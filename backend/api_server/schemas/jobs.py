"""异步任务请求与响应模型模块，定义任务创建和状态查询的数据结构。"""

from dataclasses import asdict
from typing import Optional

from pydantic import BaseModel


class JobCreateRequest(BaseModel):
    """任务创建请求模型，包含任务类型和载荷数据。"""

    job_type: str
    payload: dict = {}


class JobStatusResponse(BaseModel):
    """任务状态响应模型，包含任务进度、结果和错误摘要。"""

    job_id: str
    job_type: str
    status: str
    progress: int = 0
    result: Optional[dict] = None
    error_summary: Optional[str] = None
