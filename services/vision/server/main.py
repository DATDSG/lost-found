from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
import numpy as np
from PIL import Image
import imagehash
from io import BytesIO

app = FastAPI(title="vision-service")

class HashResponse(BaseModel):
    phash: str
    dhash: str
    ahash: str
    width: int
    height: int

class CompareRequest(BaseModel):
    h1: str
    h2: str

class CompareResponse(BaseModel):
    distance: int

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/hash", response_model=HashResponse)
async def hash_image(file: UploadFile = File(...)):
    data = await file.read()
    img = Image.open(BytesIO(data)).convert("RGB")
    ph = imagehash.phash(img)
    dh = imagehash.dhash(img)
    ah = imagehash.average_hash(img)
    w, h = img.size
    return HashResponse(phash=str(ph), dhash=str(dh), ahash=str(ah), width=w, height=h)

@app.post("/compare", response_model=CompareResponse)
async def compare(req: CompareRequest):
# Hamming distance between two hex hashes of same kind (e.g., pHash vs pHash)
# We accept mixed but real workflows should compare same-algorithm hashes.
    h1 = imagehash.hex_to_hash(req.h1)
    h2 = imagehash.hex_to_hash(req.h2)
    return CompareResponse(distance=int(h1 - h2))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8091)