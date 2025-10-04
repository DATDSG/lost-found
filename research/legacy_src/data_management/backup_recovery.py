"""
Backup and Recovery System
Implements comprehensive backup strategies and disaster recovery procedures
"""

import os
import subprocess
import asyncio
import boto3
import gzip
import json
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from pathlib import Path
from dataclasses import dataclass
from enum import Enum
import psycopg2
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from ..core.config import settings
from ..database import get_db

logger = logging.getLogger(__name__)

class BackupType(Enum):
    """Types of backups"""
    FULL = "full"
    INCREMENTAL = "incremental"
    DIFFERENTIAL = "differential"
    TRANSACTION_LOG = "transaction_log"

class BackupStatus(Enum):
    """Backup operation status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class BackupJob:
    """Backup job configuration"""
    id: str
    backup_type: BackupType
    status: BackupStatus
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    file_path: Optional[str] = None
    file_size: Optional[int] = None
    error_message: Optional[str] = None
    retention_days: int = 30
    
class DatabaseBackupService:
    """Service for database backup and recovery operations"""
    
    def __init__(self):
        self.backup_dir = Path(settings.BACKUP_DIRECTORY)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        # S3 configuration for remote backups
        if settings.BACKUP_S3_ENABLED:
            self.s3_client = boto3.client(
                's3',
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                region_name=settings.AWS_REGION
            )
            self.s3_bucket = settings.BACKUP_S3_BUCKET
        else:
            self.s3_client = None
    
    async def create_full_backup(self, compress: bool = True) -> BackupJob:
        """Create a full database backup"""
        job_id = f"full_backup_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
        
        job = BackupJob(
            id=job_id,
            backup_type=BackupType.FULL,
            status=BackupStatus.PENDING,
            retention_days=settings.FULL_BACKUP_RETENTION_DAYS
        )
        
        try:
            job.status = BackupStatus.RUNNING
            job.started_at = datetime.utcnow()
            
            # Create backup filename
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            filename = f"full_backup_{timestamp}.sql"
            if compress:
                filename += ".gz"
            
            backup_path = self.backup_dir / filename
            
            # Execute pg_dump
            dump_command = [
                'pg_dump',
                '--host', settings.DATABASE_HOST,
                '--port', str(settings.DATABASE_PORT),
                '--username', settings.DATABASE_USER,
                '--dbname', settings.DATABASE_NAME,
                '--verbose',
                '--clean',
                '--no-owner',
                '--no-privileges',
                '--format=custom' if not compress else '--format=plain'
            ]
            
            # Set password via environment variable
            env = os.environ.copy()
            env['PGPASSWORD'] = settings.DATABASE_PASSWORD
            
            if compress:
                # Pipe through gzip
                with open(backup_path, 'wb') as f:
                    dump_process = subprocess.Popen(
                        dump_command,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        env=env
                    )
                    gzip_process = subprocess.Popen(
                        ['gzip'],
                        stdin=dump_process.stdout,
                        stdout=f,
                        stderr=subprocess.PIPE
                    )
                    dump_process.stdout.close()
                    
                    _, gzip_error = gzip_process.communicate()
                    _, dump_error = dump_process.communicate()
                    
                    if dump_process.returncode != 0:
                        raise Exception(f"pg_dump failed: {dump_error.decode()}")
                    if gzip_process.returncode != 0:
                        raise Exception(f"gzip failed: {gzip_error.decode()}")
            else:
                # Direct output to file
                with open(backup_path, 'w') as f:
                    result = subprocess.run(
                        dump_command,
                        stdout=f,
                        stderr=subprocess.PIPE,
                        env=env,
                        text=True
                    )
                    
                    if result.returncode != 0:
                        raise Exception(f"pg_dump failed: {result.stderr}")
            
            # Get file size
            job.file_size = backup_path.stat().st_size
            job.file_path = str(backup_path)
            
            # Upload to S3 if configured
            if self.s3_client:
                await self._upload_to_s3(backup_path, f"database/{filename}")
            
            job.status = BackupStatus.COMPLETED
            job.completed_at = datetime.utcnow()
            
            logger.info(f"Full backup completed: {filename} ({job.file_size} bytes)")
            
        except Exception as e:
            job.status = BackupStatus.FAILED
            job.error_message = str(e)
            job.completed_at = datetime.utcnow()
            logger.error(f"Full backup failed: {e}")
        
        return job
    
    async def create_incremental_backup(self) -> BackupJob:
        """Create an incremental backup using WAL files"""
        job_id = f"incremental_backup_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
        
        job = BackupJob(
            id=job_id,
            backup_type=BackupType.INCREMENTAL,
            status=BackupStatus.PENDING,
            retention_days=settings.INCREMENTAL_BACKUP_RETENTION_DAYS
        )
        
        try:
            job.status = BackupStatus.RUNNING
            job.started_at = datetime.utcnow()
            
            # Archive WAL files
            wal_archive_dir = self.backup_dir / "wal_archive"
            wal_archive_dir.mkdir(exist_ok=True)
            
            # Get current WAL file
            engine = create_engine(settings.DATABASE_URL)
            with engine.connect() as conn:
                result = conn.execute(text("SELECT pg_current_wal_lsn();"))
                current_lsn = result.fetchone()[0]
                
                result = conn.execute(text("SELECT pg_walfile_name(pg_current_wal_lsn());"))
                current_wal_file = result.fetchone()[0]
            
            # Archive current WAL segment
            archive_command = [
                'pg_receivewal',
                '--host', settings.DATABASE_HOST,
                '--port', str(settings.DATABASE_PORT),
                '--username', settings.DATABASE_USER,
                '--directory', str(wal_archive_dir),
                '--synchronous'
            ]
            
            env = os.environ.copy()
            env['PGPASSWORD'] = settings.DATABASE_PASSWORD
            
            # Run for a short time to get current WAL files
            process = subprocess.Popen(
                archive_command,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Let it run for 10 seconds to capture current WAL
            await asyncio.sleep(10)
            process.terminate()
            
            job.file_path = str(wal_archive_dir)
            job.file_size = sum(f.stat().st_size for f in wal_archive_dir.iterdir() if f.is_file())
            
            job.status = BackupStatus.COMPLETED
            job.completed_at = datetime.utcnow()
            
            logger.info(f"Incremental backup completed: {job.file_size} bytes")
            
        except Exception as e:
            job.status = BackupStatus.FAILED
            job.error_message = str(e)
            job.completed_at = datetime.utcnow()
            logger.error(f"Incremental backup failed: {e}")
        
        return job
    
    async def restore_from_backup(
        self, 
        backup_path: str, 
        target_database: str = None,
        point_in_time: datetime = None
    ) -> bool:
        """Restore database from backup"""
        try:
            target_db = target_database or settings.DATABASE_NAME
            
            logger.info(f"Starting restore from {backup_path} to {target_db}")
            
            # Check if backup file exists
            backup_file = Path(backup_path)
            if not backup_file.exists():
                # Try to download from S3
                if self.s3_client:
                    await self._download_from_s3(backup_file.name, backup_path)
                else:
                    raise FileNotFoundError(f"Backup file not found: {backup_path}")
            
            # Drop existing connections to target database
            await self._drop_database_connections(target_db)
            
            # Restore using pg_restore or psql
            if backup_path.endswith('.gz'):
                # Compressed SQL file
                restore_command = ['gunzip', '-c', backup_path]
                psql_command = [
                    'psql',
                    '--host', settings.DATABASE_HOST,
                    '--port', str(settings.DATABASE_PORT),
                    '--username', settings.DATABASE_USER,
                    '--dbname', target_db,
                    '--quiet'
                ]
                
                env = os.environ.copy()
                env['PGPASSWORD'] = settings.DATABASE_PASSWORD
                
                # Pipe gunzip output to psql
                gunzip_process = subprocess.Popen(
                    restore_command,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                
                psql_process = subprocess.Popen(
                    psql_command,
                    stdin=gunzip_process.stdout,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env=env
                )
                
                gunzip_process.stdout.close()
                
                _, psql_error = psql_process.communicate()
                _, gunzip_error = gunzip_process.communicate()
                
                if psql_process.returncode != 0:
                    raise Exception(f"Restore failed: {psql_error.decode()}")
                
            else:
                # Custom format backup
                restore_command = [
                    'pg_restore',
                    '--host', settings.DATABASE_HOST,
                    '--port', str(settings.DATABASE_PORT),
                    '--username', settings.DATABASE_USER,
                    '--dbname', target_db,
                    '--verbose',
                    '--clean',
                    '--no-owner',
                    '--no-privileges',
                    backup_path
                ]
                
                env = os.environ.copy()
                env['PGPASSWORD'] = settings.DATABASE_PASSWORD
                
                result = subprocess.run(
                    restore_command,
                    env=env,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode != 0:
                    raise Exception(f"pg_restore failed: {result.stderr}")
            
            # Apply point-in-time recovery if specified
            if point_in_time:
                await self._apply_point_in_time_recovery(target_db, point_in_time)
            
            logger.info(f"Database restore completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"Database restore failed: {e}")
            return False
    
    async def _drop_database_connections(self, database_name: str):
        """Drop all connections to a database"""
        engine = create_engine(settings.DATABASE_URL.replace(f"/{settings.DATABASE_NAME}", "/postgres"))
        
        with engine.connect() as conn:
            # Terminate all connections to the target database
            conn.execute(text(f"""
                SELECT pg_terminate_backend(pid)
                FROM pg_stat_activity
                WHERE datname = '{database_name}' AND pid <> pg_backend_pid();
            """))
    
    async def _apply_point_in_time_recovery(self, database_name: str, target_time: datetime):
        """Apply point-in-time recovery using WAL files"""
        # This is a simplified version - full PITR requires more complex WAL replay
        logger.info(f"Applying point-in-time recovery to {target_time}")
        
        # In a full implementation, this would:
        # 1. Apply WAL files up to the target time
        # 2. Use pg_waldump to find the exact LSN
        # 3. Configure recovery.conf with target time
        # 4. Restart PostgreSQL in recovery mode
    
    async def _upload_to_s3(self, file_path: Path, s3_key: str):
        """Upload backup file to S3"""
        if not self.s3_client:
            return
        
        try:
            self.s3_client.upload_file(
                str(file_path),
                self.s3_bucket,
                s3_key,
                ExtraArgs={
                    'StorageClass': 'STANDARD_IA',  # Infrequent Access for backups
                    'ServerSideEncryption': 'AES256'
                }
            )
            logger.info(f"Uploaded backup to S3: s3://{self.s3_bucket}/{s3_key}")
        except Exception as e:
            logger.error(f"Failed to upload to S3: {e}")
    
    async def _download_from_s3(self, s3_key: str, local_path: str):
        """Download backup file from S3"""
        if not self.s3_client:
            raise Exception("S3 not configured")
        
        try:
            self.s3_client.download_file(
                self.s3_bucket,
                s3_key,
                local_path
            )
            logger.info(f"Downloaded backup from S3: {s3_key}")
        except Exception as e:
            logger.error(f"Failed to download from S3: {e}")
            raise
    
    async def cleanup_old_backups(self) -> int:
        """Clean up old backup files based on retention policies"""
        cleaned_count = 0
        
        # Clean local backups
        for backup_file in self.backup_dir.glob("*.sql*"):
            file_age = datetime.utcnow() - datetime.fromtimestamp(backup_file.stat().st_mtime)
            
            # Determine retention period based on backup type
            if "full_backup" in backup_file.name:
                retention_days = settings.FULL_BACKUP_RETENTION_DAYS
            elif "incremental" in backup_file.name:
                retention_days = settings.INCREMENTAL_BACKUP_RETENTION_DAYS
            else:
                retention_days = 30  # Default
            
            if file_age.days > retention_days:
                backup_file.unlink()
                cleaned_count += 1
                logger.info(f"Deleted old backup: {backup_file.name}")
        
        # Clean S3 backups if configured
        if self.s3_client:
            cleaned_count += await self._cleanup_s3_backups()
        
        return cleaned_count
    
    async def _cleanup_s3_backups(self) -> int:
        """Clean up old S3 backups"""
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.s3_bucket,
                Prefix='database/'
            )
            
            cleaned_count = 0
            cutoff_date = datetime.utcnow() - timedelta(days=settings.FULL_BACKUP_RETENTION_DAYS)
            
            for obj in response.get('Contents', []):
                if obj['LastModified'].replace(tzinfo=None) < cutoff_date:
                    self.s3_client.delete_object(
                        Bucket=self.s3_bucket,
                        Key=obj['Key']
                    )
                    cleaned_count += 1
                    logger.info(f"Deleted old S3 backup: {obj['Key']}")
            
            return cleaned_count
            
        except Exception as e:
            logger.error(f"Error cleaning S3 backups: {e}")
            return 0
    
    def get_backup_status(self) -> Dict[str, Any]:
        """Get backup system status"""
        backup_files = list(self.backup_dir.glob("*.sql*"))
        
        return {
            'backup_directory': str(self.backup_dir),
            'total_backups': len(backup_files),
            'total_size_mb': sum(f.stat().st_size for f in backup_files) / (1024 * 1024),
            'latest_backup': max(backup_files, key=lambda f: f.stat().st_mtime).name if backup_files else None,
            's3_enabled': self.s3_client is not None,
            's3_bucket': self.s3_bucket if self.s3_client else None
        }

class FileBackupService:
    """Service for backing up application files and media"""
    
    def __init__(self):
        self.media_dir = Path(settings.MEDIA_ROOT)
        self.backup_dir = Path(settings.BACKUP_DIRECTORY) / "files"
        self.backup_dir.mkdir(parents=True, exist_ok=True)
    
    async def backup_media_files(self) -> BackupJob:
        """Backup media files (images, documents, etc.)"""
        job_id = f"media_backup_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
        
        job = BackupJob(
            id=job_id,
            backup_type=BackupType.FULL,
            status=BackupStatus.PENDING,
            retention_days=settings.MEDIA_BACKUP_RETENTION_DAYS
        )
        
        try:
            job.status = BackupStatus.RUNNING
            job.started_at = datetime.utcnow()
            
            # Create tar.gz archive of media files
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            archive_name = f"media_backup_{timestamp}.tar.gz"
            archive_path = self.backup_dir / archive_name
            
            # Use tar command for efficient compression
            tar_command = [
                'tar',
                '-czf',
                str(archive_path),
                '-C',
                str(self.media_dir.parent),
                self.media_dir.name
            ]
            
            result = subprocess.run(
                tar_command,
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                raise Exception(f"tar command failed: {result.stderr}")
            
            job.file_path = str(archive_path)
            job.file_size = archive_path.stat().st_size
            job.status = BackupStatus.COMPLETED
            job.completed_at = datetime.utcnow()
            
            logger.info(f"Media backup completed: {archive_name} ({job.file_size} bytes)")
            
        except Exception as e:
            job.status = BackupStatus.FAILED
            job.error_message = str(e)
            job.completed_at = datetime.utcnow()
            logger.error(f"Media backup failed: {e}")
        
        return job
    
    async def restore_media_files(self, backup_path: str) -> bool:
        """Restore media files from backup"""
        try:
            backup_file = Path(backup_path)
            if not backup_file.exists():
                raise FileNotFoundError(f"Backup file not found: {backup_path}")
            
            # Extract tar.gz archive
            tar_command = [
                'tar',
                '-xzf',
                str(backup_file),
                '-C',
                str(self.media_dir.parent)
            ]
            
            result = subprocess.run(
                tar_command,
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                raise Exception(f"tar extraction failed: {result.stderr}")
            
            logger.info(f"Media files restored from {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Media restore failed: {e}")
            return False

class DisasterRecoveryService:
    """Service for disaster recovery procedures"""
    
    def __init__(self):
        self.db_backup_service = DatabaseBackupService()
        self.file_backup_service = FileBackupService()
    
    async def create_full_system_backup(self) -> Dict[str, BackupJob]:
        """Create a complete system backup"""
        logger.info("Starting full system backup")
        
        # Run database and file backups concurrently
        db_backup_task = asyncio.create_task(
            self.db_backup_service.create_full_backup(compress=True)
        )
        media_backup_task = asyncio.create_task(
            self.file_backup_service.backup_media_files()
        )
        
        db_backup, media_backup = await asyncio.gather(
            db_backup_task, media_backup_task, return_exceptions=True
        )
        
        results = {
            'database': db_backup if isinstance(db_backup, BackupJob) else None,
            'media': media_backup if isinstance(media_backup, BackupJob) else None
        }
        
        # Log results
        success_count = sum(1 for job in results.values() 
                          if job and job.status == BackupStatus.COMPLETED)
        
        logger.info(f"Full system backup completed: {success_count}/2 components successful")
        
        return results
    
    async def restore_full_system(
        self, 
        db_backup_path: str, 
        media_backup_path: str
    ) -> Dict[str, bool]:
        """Restore complete system from backups"""
        logger.info("Starting full system restore")
        
        results = {}
        
        # Restore database
        try:
            results['database'] = await self.db_backup_service.restore_from_backup(
                db_backup_path
            )
        except Exception as e:
            logger.error(f"Database restore failed: {e}")
            results['database'] = False
        
        # Restore media files
        try:
            results['media'] = await self.file_backup_service.restore_media_files(
                media_backup_path
            )
        except Exception as e:
            logger.error(f"Media restore failed: {e}")
            results['media'] = False
        
        success_count = sum(results.values())
        logger.info(f"Full system restore completed: {success_count}/2 components successful")
        
        return results
    
    async def verify_backup_integrity(self, backup_path: str) -> bool:
        """Verify backup file integrity"""
        try:
            backup_file = Path(backup_path)
            if not backup_file.exists():
                return False
            
            # For SQL backups, try to parse the header
            if backup_path.endswith('.sql') or backup_path.endswith('.sql.gz'):
                # Basic validation - check file size and format
                if backup_file.stat().st_size == 0:
                    return False
                
                # For compressed files, test decompression
                if backup_path.endswith('.gz'):
                    result = subprocess.run(
                        ['gzip', '-t', backup_path],
                        capture_output=True
                    )
                    return result.returncode == 0
            
            return True
            
        except Exception as e:
            logger.error(f"Backup integrity check failed: {e}")
            return False

# Background task for automated backups
async def run_automated_backups():
    """Background task for scheduled backups"""
    dr_service = DisasterRecoveryService()
    
    while True:
        try:
            current_hour = datetime.utcnow().hour
            
            # Full backup at 2 AM daily
            if current_hour == 2:
                await dr_service.create_full_system_backup()
                
                # Clean up old backups
                await dr_service.db_backup_service.cleanup_old_backups()
            
            # Incremental backup every 6 hours
            elif current_hour % 6 == 0:
                await dr_service.db_backup_service.create_incremental_backup()
            
        except Exception as e:
            logger.error(f"Automated backup failed: {e}")
        
        # Check every hour
        await asyncio.sleep(3600)
