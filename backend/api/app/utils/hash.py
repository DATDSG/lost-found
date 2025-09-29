from PIL import Image
import imagehash

def phash_hex(img: Image.Image) -> str:
    return str(imagehash.phash(img))