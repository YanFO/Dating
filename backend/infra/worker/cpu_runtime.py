from infra.worker.worker_runtime import WorkerRuntime


class CPUWorkerRuntime(WorkerRuntime):
    """CPU-bound worker. Skeleton for future task processing."""

    def __init__(self):
        super().__init__(queue_name="cpu_queue")
