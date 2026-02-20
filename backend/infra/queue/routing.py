from dataclasses import dataclass


@dataclass
class QueueConfig:
    queue_name: str
    priority: int = 0
    timeout: int = 300


def route_task(
    task_type: str,
    requires_gpu: bool = False,
    priority: int = 0,
) -> QueueConfig:
    if requires_gpu:
        return QueueConfig(queue_name="gpu_queue", priority=priority)
    if task_type.startswith("io_"):
        return QueueConfig(queue_name="io_queue", priority=priority)
    return QueueConfig(queue_name="cpu_queue", priority=priority)
