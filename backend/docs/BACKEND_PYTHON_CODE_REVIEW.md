# Backend Code Review Guideline
Audience: Human Reviewer + AI Agent Reviewer  
Scope: Quart-based backend with API + WebSocket, modules/agents, jobs/workers, infra/security

This document defines a **strict, repeatable code review protocol** that an AI agent (or human) must follow when reviewing backend code built under the previously defined Backend Development Guideline.

The goal of this review is **not style nitpicking**, but to ensure:
- architectural correctness
- long-term scalability
- infra-safety (timeout, queue, GPU, security)
- agent-compatibility (future automation & extension)

---

## 0) Mandatory Review Mindset (DO NOT SKIP)

Before reviewing any code, the reviewer (agent or human) MUST:

1. **Reconstruct System Intent**
   - What feature/module is being added or modified?
   - Is it agent-based, non-agent, or hybrid?
   - Is it sync (HTTP), streaming (WS), or async (job/worker)?

2. **Map the Change to Architecture**
   - Which layer(s) does this change touch?
     - api_server
     - modules
     - services
     - clients
     - infra
   - Is each responsibility placed in the correct layer?

3. **Assume the System Will Grow**
   - Multiple modules
   - Multiple workers
   - GPU + CPU mixed workloads
   - External services partially failing
   - Malicious or malformed input

If the code only works in a “happy path”, the review FAILS.

---

## 1) Review Order (Strict Sequence)

The reviewer MUST follow this order.  
Skipping steps is NOT allowed.

1. Architecture Placement Review
2. Dependency & Import Review
3. Responsibility & Boundary Review
4. API / WebSocket Review
5. Job / Worker / Queue Review (if applicable)
6. Infra & Resource Governance Review
7. Timeout / Retry / Failure Review
8. Security Review
9. Observability Review
10. Final Scalability & Maintainability Judgment

---

## 2) Architecture Placement Review (Hard Gate)

### Checklist
For every new or modified file, answer:

- Does this file live in the correct top-level directory?
  - api_server → transport & wiring only
  - modules → domain logic
  - services → cross-module reusable services
  - clients → external calls
  - infra → workers, queues, db, security
  - utils → pure helpers
  - scripts → human-only, never imported

### Immediate Reject Conditions
- Router imports a client directly
- Module imports `api_server/*`
- Business logic inside `main.py`
- Worker logic inside `api_server`
- Scripts imported by runtime code

If any occur → **REJECT PR**

---

## 3) Dependency & Import Review (Graph Sanity)

### Required Import Direction (Only This Is Allowed)

- api_server → services → modules → clients
- infra → modules / services / clients
- utils → everywhere
- config → everywhere
- scripts → nowhere (runtime)

### Red Flags
- Circular imports across layers
- A module importing another module’s internals directly (except via service)
- Direct environment variable access outside `config/settings.py`

Reviewer must explicitly state:
> “Import graph is valid” or “Import graph violation found: …”

---

## 4) Responsibility & Boundary Review

For each function/class reviewed:

### Questions the Reviewer MUST Answer
1. What is the **single responsibility** of this unit?
2. Is that responsibility:
   - transport-level?
   - domain-level?
   - infra-level?
3. Is any responsibility leaking across layers?

### Common Violations
- Router validating business rules
- Service parsing raw HTTP request objects
- Module doing auth token parsing
- Client deciding retry logic inconsistently

If a function does more than one architectural responsibility → **Request Refactor**

---

## 5) API (HTTP) Review

### Mandatory API Rules
- Input validation via api_server/schemas
- Output wrapped in standard response envelope
- No blocking calls in request handler
- Clear error mapping (domain error → HTTP code)

### Reviewer Checklist
- Are unknown fields rejected?
- Are error messages safe (no stack traces, no secrets)?
- Is request_id propagated?
- Is response shape consistent?

### Reject If
- Raw dicts used instead of schema
- Blocking CPU/GPU work in router
- Silent exception swallowing

---

## 6) WebSocket Review (If Present)

### WS-Specific Rules
- Authentication on connect
- No heavy compute in WS handler
- Uses stream_service or pubsub
- Handles disconnects & heartbeats

