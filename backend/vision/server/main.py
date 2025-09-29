from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from pydantic_settings import BaseSettings
import numpy as np
from PIL import Image
import imagehash
from io import BytesIO


class Settings(BaseSettings):
    APP_NAME: str = "vision-service"
    HOST: str = "0.0.0.0"
    PORT: int = 8091
    IMAGE_MODEL_VERSION: str = "phash-v1"

    class Config:
        env_file = ".env"


settings = Settings()

app = FastAPI(title=settings.APP_NAME)

class HashResponse(BaseModel):
    phash: str
    dhash: str
    ahash: str
    width: int
    height: int
    model_version: str

class CompareRequest(BaseModel):
    h1: str
    h2: str

class CompareResponse(BaseModel):
    distance: int

@app.get("/health")
def health():
    return {
        "status": "ok",
        "model_version": settings.IMAGE_MODEL_VERSION,
    }

@app.post("/hash", response_model=HashResponse)
async def hash_image(file: UploadFile = File(...)):
    data = await file.read()
    img = Image.open(BytesIO(data)).convert("RGB")
    ph = imagehash.phash(img)
    dh = imagehash.dhash(img)
    ah = imagehash.average_hash(img)
    w, h = img.size
    return HashResponse(
        phash=str(ph),
        dhash=str(dh),
        ahash=str(ah),
        width=w,
        height=h,
        model_version=settings.IMAGE_MODEL_VERSION,
    )

@app.post("/compare", response_model=CompareResponse)
async def compare(req: CompareRequest):
# Hamming distance between two hex hashes of same kind (e.g., pHash vs pHash)
# We accept mixed but real workflows should compare same-algorithm hashes.
    h1 = imagehash.hex_to_hash(req.h1)
    h2 = imagehash.hex_to_hash(req.h2)
    return CompareResponse(distance=int(h1 - h2))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)