"""Authentication routes."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User
from ..schemas import UserRegister, UserLogin, Token, UserResponse
from ..auth import get_password_hash, verify_password, create_access_token, create_refresh_token, decode_token
from ..dependencies import get_current_user
from ..exceptions import ValidationError, ConflictError, AuthenticationError
from ..validation import UserValidationMixin

router = APIRouter()


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
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
            hashed_password=get_password_hash(validated_password),
            display_name=validated_display_name,
            role="user"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # Generate tokens (convert UUID to string for JWT)
        access_token = create_access_token(data={"sub": str(user.id)})
        refresh_token = create_refresh_token(data={"sub": str(user.id)})
        
        return Token(access_token=access_token, refresh_token=refresh_token)
        
    except ValidationError:
        # Re-raise validation errors as-is
        raise
    except ConflictError:
        # Re-raise conflict errors as-is
        raise
    except Exception as e:
        # Handle unexpected errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed"
        )


@router.post("/login", response_model=Token)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """Login and get access tokens."""
    try:
        # Validate email format
        validator = UserValidationMixin()
        validated_email = validator.validate_email_address(credentials.email)
        
        # Find user
        user = db.query(User).filter(User.email == validated_email).first()
        
        if not user or not verify_password(credentials.password, user.hashed_password):
            raise AuthenticationError("Incorrect email or password")
        
        if not user.is_active:
            raise AuthenticationError("User account is disabled")
        
        # Generate tokens (convert UUID to string for JWT)
        access_token = create_access_token(data={"sub": str(user.id)})
        refresh_token = create_refresh_token(data={"sub": str(user.id)})
        
        return Token(access_token=access_token, refresh_token=refresh_token)
        
    except ValidationError:
        # Re-raise validation errors as-is
        raise
    except AuthenticationError:
        # Re-raise authentication errors as-is
        raise
    except Exception as e:
        # Handle unexpected errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed"
        )


@router.post("/refresh", response_model=Token)
def refresh(refresh_token: str, db: Session = Depends(get_db)):
    """Refresh access token using refresh token."""
    payload = decode_token(refresh_token)
    
    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    # Generate new tokens
    new_access_token = create_access_token(data={"sub": user.id})
    new_refresh_token = create_refresh_token(data={"sub": user.id})
    
    return Token(access_token=new_access_token, refresh_token=new_refresh_token)


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Get current user information."""
    return current_user
