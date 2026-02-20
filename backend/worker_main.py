"""Worker process entry point. Subscribes to queues and runs task handlers.

Usage:
    python worker_main.py --queue cpu_queue
"""

import argparse
import asyncio

from config.settings import load_settings
from config.logging import setup_logging
from infra.worker.worker_runtime import WorkerRuntime


def main():
    parser = argparse.ArgumentParser(description="Dating Lens Worker")
    parser.add_argument("--queue", default="cpu_queue", help="Queue to consume from")
    args = parser.parse_args()

    settings = load_settings()
    setup_logging(settings)

    runtime = WorkerRuntime(queue_name=args.queue)
    asyncio.run(runtime.start())


if __name__ == "__main__":
    main()
