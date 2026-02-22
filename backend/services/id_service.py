"""ID 生成服務

提供各模組所需的唯一識別碼生成函數。
- DB 主鍵使用 CUID2（與 Prisma @default(cuid()) 對齊）
- 請求追蹤使用 UUID4
"""

import uuid

from cuid2 import cuid_wrapper

# 建立 CUID2 生成器（預設 24 字元長度）
_cuid_generator = cuid_wrapper()


def generate_cuid() -> str:
    """生成 CUID2 主鍵（與 Prisma schema 對齊）"""
    return _cuid_generator()


def generate_request_id() -> str:
    """生成請求追蹤 ID（完整 UUID4）"""
    return str(uuid.uuid4())
