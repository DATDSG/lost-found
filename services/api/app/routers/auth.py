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