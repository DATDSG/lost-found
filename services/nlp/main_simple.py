"""
Minimal NLP Service for Lost & Found
-----------------------------------
Simple NLP service that works without external dependencies
"""

from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="NLP Service",
    description="Simple NLP service for Lost & Found",
    version="1.0.0"
)

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str = "1.0.0"
    service: str = "nlp"

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Simple health check endpoint."""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat()
    )

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "NLP Service is running", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
