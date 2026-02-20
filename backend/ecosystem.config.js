module.exports = {
  apps: [
    {
      name: "dating-lens-api",
      cwd: "/home/ubuntu/Dating_Lens/backend",
      script: ".venv/bin/hypercorn",
      args: ["main:app", "--bind", "0.0.0.0:8000", "--workers", "1"],
      autorestart: true,
      max_memory_restart: "500M",
      env: {
        ENV: "dev",
      },
      env_production: {
        ENV: "prod",
      },
    },
    {
      name: "dating-lens-worker-cpu",
      cwd: "/home/ubuntu/Dating_Lens/backend",
      script: ".venv/bin/python",
      args: ["worker_main.py", "--queue", "cpu_queue"],
      autorestart: true,
      env: {
        ENV: "dev",
      },
    },
  ],
};
