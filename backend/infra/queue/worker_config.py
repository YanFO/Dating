from dataclasses import dataclass


@dataclass
class WorkerConfig:
    queue_name: str = "cpu_queue"
    concurrency: int = 4
    poll_interval: float = 1.0
    graceful_shutdown_timeout: float = 30.0
