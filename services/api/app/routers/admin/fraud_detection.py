"""
Fraud Detection API Routes
=========================
API endpoints for fraud detection management and analysis.
"""

from __future__ import annotations

import json
import uuid
from typing import Dict, List, Optional
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from ...infrastructure.database.session import get_async_db
from ...dependencies import get_current_admin
from ...models import User, FraudDetectionResult, FraudPattern, FraudDetectionLog, FraudRiskLevel
from ...domains.reports.models.report import Report
from ...services.fraud_detection_service import fraud_detection_service, FraudDetectionResult as ServiceResult
from ...helpers import create_audit_log_async

router = APIRouter()


@router.get("")
async def get_fraud_detection_overview(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    risk_level: Optional[str] = None,
    is_reviewed: Optional[bool] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Get fraud detection overview with results and stats."""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        logger.info(f"🔍 Fetching fraud detection data for user: {current_user.email}")
        # Get fraud detection results
        query = select(FraudDetectionResult)
        
        # Apply filters
        if risk_level:
            query = query.where(FraudDetectionResult.risk_level == risk_level)
        if is_reviewed is not None:
            query = query.where(FraudDetectionResult.is_reviewed == is_reviewed)
        
        # Get total count
        count_query = select(func.count()).select_from(FraudDetectionResult)
        if risk_level:
            count_query = count_query.where(FraudDetectionResult.risk_level == risk_level)
        if is_reviewed is not None:
            count_query = count_query.where(FraudDetectionResult.is_reviewed == is_reviewed)
        
        total = (await db.execute(count_query)).scalar() or 0
        
        # Get paginated results
        results_query = query.order_by(desc(FraudDetectionResult.detected_at)).offset(skip).limit(limit)
        result = await db.execute(results_query)
        fraud_results = result.scalars().all()
        
        # Format response
        items = []
        for fraud_result in fraud_results:
            items.append({
                "id": fraud_result.id,
                "report_id": fraud_result.report_id,
                "risk_level": fraud_result.risk_level,
                "fraud_score": fraud_result.fraud_score,
                "confidence": fraud_result.confidence,
                "flags": fraud_result.flags or [],
                "is_reviewed": fraud_result.is_reviewed,
                "is_confirmed_fraud": fraud_result.is_confirmed_fraud,
                "detected_at": fraud_result.detected_at.isoformat() if fraud_result.detected_at else None,
                "created_at": fraud_result.created_at.isoformat(),
                "reviewed_at": fraud_result.reviewed_at.isoformat() if fraud_result.reviewed_at else None,
                "reviewed_by": fraud_result.reviewed_by,
                "admin_notes": fraud_result.admin_notes,
            })
        
        # Get stats
        stats_query = select(
            func.count().label("total_detections"),
            func.count().filter(FraudDetectionResult.is_reviewed == False).label("pending_review"),
            func.count().filter(FraudDetectionResult.is_confirmed_fraud == True).label("confirmed_fraud"),
            func.avg(FraudDetectionResult.fraud_score).label("avg_score"),
        ).select_from(FraudDetectionResult)
        
        stats_result = await db.execute(stats_query)
        stats_row = stats_result.first()
        
        stats = {
            "total_detections": stats_row.total_detections or 0,
            "pending_review": stats_row.pending_review or 0,
            "confirmed_fraud": stats_row.confirmed_fraud or 0,
            "avg_score": float(stats_row.avg_score) if stats_row.avg_score else 0.0,
            "accuracy_rate": 85.0,  # Placeholder - would need actual calculation
        }
        
        result = {
            "items": items,
            "total": total,
            "skip": skip,
            "limit": limit,
            "stats": stats,
        }
        
        logger.info(f"✅ Fraud detection data fetched successfully: {total} total, {len(items)} returned")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error fetching fraud detection data: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch fraud detection data: {str(e)}"
        )


class FraudAnalysisRequest(BaseModel):
    """Request model for fraud analysis."""
    report_ids: Optional[List[str]] = None
    force_reanalysis: bool = False


class FraudReviewRequest(BaseModel):
    """Request model for fraud review."""
    is_confirmed_fraud: bool
    reviewer_notes: Optional[str] = None


class FraudStatsResponse(BaseModel):
    """Response model for fraud statistics."""
    total_detections: int
    pending_review: int
    confirmed_fraud: int
    false_positives: int
    by_risk_level: Dict[str, int]
    detection_rate: float
    accuracy_rate: float


@router.post("/analyze")
async def analyze_reports_for_fraud(
    request: FraudAnalysisRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Analyze reports for fraud detection."""
    try:
        if request.report_ids:
            # Analyze specific reports
            reports_query = select(Report).where(Report.id.in_(request.report_ids))
            result = await db.execute(reports_query)
            reports = result.scalars().all()
        else:
            # Analyze recent pending reports
            recent_time = datetime.utcnow() - timedelta(hours=24)
            reports_query = select(Report).where(
                Report.status == "pending",
                Report.created_at >= recent_time
            ).limit(100)
            result = await db.execute(reports_query)
            reports = result.scalars().all()
        
        if not reports:
            return {"message": "No reports found for analysis", "analyzed": 0}
        
        # Convert reports to dict format for analysis
        report_data = []
        for report in reports:
            report_dict = {
                'id': report.id,
                'title': report.title,
                'description': report.description,
                'type': report.type,
                'category': report.category,
                'is_urgent': report.is_urgent,
                'reward_offered': report.reward_offered,
                'reward_amount': report.reward_amount,
                'contact_info': report.contact_info,
                'location_city': report.location_city,
                'location_address': report.location_address,
                'latitude': report.latitude,
                'longitude': report.longitude,
                'images': report.images or [],
                'image_hashes': report.image_hashes or [],
                'created_at': report.created_at.isoformat() if report.created_at else None
            }
            report_data.append(report_dict)
        
        # Perform fraud analysis
        analysis_results = await fraud_detection_service.batch_analyze_reports(report_data)
        
        # Store results in database
        stored_results = []
        for result in analysis_results:
            # Check if result already exists and force_reanalysis is False
            if not request.force_reanalysis:
                existing_query = select(FraudDetectionResult).where(
                    FraudDetectionResult.report_id == result.report_id
                ).order_by(desc(FraudDetectionResult.created_at)).limit(1)
                existing_result = await db.execute(existing_query)
                existing = existing_result.scalar_one_or_none()
                
                if existing:
                    continue
            
            # Create new fraud detection result
            fraud_result = FraudDetectionResult(
                id=uuid.uuid4(),
                report_id=uuid.UUID(result.report_id),
                risk_level=result.risk_level.value,
                fraud_score=result.fraud_score,
                confidence=result.confidence,
                flags=result.flags,
                details=result.details,
                model_version=result.model_version,
                detected_at=result.detected_at
            )
            
            db.add(fraud_result)
            stored_results.append(fraud_result)
            
            # Log the detection
            log_entry = FraudDetectionLog(
                id=uuid.uuid4(),
                report_id=uuid.UUID(result.report_id),
                detection_result_id=fraud_result.id,
                analysis_type="automatic",
                action_type="auto_detection",
                triggered_by="system",
                final_score=result.fraud_score,
                final_risk_level=result.risk_level,
                action_details={
                    "fraud_score": result.fraud_score,
                    "risk_level": result.risk_level.value,
                    "flags_count": len(result.flags),
                    "model_version": result.model_version
                },
                model_version=result.model_version
            )
            db.add(log_entry)
        
        await db.commit()
        
        # Create audit log
        await create_audit_log_async(
            db=db,
            user_id=str(current_user.id),
            action="fraud_analysis",
            resource_type="reports",
            resource_id=None,
            details=json.dumps({
                "admin": current_user.email,
                "reports_analyzed": len(stored_results),
                "total_reports": len(reports),
                "force_reanalysis": request.force_reanalysis
            }),
        )
        
        return {
            "message": f"Analyzed {len(stored_results)} reports",
            "analyzed": len(stored_results),
            "total_reports": len(reports),
            "results": [
                {
                    "report_id": result.report_id,
                    "risk_level": result.risk_level.value,
                    "fraud_score": result.fraud_score,
                    "flags": result.flags
                }
                for result in analysis_results
            ]
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Fraud analysis failed: {str(e)}"
        )


@router.get("/results")
async def get_fraud_detection_results(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    risk_level: Optional[str] = None,
    is_reviewed: Optional[bool] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Get fraud detection results with filtering."""
    try:
        query = select(FraudDetectionResult)
        
        # Apply filters
        if risk_level:
            query = query.where(FraudDetectionResult.risk_level == risk_level)
        if is_reviewed is not None:
            query = query.where(FraudDetectionResult.is_reviewed == is_reviewed)
        
        # Get total count
        count_query = select(func.count()).select_from(FraudDetectionResult)
        if risk_level:
            count_query = count_query.where(FraudDetectionResult.risk_level == risk_level)
        if is_reviewed is not None:
            count_query = count_query.where(FraudDetectionResult.is_reviewed == is_reviewed)
        
        total = (await db.execute(count_query)).scalar() or 0
        
        # Get paginated results
        results_query = query.order_by(desc(FraudDetectionResult.detected_at)).offset(skip).limit(limit)
        result = await db.execute(results_query)
        fraud_results = result.scalars().all()
        
        # Format response
        items = []
        for fraud_result in fraud_results:
            items.append({
                "id": fraud_result.id,
                "report_id": fraud_result.report_id,
                "risk_level": fraud_result.risk_level,
                "fraud_score": fraud_result.fraud_score,
                "confidence": fraud_result.confidence,
                "flags": fraud_result.flags or [],
                "is_reviewed": fraud_result.is_reviewed,
                "is_confirmed_fraud": fraud_result.is_confirmed_fraud,
                "detected_at": fraud_result.detected_at.isoformat() if fraud_result.detected_at else None,
                "reviewed_at": fraud_result.reviewed_at.isoformat() if fraud_result.reviewed_at else None,
                "model_version": fraud_result.model_version
            })
        
        return {
            "items": items,
            "total": total,
            "skip": skip,
            "limit": limit
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get fraud detection results: {str(e)}"
        )


@router.get("/flagged-reports")
async def get_flagged_reports(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_async_db),
):
    """Get reports that have been flagged for fraud detection."""
    try:
        # Check if fraud detection tables exist
        try:
            # Get fraud detection results with high risk
            query = select(FraudDetectionResult).where(
                FraudDetectionResult.risk_level.in_(["high", "critical"])
            )
            
            # Get total count
            count_query = select(func.count()).select_from(FraudDetectionResult).where(
                FraudDetectionResult.risk_level.in_(["high", "critical"])
            )
            total = (await db.execute(count_query)).scalar() or 0
            
            # Get paginated results
            results_query = query.order_by(desc(FraudDetectionResult.detected_at)).offset(skip).limit(limit)
            result = await db.execute(results_query)
            fraud_results = result.scalars().all()
            
            # Format response
            items = []
            for fraud_result in fraud_results:
                items.append({
                    "id": fraud_result.id,
                    "report_id": fraud_result.report_id,
                    "risk_level": fraud_result.risk_level,
                    "fraud_score": fraud_result.fraud_score,
                    "confidence": fraud_result.confidence,
                    "flags": fraud_result.flags or [],
                    "is_reviewed": fraud_result.is_reviewed,
                    "is_confirmed_fraud": fraud_result.is_confirmed_fraud,
                    "detected_at": fraud_result.detected_at.isoformat() if fraud_result.detected_at else None,
                    "reviewed_at": fraud_result.reviewed_at.isoformat() if fraud_result.reviewed_at else None,
                    "model_version": fraud_result.model_version
                })
            
            return {
                "items": items,
                "total": total,
                "skip": skip,
                "limit": limit
            }
        except Exception:
            # Tables don't exist yet, return empty results
            return {
                "items": [],
                "total": 0,
                "skip": skip,
                "limit": limit
            }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get flagged reports: {str(e)}"
        )


@router.get("/stats")
async def get_fraud_detection_stats(
    db: AsyncSession = Depends(get_async_db),
):
    """Get fraud detection statistics."""
    try:
        # Check if fraud detection tables exist
        try:
            # Total detections
            total_detections = (await db.execute(
                select(func.count()).select_from(FraudDetectionResult)
            )).scalar() or 0
        except Exception:
            # Tables don't exist yet, return empty stats
            return FraudStatsResponse(
                total_detections=0,
                pending_review=0,
                confirmed_fraud=0,
                false_positives=0,
                by_risk_level={},
                detection_rate=0.0,
                accuracy_rate=0.0
            )
        
        # Pending review
        pending_review = (await db.execute(
            select(func.count()).select_from(FraudDetectionResult)
            .where(FraudDetectionResult.is_reviewed == False)
        )).scalar() or 0
        
        # Confirmed fraud
        confirmed_fraud = (await db.execute(
            select(func.count()).select_from(FraudDetectionResult)
            .where(FraudDetectionResult.is_confirmed_fraud == True)
        )).scalar() or 0
        
        # False positives
        false_positives = (await db.execute(
            select(func.count()).select_from(FraudDetectionResult)
            .where(
                FraudDetectionResult.is_reviewed == True,
                FraudDetectionResult.is_confirmed_fraud == False
            )
        )).scalar() or 0
        
        # By risk level
        risk_level_query = select(
            FraudDetectionResult.risk_level,
            func.count().label('count')
        ).group_by(FraudDetectionResult.risk_level)
        
        risk_result = await db.execute(risk_level_query)
        risk_levels = risk_result.fetchall()
        
        by_risk_level = {row.risk_level: row.count for row in risk_levels}
        
        # Detection rate (detections per total reports)
        total_reports = (await db.execute(
            select(func.count()).select_from(Report)
        )).scalar() or 0
        
        detection_rate = (total_detections / total_reports * 100) if total_reports > 0 else 0
        
        # Accuracy rate (confirmed fraud / total reviewed)
        total_reviewed = confirmed_fraud + false_positives
        accuracy_rate = (confirmed_fraud / total_reviewed * 100) if total_reviewed > 0 else 0
        
        return FraudStatsResponse(
            total_detections=total_detections,
            pending_review=pending_review,
            confirmed_fraud=confirmed_fraud,
            false_positives=false_positives,
            by_risk_level=by_risk_level,
            detection_rate=round(detection_rate, 2),
            accuracy_rate=round(accuracy_rate, 2)
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get fraud detection stats: {str(e)}"
        )


@router.post("/results/{result_id}/review")
async def review_fraud_detection_result(
    result_id: str,
    request: FraudReviewRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Review and confirm fraud detection result."""
    try:
        # Convert result_id to UUID
        try:
            result_id_uuid = uuid.UUID(result_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid result ID format"
            )
        
        # Get fraud detection result
        result_query = select(FraudDetectionResult).where(FraudDetectionResult.id == result_id_uuid)
        fraud_result = await db.execute(result_query)
        fraud_result = fraud_result.scalar_one_or_none()
        
        if not fraud_result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Fraud detection result not found"
            )
        
        # Update result
        fraud_result.is_reviewed = True
        fraud_result.is_confirmed_fraud = request.is_confirmed_fraud
        fraud_result.admin_notes = request.reviewer_notes
        fraud_result.reviewed_by = str(current_user.id)
        fraud_result.reviewed_at = datetime.utcnow()
        
        await db.commit()
        
        # Create audit log
        await create_audit_log_async(
            db=db,
            user_id=str(current_user.id),
            action="fraud_review",
            resource_type="fraud_detection_result",
            resource_id=result_id,
            details=json.dumps({
                "admin": current_user.email,
                "is_confirmed_fraud": request.is_confirmed_fraud,
                "reviewer_notes": request.reviewer_notes,
                "original_fraud_score": fraud_result.fraud_score,
                "risk_level": fraud_result.risk_level
            }),
        )
        
        return {
            "message": "Fraud detection result reviewed successfully",
            "result_id": result_id,
            "is_confirmed_fraud": request.is_confirmed_fraud
        }
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to review fraud detection result: {str(e)}"
        )


