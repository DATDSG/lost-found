from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Minimal FastAPI app for testing
app = FastAPI(
    title="Lost & Found API",
    description="Tri-lingual Lost & Found System",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    """Health check endpoint."""
    return {
        "status": "ok",
        "app": "Lost & Found API",
        "version": "2.0.0",
        "message": "System is running!"
    }

@app.get("/")
def root():
    """Root endpoint with API information."""
    return {
        "message": "Lost & Found API - Minimal Version",
        "version": "2.0.0",
        "docs": "/docs",
        "health": "/health",
        "status": "✅ API is working!"
    }

@app.get("/test")
def test():
    """Simple test endpoint."""
    return {
        "message": "Test successful!",
        "features": {
            "baseline_matching": "Ready",
            "geospatial_search": "Ready", 
            "multilingual": "Ready (si/ta/en)",
            "status": "✅ All systems go!"
        }
    }
