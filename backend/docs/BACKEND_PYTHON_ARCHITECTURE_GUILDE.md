# Backend Development Guideline (Quart + API + WebSocket + Modules + Jobs/Workers + Security/Infra)
Owner: Backend Architecture
Goal: This guideline defines a scalable backend structure that supports: (1) modular features (agent + non-agent systems), (2) Quart HTTP + WebSocket in one app, (3) jobs/workers/queues, (4) CPU/GPU routing & resource governance, (5) infra-grade concerns (timeouts/retries, security, networking), and (6) consistent code quality so that an agent can follow it to implement new features safely.

---

## 0) Non-negotiable Principles (Agent must follow)
1. Single Entry Policy:
   - All runtime entrypoints live at repository root (e.g., `main.py`, `worker_main.py`, `job_runner.py`).
   - `api_server/` contains assembly logic (create_app, routes, middleware, lifecycle). It MUST NOT directly run the server.

2. Module-first Architecture:
   - Features are organized as `modules/<feature>/...`.
   - "Agent" is a feature module, not the entire system identity.
   - Any new capability (e.g. TTS, Retrieval, Finance, OCR) becomes a module, regardless of whether it uses agents internally.

3. Thin Router, Thick Service:
   - Routers (HTTP/WS) only validate input, call service layer, and return responses.
   - Business logic MUST live in modules/services.

4. No Cross-layer Violations:
   - Routers MUST NOT import clients directly (only through services).
   - Modules MUST NOT import `api_server/*` (no coupling to transport layer).
   - Scripts MUST NOT be imported by runtime code.

5. Observability & Safety by Default:
   - Every external call must enforce timeouts.
   - Every request must have a request_id / trace_id.
   - Security controls (authn/authz, rate limiting, validation) are default, not optional.

---

## 1) Recommended Repository Structure (Canonical)
backend/
  main.py                         # HTTP + WebSocket entrypoint (run server)
  worker_main.py                  # Worker entrypoint (queue consumers)
  job_runner.py                   # Batch job runner entrypoint (optional)
  run_migration.py                # Migration runner (manual/CI)
  requirements.txt
  README.md
  .env
  .gitignore

  api_server/
    app.py                        # create_app(settings) -> Quart app
    lifecycle.py                  # startup/shutdown hooks
    http.py                       # http wiring (blueprints, error handlers)
    websocket.py                  # ws wiring (ws routes registration)
    middlewares/
      auth.py
      rate_limit.py
      tracing.py
      cors.py
      security_headers.py
    routers/                      # HTTP routers only
      health.py
      api_v1.py
      agent.py
      jobs.py
    schemas/                      # Transport DTO (request/response)
      common.py
      agent.py
      tts.py
      jobs.py

  modules/                        # Feature modules (domain-oriented)
    agent/
      README.md                   # how to extend tools/subagents/prompts/personas safely
      supervisor/
        supervisor.py
        policies.py               # routing rules, tool policies
      subagents/
        __init__.py
        planner.py
        executor.py
        critic.py
      tools/
        __init__.py
        registry.py               # tool registration & metadata
        builtin/
          web.py
          retrieval.py
          memory.py
      prompts/
        system/
          base.md
          safety.md
        templates/
          reasoning.md
          tool_call.md
      personas/
        default.yaml
        analyst.yaml
      context/
        builder.py                # build context pack (memory/retrieval/user state)
        schemas.py                # internal context schemas (NOT API schemas)
      service.py                  # Agent orchestration service (HTTP/WS calls here)
      models.py                   # internal domain models
      errors.py                   # domain errors

    retrieval/
      README.md
      service.py
      reranker.py
      index/
        builder.py
        query.py
      models.py

    jobs/                         # Core job definitions (domain-agnostic orchestration)
      README.md
      registry.py                 # job type registry
      service.py                  # job submission/status/cancel
      models.py                   # job models/state machine
      errors.py
      definitions/
        ingest_documents.py
        build_index.py

  services/                       # Cross-module shared services (infra-aware, reusable)
    auth_service.py               # token validation, session
    task_service.py               # shared async task primitives
    stream_service.py             # pubsub streams for ws
    id_service.py                 # request_id/job_id generation
    policy_service.py             # access policies, feature flags

  clients/                        # External dependencies wrapper (timeouts/retries enforced)
    http/
      base.py                     # shared http client with retry/timeout
    llm/
      openai_client.py
      local_vllm_client.py
    vector_db/
      weaviate_client.py
      milvus_client.py
    sql/
      postgres.py
      sqlite.py
    cache/
      redis_client.py
    queue/
      redis_queue.py              # enqueue/dequeue primitives
    observability/
      metrics.py
      tracing.py

  infra/                          # Runtime infrastructure wiring (workers, queues, db, security)
    database/
      engine.py                   # create_engine, pool settings
      session.py                  # session management
      migrations/
    queue/
      routing.py                  # cpu/gpu/io queue routing rules
      worker_config.py            # concurrency, prefetch, ack strategies
      tasks/                      # task handlers (invoke modules/services)
        agent_tasks.py
        job_tasks.py
    worker/
      worker_runtime.py           # worker loop, shutdown handling
      gpu_runtime.py              # GPU worker specifics
      cpu_runtime.py              # CPU worker specifics
    jobs/
      scheduler.py                # schedule recurring jobs (optional)
      executor.py                 # run job definition with state transitions
    security/
      secrets.py                  # secrets retrieval, redaction
      audit_log.py                # audit logging
      ip_allowlist.py

  config/
    settings.py                   # all env configuration parsing + validation
    constants.py
    feature_flags.py
    logging.py

  utils/                          # Pure helpers (no side-effects)
    time.py
    json.py
    async_tools.py
    retry.py
    validation.py
    crypto.py

  scripts/                        # Human/CI-only (never imported)
    init_db.py
    seed.py
    migrate.py
    debug_env.py

