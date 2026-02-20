from dataclasses import asdict
from typing import Optional

from pydantic import BaseModel


class JobCreateRequest(BaseModel):
    job_type: str
    payload: dict = {}


class JobStatusResponse(BaseModel):
    job_id: str
    job_type: str
    status: str
    progress: int = 0
    result: Optional[dict] = None
    error_summary: Optional[str] = None
