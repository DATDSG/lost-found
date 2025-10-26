"""Simple authentication routes."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..models import User
from ..schemas import UserRegister, UserLogin, Token, UserResponse
from ..auth import get_password_hash, verify_password, create_access_token, decode_token
from ..dependencies import get_current_user
from ..exceptions import ValidationError, ConflictError, AuthenticationError
from ..validation import UserValidationMixin

router = APIRouter()


def get_sync_db():
    """Get synchronous database session for authentication."""
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy import create_engine
    from ..config import config
    
    # Create synchronous engine using psycopg (not psycopg2)
    sync_database_url = config.DATABASE_URL.replace("+asyncpg", "+psycopg")
    sync_engine = create_engine(sync_database_url)
    SessionLocal = sessionmaker(bind=sync_engine)
    
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_sync_db)):
    """Register a new user."""
    try:
        # Validate input data
        validator = UserValidationMixin()
        
        # Validate email
        validated_email = validator.validate_email_address(user_data.email)
        
        # Validate password
        validated_password = validator.validate_password_strength(user_data.password)
        
        # Validate display name
        display_name = user_data.display_name or user_data.email.split("@")[0]
        validated_display_name = validator.validate_display_name(display_name)
        
        # Check if user exists
        existing_user = db.query(User).filter(User.email == validated_email).first()
        if existing_user:
            raise ConflictError("Email already registered")
        
        # Create new user
        user = User(
            email=validated_email,
            password=get_password_hash(validated_password),
            display_name=validated_display_name,
            role="user"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # Create audit log for user registration
        from ..helpers import create_audit_log
        create_audit_log(
            db=db,
            user_id=str(user.id),
            action="register",
            resource_type="user",
            resource_id=str(user.id),
            details=f"User registered with email: {user.email}"
        )
        
        # Generate access token
        access_token = create_access_token(data={"sub": str(user.id)})
        
        return Token(access_token=access_token, refresh_token="", token_type="bearer")
        
    except ValidationError:
        # Re-raise validation errors as-is
        raise
    except ConflictError:
        # Re-raise conflict errors as-is
        raise
    except Exception as e:
        # Handle unexpected errors
        print(f"Registration error: {e}")
        print(f"Error type: {type(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed"
        )


@router.post("/login", response_model=Token)
def login(credentials: UserLogin, db: Session = Depends(get_sync_db)):
    """Login and get access token."""
    try:
        # Validate email format
        validator = UserValidationMixin()
        validated_email = validator.validate_email_address(credentials.email)
        
        # Find user
        user = db.query(User).filter(User.email == validated_email).first()
        
        if not user or not verify_password(credentials.password, user.password):
            raise AuthenticationError("Incorrect email or password")
        
        if not user.is_active:
            raise AuthenticationError("User account is disabled")
        
        # Create audit log for user login
        from ..helpers import create_audit_log
        create_audit_log(
            db=db,
            user_id=str(user.id),
            action="login",
            resource_type="auth",
            resource_id=None,
            details=f"User logged in successfully from IP: {credentials.email}"
        )
        
        # Generate access token
        access_token = create_access_token(data={"sub": str(user.id)})
        
        return Token(access_token=access_token, refresh_token="", token_type="bearer")
        
    except ValidationError:
        # Re-raise validation errors as-is
        raise
    except AuthenticationError:
        # Re-raise authentication errors as-is
        raise
    except Exception as e:
        # Handle unexpected errors
        print(f"Login error: {e}")
        print(f"Error type: {type(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed"
        )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Get current user information."""
    return current_user


@router.post("/forgot-password")
def forgot_password(email: str, db: Session = Depends(get_sync_db)):
    """Request password reset."""
    try:
        # Validate email format
        validator = UserValidationMixin()
        validated_email = validator.validate_email_address(email)
        
        # Check if user exists
        user = db.query(User).filter(User.email == validated_email).first()
        
        if not user:
            # Don't reveal if user exists or not for security
            return {"message": "If the email exists, a reset link has been sent"}
        
        # In a real implementation, you would:
        # 1. Generate a reset token
        # 2. Send email with reset link
        # 3. Store token in database with expiration
        
        return {"message": "If the email exists, a reset link has been sent"}
        
    except ValidationError:
        raise
    except Exception as e:
        print(f"Forgot password error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password reset request failed"
        )


@router.post("/reset-password")
def reset_password(token: str, password: str, db: Session = Depends(get_sync_db)):
    """Reset password with token."""
    try:
        # In a real implementation, you would:
        # 1. Validate the reset token
        # 2. Check if token is expired
        # 3. Update user password
        # 4. Invalidate the token
        
        # For now, return a placeholder response
        return {"message": "Password reset successfully"}
        
    except Exception as e:
        print(f"Reset password error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password reset failed"
        )


@router.post("/change-password")
def change_password(
    current_password: str,
    new_password: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_sync_db)
):
    """Change user password."""
    try:
        # Verify current password
        if not verify_password(current_password, current_user.password):
            raise AuthenticationError("Current password is incorrect")
        
        # Validate new password
        validator = UserValidationMixin()
        validator.validate_password(new_password)
        
        # Update password
        current_user.password = get_password_hash(new_password)
        db.commit()
        
        return {"message": "Password changed successfully"}
        
    except ValidationError:
        raise
    except AuthenticationError:
        raise
    except Exception as e:
        print(f"Change password error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password change failed"
        )


@router.post("/logout")
def logout(current_user: User = Depends(get_current_user)):
    """Logout user (invalidate token on client side)."""
    # In a real implementation with refresh tokens, you would:
    # 1. Invalidate the refresh token
    # 2. Add token to blacklist
    
    return {"message": "Logged out successfully"}