---

## 2) Entry Points: What runs and why
### 2.1 main.py (Only entrypoint for API + WebSocket)
Responsibilities:
- Load settings from `config/settings.py`
- Create Quart app via `api_server/app.py:create_app(settings)`
- Run server (hypercorn or uvicorn-like ASGI runner for Quart)
Rules:
- No business logic in main.py
- No direct DB schema logic
- No tool registration here; do it in create_app or lifecycle

Example skeleton:
---
from config.settings import load_settings
from api_server.app import create_app

def main():
    settings = load_settings()
    app = create_app(settings)
    # run with hypercorn programmatically or via CLI
    # Prefer CLI: hypercorn main:app --bind 0.0.0.0:8000

app = None
settings = load_settings()
app = create_app(settings)
---
Notes:
- Provide `app` at module level so hypercorn can import it.

### 2.2 worker_main.py (Worker entrypoint)
Responsibilities:
- Load settings
- Start worker runtime (cpu worker, gpu worker, io worker)
- Subscribe to queues and run task handlers (infra/queue/tasks/*)
Rules:
- Worker MUST NOT import api_server/*
- Worker runs long tasks; API server remains responsive

### 2.3 job_runner.py (Batch runner entrypoint)
Responsibilities:
- Run batch operations on demand (CLI)
- Useful for controlled batch runs, migrations, scheduled tasks

---

## 3) api_server Layer Rules (HTTP + WS in same Quart app)
### 3.1 app.py
Must do:
- Instantiate Quart app
- Register middleware
- Register HTTP routers (blueprints)
- Register WS routes
- Register lifecycle hooks (startup/shutdown)

Must NOT do:
- run server
- import module internals directly unless wiring; keep logic minimal

### 3.2 routers/ (HTTP)
Responsibilities:
- Parse & validate input (api_server/schemas)
- Auth context injection (via middleware)
- Call services: modules/*/service.py or services/*
- Return standardized response envelope

Router MUST NOT:
- call clients directly
- implement heavy logic
- do DB transactions directly

### 3.3 ws/ (WebSocket)
Responsibilities:
- Authenticate on connect (token in query/header)
- Join stream channels (job_id, session_id)
- Forward streaming outputs from stream_service
- Send heartbeats and handle disconnect gracefully

WS MUST NOT:
- do heavy compute
- call external APIs directly
- block event loop

---

## 4) Modules Layer: Feature-oriented design
### 4.1 Module boundaries
A module owns:
- Domain models (models.py)
- Domain errors (errors.py)
- Service API (service.py)
- Internal orchestration / pipeline (pipeline.py optional)
- Adapters to external systems (adapters/ optional)

A module MUST NOT own:
- HTTP schemas (those are transport-level under api_server/schemas)
- Global settings parsing (belongs in config/settings.py)
- Shared infra (belongs in infra/ or services/)

### 4.2 Agent Module (modules/agent) Detailed Requirements
Directory meanings:
- supervisor/: "Orchestration brain" deciding which subagent/tool runs
  - supervisor.py: entrypoint of orchestration
  - policies.py: routing policies (e.g., tool choice, constraints)
- subagents/: Each subagent is a small deterministic unit with:
  - clear input schema
  - clear output schema
  - no hidden side effects
- tools/:
  - registry.py: single source of truth of tool metadata
  - builtin/: built-in tools, each tool must:
    - validate args
    - enforce timeouts for external calls via clients
    - return typed result
- prompts/:
  - system/: system prompts shared across runs
  - templates/: composable prompt pieces
  - prompts must be versioned and have test coverage (snapshot tests)
- personas/:
  - YAML-defined persona specs
  - MUST include constraints: tone, domain, refusal policy, tool policy
- context/:
  - builder.py: builds a "context pack" from memory, retrieval, user state
  - schemas.py: internal context schema, stable versioning

Agent service (service.py) must support:
- sync call (HTTP)
- streaming call (WS)
- job-based call (enqueue to worker for long runs)

Agent service must define:
- run_session(input) -> output
- stream_session(input) -> async generator
- enqueue_session(input) -> job_id

### 4.3 Non-agent Modules (e.g., TTS)
A TTS module must support:
- short inference path (<= few seconds): HTTP response
- long/streaming path: WS streaming or job streaming
- batch path: jobs module integration

Adapters must be isolated:
- adapters/cosyvoice3.py handles model interface; no HTTP/WS concerns

---

## 5) services/ Layer: Cross-module Services
Use `services/` for:
- auth_service: auth context, token parsing, permission checks
- stream_service: pubsub event bus for WS streaming
- task_service: unify job enqueue & status, across modules
- policy_service: feature flags, access control

Rules:
- services/ may call clients/
- services/ may be used by api_server & modules
- services/ MUST be stateless or have clearly managed lifecycle resources

---

## 6) clients/ Layer: External Call Governance (Timeout/Retry Mandatory)
### 6.1 Every external call MUST enforce:
- connect timeout
- read timeout
- total timeout
- retry policy (bounded)
- circuit breaker (recommended)

Client base behavior:
- Default timeouts:
  - connect_timeout: 2s
  - read_timeout: 30s (tune by service)
  - total_timeout: 35s
- Retry:
  - only for idempotent operations
  - exponential backoff with jitter
  - max attempts: 3

Clients MUST:
- expose typed methods (no raw requests scattered)
- implement request_id propagation
- redact secrets in logs

Example client usage pattern:
---
result = await llm_client.generate(prompt, timeout=25, request_id=req_id)
---

---

## 7) infra/ Layer: Workers, Queues, Jobs, Database, Security
### 7.1 Queues & Routing (CPU/GPU/IO split)
You MUST implement queue routing:
- cpu_queue: CPU-only tasks (parsing, DB ops, small LLM calls if allowed)
- gpu_queue: GPU-required tasks (TTS synthesis, large model inference)
- io_queue: network-heavy tasks (crawl, download, large uploads)

Routing rules live in:
- infra/queue/routing.py

Routing inputs:
- task_type
- expected_runtime
- requires_gpu (bool)
- memory_estimate_mb
- priority

Minimum routing outputs:
- queue_name
- concurrency_limit
- prefetch_limit
- retry_policy

### 7.2 Worker Runtimes (CPU/GPU core usage governance)
CPU worker:
- Concurrency: limited by CPU cores (e.g., n_cores - 1)
- Async tasks: avoid blocking event loop
- Use process-level concurrency for heavy CPU tasks

GPU worker:
- One worker process per GPU device is recommended
- Set `CUDA_VISIBLE_DEVICES` at process start
- Enforce per-task GPU memory policy:
  - refuse tasks if memory estimate > available
  - optional: queue with backpressure

Core governance:
- CPU affinity (optional):
  - pin heavy CPU workers to specific cores
- GPU governance:
  - lock GPU per worker
  - do not allow multiple heavy models per process unless managed

### 7.3 Jobs System (infra/jobs + modules/jobs)
You requested `infra/jobs/` — implement as execution infrastructure; job definitions live in `modules/jobs/definitions`.

Split responsibilities:
- modules/jobs:
  - job registry (job types)
  - job state machine models
  - job submission API (create/cancel/status)
  - job definitions (what to do)
- infra/jobs:
  - job executor runtime
  - scheduler (optional cron-like scheduling)
  - state persistence strategy

Job lifecycle (minimum):
- PENDING -> RUNNING -> SUCCEEDED | FAILED | CANCELED
- progress: 0..100
- metadata: logs pointer, artifacts pointer
- retry_count, error_summary

Job persistence:
- Start with Redis (fast) or SQL (durable)
- Must support: get_job(job_id), update_job(job_id, patch)

Streaming:
- Jobs publish events to stream_service:
  - job.progress
  - job.log
  - job.output_chunk
WS subscribes by job_id.

### 7.4 Database (infra/database)
Rules:
- DB engine/session only in infra/database
- Repositories (optional) should live under modules/<feature>/repo.py or clients/sql/*
- Migrations only in infra/database/migrations

If you must run embedded DB inside backend:
- Provide startup hook to initialize DB
- Provide graceful shutdown hook

### 7.5 Security (infra/security + api_server/middlewares)
Security MUST include:
1) Authentication:
   - HTTP: Authorization header (Bearer JWT / API Key)
   - WS: token on connect, verified once then bound to connection
2) Authorization:
   - role/permission check at router/service boundary
3) Input Validation:
   - strict schema validation for all requests
   - reject unknown fields by default
4) Rate Limiting:
   - per-IP + per-user + per-token
   - separate limits for HTTP and WS
5) Security Headers:
   - HSTS, X-Content-Type-Options, etc.
6) Audit Logging:
   - log who did what (user_id, action, resource_id, timestamp)
   - redact PII and secrets
7) Secrets Handling:
   - never log secrets
   - env/vault only
   - rotate keys friendly

WS security notes:
- Implement heartbeat/ping to detect stale connections
- Apply message size limits
- Apply channel access control (job_id must belong to user)

---

## 8) WebSocket + API Integration Pattern (Canonical)
API is for control plane:
- POST /jobs -> create job, return job_id
- GET /jobs/<id> -> status
- POST /agent/run -> short sync run (if allowed)
- POST /agent/enqueue -> long run, return job_id

WS is for data plane:
- WS /ws/jobs/<job_id> -> stream progress/log/output
- WS /ws/agent/<session_id> -> stream tokens/events

Rules:
- Never stream large payloads via HTTP; use WS
- Never do compute in WS handler; subscribe to stream_service

---

## 9) Middleware Standard (api_server/middlewares)
Must include:
- tracing.py: request_id, trace_id injection, propagate downstream
- auth.py: parse token, attach user context
- rate_limit.py: enforce per route group
- cors.py: strict allowlist
- security_headers.py: set headers

Error handling:
- Centralized error handler maps domain errors -> HTTP codes
- Do not leak stack traces in prod

---

## 10) Timeout & Retry Policy (Mandatory)
### 10.1 External HTTP calls
- connect_timeout: 2s
- read_timeout: 30s
- total_timeout: 35s
- retries: 0-3 based on idempotency

### 10.2 DB calls
- pool_timeout: limited
- query timeout (if supported)

### 10.3 LLM calls
- Hard cap per request
- Token streaming requires backpressure
- If streaming stalls > N seconds, cancel

### 10.4 WS
- heartbeat interval: 15-30s
- disconnect if no pong after 2 intervals

---

## 11) Logging / Observability
Must include:
- structured logs (json)
- request_id on every log
- job_id on job logs
- latency metrics per route
- external call metrics (success/fail, latency, timeout count)

Redaction:
- tokens, keys, passwords MUST be redacted

---

## 12) PM2 Deployment Standard (uv + venv + ecosystem)
### 12.1 Environment
- Use `uv venv .venv`
- Install dependencies via `uv pip install -r requirements.txt`

### 12.2 PM2 apps
- backend-api: run Quart via hypercorn import of `main:app`
- backend-worker-cpu: run `worker_main.py` with cpu_queue
- backend-worker-gpu0: run worker with CUDA_VISIBLE_DEVICES=0
- backend-worker-gpu1: run worker with CUDA_VISIBLE_DEVICES=1 (optional)

Example ecosystem.config.js layout:
---
module.exports = {
  apps: [
    {
      name: "backend-api",
      cwd: "/path/to/backend",
      script: ".venv/bin/hypercorn",
      args: ["main:app", "--bind", "0.0.0.0:8000", "--workers", "1"],
      autorestart: true,
      env: { ENV: "prod" }
    },
    {
      name: "backend-worker-cpu",
      cwd: "/path/to/backend",
      script: ".venv/bin/python",
      args: ["-m", "worker_main", "--queue", "cpu_queue"],
      autorestart: true,
      env: { ENV: "prod" }
    },
    {
      name: "backend-worker-gpu0",
      cwd: "/path/to/backend",
      script: ".venv/bin/python",
      args: ["-m", "worker_main", "--queue", "gpu_queue"],
      autorestart: true,
      env: { ENV: "prod", CUDA_VISIBLE_DEVICES: "0" }
    }
  ]
}
---

---

## 13) Code Style & Contracts (Agent must follow)
1) Every service/module public method must have:
- input schema (typed)
- output schema (typed)
- explicit error types

2) Avoid global singletons except:
- settings
- logger
- connection pools managed by lifecycle

3) Async correctness:
- Do not block event loop
- Use threadpool/processpool for CPU-bound tasks

4) Versioning:
- schemas and prompts must be versioned if changes are not backward compatible

5) Forbidden patterns:
- routers importing clients
- modules importing api_server
- scripts imported by runtime
- hidden side effects on import

---

## 14) Implementation Checklist for Adding a New Feature Module
When adding `modules/<new_feature>`:
1. Create `README.md` describing purpose and boundaries
2. Add `service.py`, `models.py`, `errors.py`
3. Add `adapters/` if external integrations exist
4. Add HTTP router `api_server/routers/<new_feature>.py`
5. Add DTO `api_server/schemas/<new_feature>.py`
6. Add WS route only if streaming/progress needed
7. If long-running:
   - add job definition in `modules/jobs/definitions/<new_feature>_*.py`
   - add task handler in `infra/queue/tasks/`
8. Add security rules:
   - permissions in auth_service / policy_service
   - rate limit policy
9. Add timeouts for all external calls
10. Add tests: schema validation, service unit tests, integration tests

---

## 15) Minimal Standard Response Envelope (HTTP)
- success: bool
- request_id: string
- data: object | null
- error: { code, message, details } | null

WS message standard:
- type: "progress" | "log" | "chunk" | "done" | "error"
- request_id
- job_id/session_id
- payload

---

## 16) Final Notes
- This architecture intentionally supports: agent-first, non-agent features, heavy GPU workloads, batch jobs, and secure streaming.
- Keep the app assembly thin, the services clear, and infra isolated.
- Whenever uncertain where a code should go: place it where its responsibility is most stable. Transport concerns in api_server, domain concerns in modules, infra concerns in infra, external calls in clients.
