#!/usr/bin/env python3
"""
Backend Enhancements Setup Script
Initializes and configures all backend enhancement features
"""

import asyncio
import sys
import os
from pathlib import Path
from typing import Dict, List, Any
import logging

# Add src to path for imports
sys.path.append(str(Path(__file__).parent / "src"))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from alembic.config import Config
from alembic import command

from src.config.backend_enhancements import config
from src.models.soft_delete import configure_soft_delete_session
from src.performance.database_optimization import DatabaseIndexManager, QueryCacheManager
from src.auth.rbac import RolePermissions
from src.data_management.backup_recovery import DatabaseBackupService

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BackendEnhancementsSetup:
    """Main setup class for backend enhancements"""
    
    def __init__(self):
        self.config = config
        self.setup_results = {
            "database": False,
            "migrations": False,
            "indexes": False,
            "cache": False,
            "rbac": False,
            "backup": False,
            "configuration": False
        }
    
    async def run_full_setup(self) -> Dict[str, Any]:
        """Run complete backend enhancements setup"""
        logger.info("Starting backend enhancements setup...")
        
        try:
            # 1. Validate configuration
            logger.info("Step 1: Validating configuration...")
            await self.validate_configuration()
            
            # 2. Setup database connection
            logger.info("Step 2: Setting up database connection...")
            await self.setup_database()
            
            # 3. Run migrations
            logger.info("Step 3: Running database migrations...")
            await self.run_migrations()
            
            # 4. Create performance indexes
            logger.info("Step 4: Creating performance indexes...")
            await self.setup_indexes()
            
            # 5. Initialize cache
            logger.info("Step 5: Initializing cache...")
            await self.setup_cache()
            
            # 6. Setup RBAC
            logger.info("Step 6: Setting up RBAC...")
            await self.setup_rbac()
            
            # 7. Initialize backup system
            logger.info("Step 7: Initializing backup system...")
            await self.setup_backup()
            
            # 8. Final configuration
            logger.info("Step 8: Final configuration...")
            await self.finalize_configuration()
            
            logger.info("Backend enhancements setup completed successfully!")
            return {
                "success": True,
                "results": self.setup_results,
                "message": "All backend enhancements configured successfully"
            }
            
        except Exception as e:
            logger.error(f"Setup failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "results": self.setup_results
            }
    
    async def validate_configuration(self):
        """Validate all configuration settings"""
        issues = self.config.validate_configuration()
        
        if issues["errors"]:
            error_msg = "Configuration errors found: " + "; ".join(issues["errors"])
            raise Exception(error_msg)
        
        if issues["warnings"]:
            for warning in issues["warnings"]:
                logger.warning(f"Configuration warning: {warning}")
        
        # Check feature flags
        feature_flags = self.config.get_feature_flags()
        enabled_features = [k for k, v in feature_flags.items() if v]
        logger.info(f"Enabled features: {', '.join(enabled_features)}")
        
        self.setup_results["configuration"] = True
    
    async def setup_database(self):
        """Setup database connection and session configuration"""
        try:
            # Get database URL from environment or config
            database_url = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/lost_found")
            
            # Create engine
            engine = create_engine(database_url)
            
            # Test connection
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            
            # Configure session factory with soft delete
            SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
            configure_soft_delete_session(SessionLocal)
            
            self.engine = engine
            self.SessionLocal = SessionLocal
            self.setup_results["database"] = True
            
            logger.info("Database connection established successfully")
            
        except Exception as e:
            logger.error(f"Database setup failed: {e}")
            raise
    
    async def run_migrations(self):
        """Run Alembic migrations"""
        try:
            # Setup Alembic configuration
            alembic_cfg = Config("alembic.ini")
            
            # Run migrations
            command.upgrade(alembic_cfg, "head")
            
            self.setup_results["migrations"] = True
            logger.info("Database migrations completed successfully")
            
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            raise
    
    async def setup_indexes(self):
        """Create performance indexes"""
        try:
            with self.SessionLocal() as db:
                index_manager = DatabaseIndexManager(db)
                
                # Create all performance indexes
                results = index_manager.create_performance_indexes()
                
                # Check results
                created = sum(1 for success in results.values() if success)
                total = len(results)
                
                if created < total:
                    failed_indexes = [name for name, success in results.items() if not success]
                    logger.warning(f"Some indexes failed to create: {failed_indexes}")
                
                logger.info(f"Created {created}/{total} performance indexes")
                self.setup_results["indexes"] = created > 0
                
        except Exception as e:
            logger.error(f"Index creation failed: {e}")
            raise
    
    async def setup_cache(self):
        """Initialize Redis cache"""
        try:
            cache_manager = QueryCacheManager()
            
            # Test cache connection
            cache_manager.redis_client.ping()
            
            # Get cache stats
            stats = cache_manager.get_cache_stats()
            logger.info(f"Cache connected - Memory: {stats.get('used_memory_mb', 0):.2f}MB")
            
            self.setup_results["cache"] = True
            
        except Exception as e:
            logger.error(f"Cache setup failed: {e}")
            # Cache is optional, don't fail setup
            logger.warning("Continuing without cache...")
    
    async def setup_rbac(self):
        """Setup Role-Based Access Control"""
        try:
            # Validate RBAC configuration
            role_permissions = RolePermissions()
            
            # Log available roles and permissions
            logger.info("RBAC configured with roles:")
            for role, permissions in role_permissions.PERMISSIONS.items():
                logger.info(f"  {role.value}: {len(permissions)} permissions")
            
            self.setup_results["rbac"] = True
            
        except Exception as e:
            logger.error(f"RBAC setup failed: {e}")
            raise
    
    async def setup_backup(self):
        """Initialize backup system"""
        try:
            if not self.config.backup.DB_BACKUP_ENABLED:
                logger.info("Database backup disabled in configuration")
                self.setup_results["backup"] = True
                return
            
            with self.SessionLocal() as db:
                backup_service = DatabaseBackupService(db)
                
                # Test backup configuration
                backup_path = Path(self.config.backup.LOCAL_BACKUP_PATH)
                backup_path.mkdir(parents=True, exist_ok=True)
                
                logger.info(f"Backup system initialized - Path: {backup_path}")
                
                # Schedule first backup if enabled
                if self.config.backup.DB_BACKUP_ENABLED:
                    logger.info("Backup system ready for scheduled backups")
                
                self.setup_results["backup"] = True
                
        except Exception as e:
            logger.error(f"Backup setup failed: {e}")
            # Backup is optional, don't fail setup
            logger.warning("Continuing without backup system...")
    
    async def finalize_configuration(self):
        """Finalize configuration and create summary"""
        try:
            # Create configuration summary
            summary = {
                "features_enabled": self.config.get_feature_flags(),
                "setup_results": self.setup_results,
                "configuration": {
                    "oauth2_configured": bool(self.config.auth.GOOGLE_CLIENT_ID),
                    "2fa_enabled": True,
                    "rbac_enabled": True,
                    "soft_delete_enabled": True,
                    "performance_optimized": self.setup_results["indexes"],
                    "cache_enabled": self.setup_results["cache"],
                    "backup_enabled": self.setup_results["backup"]
                }
            }
            
            # Save configuration summary
            summary_path = Path("backend_enhancements_summary.json")
            import json
            with open(summary_path, 'w') as f:
                json.dump(summary, f, indent=2, default=str)
            
            logger.info(f"Configuration summary saved to {summary_path}")
            
        except Exception as e:
            logger.error(f"Configuration finalization failed: {e}")
            raise

