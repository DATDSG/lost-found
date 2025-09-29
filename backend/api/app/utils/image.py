from PIL import Image
from io import BytesIO

def to_jpeg(src: bytes, quality: int = 85) -> bytes:
    img = Image.open(BytesIO(src)).convert("RGB")
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=quality)
    return buf.getvalue()