### Reviewer Checklist
- Is WS used only for streaming/progress?
- Are messages typed (progress/log/chunk/done/error)?
- Is backpressure considered?

### Reject If
- WS handler calls external APIs directly
- Long loops without await
- No disconnect cleanup

---

## 7) Jobs / Workers / Queue Review (Critical for Scale)

### Mandatory for Long-Running Tasks
- API enqueues job → returns job_id
- Worker executes job
- Progress/events streamed via WS

### Reviewer Checklist
- Is the job definition in modules/jobs/definitions?
- Is execution handled in infra/queue/tasks?
- Is job state persisted and recoverable?
- Are retries bounded and explicit?

### GPU/CPU Governance Check
- Does task declare `requires_gpu`?
- Is routing logic used?
- Is CUDA_VISIBLE_DEVICES respected?

### Reject If
- API server executes long task inline
- GPU logic runs in HTTP process
- Job has no timeout or cancel path

---

## 8) Infra & Resource Governance Review

### CPU
- CPU-bound work offloaded to worker/process pool
- No blocking calls in async event loop

### GPU
- One worker per GPU (or explicit sharing logic)
- Memory usage considered
- Model loading not repeated per task unnecessarily

### Networking
- Connection pooling used
- Timeouts defined
- Circuit breaker or failure isolation present

Reviewer must explicitly state:
> “Resource governance acceptable” or list risks.

---

## 9) Timeout / Retry / Failure Review (MANDATORY)

### Reviewer MUST Identify
- All external calls made
- Their timeout configuration
- Retry behavior
- Failure handling strategy

### Reject If
- External call without timeout
- Infinite retry possibility
- Failure causes cascade (e.g., blocking worker forever)

---

## 10) Security Review (Non-Negotiable)

### Checklist
- Authentication enforced?
- Authorization checked at correct layer?
- Rate limiting applied?
- Secrets never logged?
- Input validation strict?
- Audit log written for sensitive actions?

### WS Security
- Token verified on connect
- Channel access controlled
- Message size limited

### Reject If
- Trusting client-provided IDs without auth
- Logging tokens or secrets
- Missing auth on WS

---

## 11) Observability Review

### Mandatory Signals
- Structured logs
- request_id / job_id propagation
- Meaningful error logs
- No noisy debug logs in prod path

Reviewer should ask:
> “If this fails in prod at 3am, can we diagnose it?”

If not → request improvements.

---

## 12) Agent-Specific Review (If Module Uses Agents)

### Additional Checks
- Tools registered via registry (not ad-hoc)
- Prompts versioned and isolated
- Personas constrained (no unrestricted tool access)
- Context builder deterministic & explainable

### Reject If
- Tools called without metadata
- Prompt logic scattered across files
- Agent allowed to call infra/client directly

---

## 13) Scalability & Future-Proofing Judgment

The reviewer MUST answer these questions explicitly:

1. Can this feature run safely with 10x traffic?
2. Can it coexist with other modules without coupling?
3. Can it be moved to another machine/service later?
4. Can an agent extend this without breaking rules?

If any answer is “no”, reviewer must explain why and propose a fix.

---

## 14) Required Review Output Format (Agent MUST follow)

The final review response MUST include:

1. **Summary**
   - What was reviewed
   - Overall verdict: APPROVE / REQUEST CHANGES / REJECT

2. **Architecture Compliance**
   - Pass/Fail with reasons

3. **Critical Issues (if any)**
   - Numbered list, highest severity first

4. **Non-Critical Improvements**
   - Suggestions, not blockers

5. **Security & Infra Assessment**
   - Explicit statement

6. **Final Recommendation**
   - Merge / Revise / Redesign

---

## 15) Absolute Reject Conditions (Immediate Stop)

If ANY of the following are found:
- Security bypass
- Blocking GPU/CPU work in API server
- Missing timeout on external calls
- Cross-layer import violations
- Long-running task without job/worker

→ Verdict MUST be **REJECT**, no exceptions.

---

## 16) Closing Rule

A backend code review is **not complete** unless the reviewer can confidently say:

> “This code will still be safe, maintainable, and extensible when the system is 5x larger, runs on multiple machines, and is partially operated by agents.”

If that statement cannot be made truthfully, the review FAILS.