class HealthChecker:
    """Health check utilities for backend enhancements"""
    
    @staticmethod
    async def check_all_systems() -> Dict[str, Any]:
        """Comprehensive health check of all systems"""
        health_status = {
            "overall_healthy": True,
            "checks": {}
        }
        
        # Database check
        try:
            database_url = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/lost_found")
            engine = create_engine(database_url)
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            health_status["checks"]["database"] = {"healthy": True, "message": "Connected"}
        except Exception as e:
            health_status["checks"]["database"] = {"healthy": False, "error": str(e)}
            health_status["overall_healthy"] = False
        
        # Cache check
        try:
            cache_manager = QueryCacheManager()
            cache_manager.redis_client.ping()
            stats = cache_manager.get_cache_stats()
            health_status["checks"]["cache"] = {
                "healthy": True, 
                "stats": stats
            }
        except Exception as e:
            health_status["checks"]["cache"] = {"healthy": False, "error": str(e)}
        
        # Configuration check
        try:
            issues = config.validate_configuration()
            health_status["checks"]["configuration"] = {
                "healthy": len(issues["errors"]) == 0,
                "issues": issues
            }
            if issues["errors"]:
                health_status["overall_healthy"] = False
        except Exception as e:
            health_status["checks"]["configuration"] = {"healthy": False, "error": str(e)}
            health_status["overall_healthy"] = False
        
        return health_status

