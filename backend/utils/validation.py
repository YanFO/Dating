"""输入验证工具模块，提供图像与文本输入的校验与清理功能。"""

import base64
import re

from config.constants import MAX_IMAGE_SIZE_MB


def validate_base64_image(data: str) -> bytes:
    """验证并解码 base64 编码的图像数据，返回原始字节。"""
    clean = data
    if "," in clean:
        clean = clean.split(",", 1)[1]
    clean = re.sub(r"\s+", "", clean)
    decoded = base64.b64decode(clean, validate=True)
    return decoded


def validate_image_size(data: bytes, max_mb: int = MAX_IMAGE_SIZE_MB) -> None:
    """检查图像大小是否超过限制，超过则抛出 ValueError。"""
    size_mb = len(data) / (1024 * 1024)
    if size_mb > max_mb:
        raise ValueError(f"Image size {size_mb:.1f}MB exceeds limit of {max_mb}MB")


def sanitize_text_input(text: str) -> str:
    """清理文本输入：去除首尾空白与空字符。"""
    text = text.strip()
    text = re.sub(r"\x00", "", text)
    return text