@router.get("/patterns")
async def get_fraud_patterns(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Get all fraud detection patterns."""
    try:
        query = select(FraudPattern).where(FraudPattern.is_active == True)
        result = await db.execute(query)
        patterns = result.scalars().all()
        
        items = []
        for pattern in patterns:
            items.append({
                "id": pattern.id,
                "pattern_type": pattern.pattern_type,
                "description": pattern.description,
                "weight": pattern.weight,
                "regex_pattern": pattern.regex_pattern,
                "keywords": pattern.keywords or [],
                "is_auto_enabled": pattern.is_auto_enabled,
                "created_at": pattern.created_at.isoformat() if pattern.created_at else None
            })
        
        return {"patterns": items}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get fraud patterns: {str(e)}"
        )


@router.post("/train-models")
async def train_fraud_detection_models(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Train fraud detection models with historical data."""
    try:
        # Get historical fraud detection results for training
        training_query = select(FraudDetectionResult).where(
            FraudDetectionResult.is_reviewed == True
        ).limit(1000)  # Limit for performance
        
        result = await db.execute(training_query)
        fraud_results = result.scalars().all()
        
        if len(fraud_results) < 10:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Insufficient training data. Need at least 10 reviewed fraud detection results."
            )
        
        # Prepare training data
        training_data = []
        for fraud_result in fraud_results:
            # Get the associated report
            report_query = select(Report).where(Report.id == fraud_result.report_id)
            report_result = await db.execute(report_query)
            report = report_result.scalar_one_or_none()
            
            if report:
                report_dict = {
                    'id': report.id,
                    'title': report.title,
                    'description': report.description,
                    'type': report.type,
                    'category': report.category,
                    'is_urgent': report.is_urgent,
                    'reward_offered': report.reward_offered,
                    'reward_amount': report.reward_amount,
                    'contact_info': report.contact_info,
                    'location_city': report.location_city,
                    'latitude': report.latitude,
                    'longitude': report.longitude,
                    'images': report.images or [],
                    'is_fraud': fraud_result.is_confirmed_fraud
                }
                training_data.append(report_dict)
        
        # Train models
        await fraud_detection_service.train_models(training_data)
        
        # Log training activity
        # Note: report_id is required, using a special training report UUID
        training_report_id = uuid.UUID('00000000-0000-0000-0000-000000000000')
        log_entry = FraudDetectionLog(
            id=uuid.uuid4(),
            report_id=training_report_id,
            analysis_type="batch",
            action_type="model_training",
            triggered_by="admin",
            final_score=0.0,
            final_risk_level=FraudRiskLevel.LOW,
            action_details={
                "training_samples": len(training_data),
                "confirmed_fraud": sum(1 for d in training_data if d['is_fraud']),
                "false_positives": sum(1 for d in training_data if not d['is_fraud'])
            },
            model_version=fraud_detection_service.model_version
        )
        db.add(log_entry)
        
        await db.commit()
        
        # Create audit log
        await create_audit_log_async(
            db=db,
            user_id=str(current_user.id),
            action="train_fraud_models",
            resource_type="fraud_detection",
            resource_id=None,
            details=json.dumps({
                "admin": current_user.email,
                "training_samples": len(training_data),
                "model_version": fraud_detection_service.model_version
            }),
        )
        
        return {
            "message": "Fraud detection models trained successfully",
            "training_samples": len(training_data),
            "model_version": fraud_detection_service.model_version
        }
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to train fraud detection models: {str(e)}"
        )