async def main():
    """Main setup function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Backend Enhancements Setup")
    parser.add_argument("--action", choices=["setup", "health", "validate"], 
                       default="setup", help="Action to perform")
    parser.add_argument("--skip-indexes", action="store_true", 
                       help="Skip index creation (faster setup)")
    parser.add_argument("--force", action="store_true", 
                       help="Force setup even with warnings")
    
    args = parser.parse_args()
    
    if args.action == "health":
        health_checker = HealthChecker()
        status = await health_checker.check_all_systems()
        
        print("\n=== Backend Enhancements Health Check ===")
        print(f"Overall Status: {'✅ HEALTHY' if status['overall_healthy'] else '❌ UNHEALTHY'}")
        
        for check_name, check_result in status["checks"].items():
            status_icon = "✅" if check_result["healthy"] else "❌"
            print(f"{status_icon} {check_name.title()}: ", end="")
            
            if check_result["healthy"]:
                print("OK")
                if "stats" in check_result:
                    for key, value in check_result["stats"].items():
                        print(f"    {key}: {value}")
            else:
                print(f"FAILED - {check_result.get('error', 'Unknown error')}")
        
        return status["overall_healthy"]
    
    elif args.action == "validate":
        print("\n=== Configuration Validation ===")
        issues = config.validate_configuration()
        
        if issues["errors"]:
            print("❌ Configuration Errors:")
            for error in issues["errors"]:
                print(f"  - {error}")
        
        if issues["warnings"]:
            print("⚠️  Configuration Warnings:")
            for warning in issues["warnings"]:
                print(f"  - {warning}")
        
        if not issues["errors"] and not issues["warnings"]:
            print("✅ Configuration is valid")
        
        return len(issues["errors"]) == 0
    
    else:  # setup
        setup = BackendEnhancementsSetup()
        
        if args.skip_indexes:
            setup.setup_results["indexes"] = True  # Skip index creation
        
        result = await setup.run_full_setup()
        
        print("\n=== Backend Enhancements Setup Results ===")
        if result["success"]:
            print("✅ Setup completed successfully!")
            
            print("\nSetup Results:")
            for component, status in result["results"].items():
                status_icon = "✅" if status else "❌"
                print(f"  {status_icon} {component.title()}")
            
            print(f"\nFeature flags enabled: {len([k for k, v in config.get_feature_flags().items() if v])}")
            print("\nNext steps:")
            print("1. Update your .env file with required API keys")
            print("2. Run database migrations: alembic upgrade head")
            print("3. Start the API server: uvicorn app.main:app --reload")
            print("4. Test the health endpoint: GET /api/v1/performance/monitoring/health")
            
        else:
            print(f"❌ Setup failed: {result['error']}")
            return False
        
        return result["success"]

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
