import base64
import re

from config.constants import MAX_IMAGE_SIZE_MB


def validate_base64_image(data: str) -> bytes:
    clean = data
    if "," in clean:
        clean = clean.split(",", 1)[1]
    clean = re.sub(r"\s+", "", clean)
    try:
        decoded = base64.b64decode(clean, validate=True)
    except Exception as exc:
        raise ValueError("Invalid base64 image data") from exc
    return decoded


def validate_image_size(data: bytes, max_mb: int = MAX_IMAGE_SIZE_MB) -> None:
    size_mb = len(data) / (1024 * 1024)
    if size_mb > max_mb:
        raise ValueError(f"Image size {size_mb:.1f}MB exceeds limit of {max_mb}MB")


def sanitize_text_input(text: str) -> str:
    text = text.strip()
    text = re.sub(r"\x00", "", text)
    return text
