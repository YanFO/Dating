# Frontend Agent Guideline
## Next.js + React + TypeScript + Tailwind + shadcn/ui

---

## 0. Guideline Purpose（Agent 行為定位）

This document defines **non-negotiable architectural rules** for frontend development.

The agent must:
- Prioritize **system consistency over local optimization**
- Treat UI as a **deterministic function of state**
- Treat TypeScript as a **hard architectural constraint**
- Treat Tailwind + shadcn as a **design decision system**, not styling tools
- Enforce **modularity, separation of concerns, and predictable data flow**

The agent is NOT allowed to:
- Freestyle component structure
- Mix domain logic into UI components
- Bypass typing for speed
- Introduce implicit state or hidden side effects

---

## 1. Mental Model（核心心智模型）

### 1.1 Rendering Model (React)

UI = f(state, props)

- Rendering is **pure computation**
- Rendering must NOT cause side effects
- Rendering may run multiple times
- Rendering does NOT equal DOM mutation

Side effects are ONLY allowed in:
- useEffect
- server actions
- API routes

---

### 1.2 State Model（狀態模型）

State represents **truth**, not temporary UI hacks.

Rules:
- State must be explicit
- State must be typed
- State transitions must be predictable
- Invalid state must be unrepresentable

Prefer:
- Union-based state machines
- Lifted state over duplicated local state
- Controlled components over uncontrolled ones

---

### 1.3 Data Flow Model（資料流）

- Data flows **top-down** (parent → child)
- Events flow **bottom-up** (child → parent)
- No circular dependencies
- No implicit global mutation

---

## 2. Project Structure（專案結構）

---

```
frontend/
├── app/                         # Next.js App Router
│   ├── layout.tsx               # Root layout with providers
│   ├── page.tsx                 # Home page
│   ├── test/                    # Exam workflow pages
│   │   ├── generate/            # Question generation
│   │   ├── preview/[id]/        # Exam preview
│   │   ├── take/[id]/           # Take exam
│   │   └── results/[id]/        # View results
│   ├── solve/                   # Problem solving page
│   ├── wrong-answers/           # Wrong answer book
│   └── design-system/           # Design system showcase
├── components/                  # React components
│   ├── ui/                      # shadcn/ui base components
│   ├── questions/               # Question-related components
│   ├── camera/                  # Camera capture components
│   ├── results/                 # Result display components
│   ├── layout/                  # Layout components (header, nav)
│   ├── modals/                  # Modal components
│   ├── providers/               # Context providers
│   └── companion/               # AI companion components
├── lib/                         # Utilities and helpers
│   ├── api.ts                   # Backend API client
│   ├── stores/                  # Zustand state stores
│   │   ├── exam-store.ts        # Exam workflow state
│   │   └── solver-store.ts      # Problem solver state
│   ├── hooks/                   # Custom React hooks
│   ├── i18n/                    # i18next configuration
│   ├── camera-utils.ts          # Camera utilities
│   ├── pdf-generator.ts         # PDF generation
│   ├── s3-upload.ts             # S3 upload utility
│   └── utils.ts                 # General utilities
├── types/                       # TypeScript definitions
│   ├── question.ts              # Question type definitions
│   ├── api.ts                   # API response types
│   └── index.ts                 # Type exports
├── locales/                     # i18n translations
│   ├── en/                      # English
│   └── zh-TW/                   # Traditional Chinese
├── styles/
│   └── globals.css              # Global styles + Tailwind
├── prisma/                      # Prisma ORM
│   └── schema.prisma            # Database schema
└── public/                      # Static assets
    └── manifest.json            # PWA manifest
```

---

Rules:
- app/ is routing + composition only
- components/ui contains PURE presentational components (shadcn/ui)
- components/ subdirectories contain domain-specific components
- lib/stores/ contains Zustand stores for state management
- lib/api.ts is the single API client for backend communication
- types/question.ts is the single source of truth for Question type
- locales/ contains i18n translation files
- prisma/ contains database schema (types only, backend handles DB)

---

## 3. Client / Server Architecture（Next.js）

---

### 3.1 Server Responsibilities

Server Components / API Routes must handle:
- Data fetching
- Authentication
- Authorization
- Heavy computation
- Secure logic

Server code must NOT:
- Contain UI-specific state
- Depend on browser APIs

---

### 3.2 Client Responsibilities

Client Components handle:
- Interaction
- Local UI state
- Animation
- 3D rendering (Three.js / WebGL)

Client components must:
- Be explicitly marked with "use client"
- Remain as thin as possible
- Consume already-shaped data

---

### 3.3 Boundary Rules

- Server → Client: pass serialized data only
- Client must NOT call server logic directly
- API contracts must be typed

---

## 4. Component Layering（最重要）

---

### 4.1 UI Components（components/ui）

Purpose:
- Visual representation only

Rules:
- Accept props only
- No fetch
- No hooks (except trivial ones like useId)
- No domain assumptions

Example:
---
interface ButtonProps {
  variant: "primary" | "secondary"
  disabled?: boolean
  onClick: () => void
}

function Button(props: ButtonProps) {
  ...
}
---

---

### 4.2 Domain Components（components/domain）

Purpose:
- Bridge domain logic and UI

Rules:
- May use hooks
- May compose multiple UI components
- Must translate domain data → UI props
- No direct routing

---

### 4.3 Container / Page Components

Purpose:
- Orchestration only

Rules:
- Fetch data (server-side preferred)
- Pass data downward
- No styling details
- No business logic leakage

---

## 5. Design Page（設計中樞，必須存在）

---

### 5.1 Design Page Purpose

The Design Page is a **single source of truth** for:
- Component inventory
- Design tokens
- Tailwind configuration
- shadcn component variants
- Visual themes
- Motion / interaction style

This page MUST exist.

---

### 5.2 Design Page Content

/design/page.tsx must display:
- All UI components
- All variants
- Color palette matrix
- Spacing scale
- Typography scale
- Border radius system
- Shadow system
- Motion tokens
- 3D asset previews (if applicable)

---

### 5.3 Design First Rule

Before implementing any new feature:
- Agent MUST verify design exists in Design Page
- If not, design must be added first

Implementation without design reference is forbidden.

---

## 6. Tailwind Usage Rules（設計決策系統）

---

- Tailwind tokens represent **design decisions**
- Arbitrary values are forbidden unless approved
- Use semantic classes via config
- Spacing, color, radius must come from config

Tailwind is NOT:
- A styling playground
- A per-component customization tool

---

## 7. shadcn/ui Usage Rules（Component Blueprint）

---

shadcn components are:
- Copied into the repo
- Owned by the project
- Allowed to be modified

Rules:
- Do NOT treat shadcn as an external library
- All shadcn components live in components/ui
- Variants must be documented in Design Page
- Styling changes must be global-consistent

---

## 8. TypeScript as Architecture Constraint

---

### 8.1 Typing Rules

- No implicit any
- No untyped props
- No untyped API response
- No casting to silence errors

---

### 8.2 State Typing（強制）

All non-trivial state must use union types.

Example:
---
type LoadState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: Item[] }
  | { status: "error"; message: string }
---

Invalid states must be impossible.

---

### 8.3 API Contracts

All API responses must be typed.

Services return typed promises.

---

## 9. Hooks & Lifecycle Rules

---

### 9.1 useEffect Rules

useEffect is ONLY for:
- Side effects
- Subscriptions
- Sync with external systems

useEffect is NOT:
- A data pipeline
- A rendering tool

---

### 9.2 Dependency Discipline

- Dependency arrays must be explicit
- Missing dependencies are forbidden
- Suppressing lint warnings is forbidden

---

### 9.3 Custom Hooks

Custom hooks must:
- Encapsulate one responsibility
- Expose typed API
- Never return raw fetch responses

---

## 10. Database Layer（Prisma 資料庫架構）

---

### 10.1 Prisma as Single Source of Truth

Prisma serves as the **type-safe database layer** for the application.

Architecture:
```
[Client] → [API Routes / Server Actions] → [Services] → [Prisma Client] → [Database]
```

Rules:
- Prisma Client is the ONLY way to access the database
- All database operations MUST go through the services layer
- Direct Prisma calls in components are forbidden
- Schema changes require migrations

---

### 10.2 Prisma Directory Structure

```
prisma/
  schema.prisma      # Database schema definition
  migrations/        # Version-controlled migrations
  seed.ts            # Seed data for development
```

---

### 10.3 Schema Design Rules

Schema must follow:
- Explicit relations with @relation directive
- Required fields over optional when possible
- Enum types for finite value sets
- Proper indexing for query optimization
- Soft delete pattern when needed (deletedAt field)

Example:
```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  role      Role     @default(USER)
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

enum Role {
  USER
  ADMIN
}
```

---

### 10.4 Prisma Client Singleton

Prisma Client MUST be instantiated as a singleton.

Location: `lib/prisma.ts`

```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma
}
```

Rules:
- Import from `lib/prisma` only
- Never instantiate PrismaClient elsewhere
- This prevents connection pool exhaustion in development

---

### 10.5 Services Layer Integration

Services encapsulate all Prisma operations.

Structure:
```
services/
  user.service.ts
  post.service.ts
  ...
```

Example:
```typescript
// services/user.service.ts
import { prisma } from '@/lib/prisma'
import type { User, Prisma } from '@prisma/client'

export const userService = {
  async findById(id: string): Promise<User | null> {
    return prisma.user.findUnique({ where: { id } })
  },

  async create(data: Prisma.UserCreateInput): Promise<User> {
    return prisma.user.create({ data })
  },

  async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return prisma.user.update({ where: { id }, data })
  },

  async delete(id: string): Promise<User> {
    return prisma.user.delete({ where: { id } })
  }
}
```

Rules:
- Services return Prisma-generated types
- Complex queries are encapsulated in service methods
- No raw SQL unless absolutely necessary
- Transaction logic stays in services

---

### 10.6 Type Integration

Prisma generates types automatically.

Usage in types/:
```typescript
// types/user.ts
import type { User, Post } from '@prisma/client'

// Extend or pick from Prisma types
export type UserWithPosts = User & {
  posts: Post[]
}

export type UserCreateDTO = Pick<User, 'email' | 'name'>
```

Rules:
- Prefer Prisma-generated types over manual definitions
- Use Pick/Omit for DTOs
- Create composite types for relations
- Keep API contracts in sync with schema

---

### 10.7 Server Actions with Prisma

Server Actions are the preferred way to mutate data.

```typescript
// app/actions/user.actions.ts
'use server'

import { userService } from '@/services/user.service'
import { revalidatePath } from 'next/cache'

export async function createUser(formData: FormData) {
  const email = formData.get('email') as string
  const name = formData.get('name') as string

  const user = await userService.create({ email, name })

  revalidatePath('/users')
  return user
}
```

Rules:
- Server Actions call services, not Prisma directly
- Validate input before database operations
- Revalidate affected paths after mutations
- Handle errors at the action boundary

---

### 10.8 API Routes with Prisma

For REST-style endpoints:

```typescript
// app/api/users/route.ts
import { NextResponse } from 'next/server'
import { userService } from '@/services/user.service'

export async function GET() {
  const users = await userService.findAll()
  return NextResponse.json(users)
}

export async function POST(request: Request) {
  const body = await request.json()
  const user = await userService.create(body)
  return NextResponse.json(user, { status: 201 })
}
```

---

### 10.9 Migration Workflow

Migration commands:
```bash
# Create migration after schema change
npx prisma migrate dev --name <migration_name>

# Apply migrations in production
npx prisma migrate deploy

# Reset database (development only)
npx prisma migrate reset

# Generate Prisma Client
npx prisma generate
```

Rules:
- Never edit migration files manually
- Migration names should be descriptive (e.g., `add_user_role_field`)
- Run `prisma generate` after schema changes
- Commit migrations to version control

---

### 10.10 Seeding

Seed file for development data:

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  await prisma.user.createMany({
    data: [
      { email: 'admin@example.com', name: 'Admin', role: 'ADMIN' },
      { email: 'user@example.com', name: 'User', role: 'USER' },
    ],
  })
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(() => prisma.$disconnect())
```

Add to package.json:
```json
{
  "prisma": {
    "seed": "ts-node --compiler-options {\"module\":\"CommonJS\"} prisma/seed.ts"
  }
}
```

---

## 11. API-Heavy & Complex UX Projects

---

### 11.1 API Strategy

- Centralized services layer
- Typed responses (Prisma-generated types preferred)
- Error handling at boundary
- UI receives normalized data

---

### 11.2 Complex UI

For complex UI flows:
- State machine over boolean flags
- Domain logic in hooks
- UI reflects state, not logic

---

### 11.3 3D Assets

3D assets:
- Loaded lazily
- Isolated in client-only components
- Abstracted behind domain components

UI must not depend on raw 3D APIs.

---

## 12. Anti-Patterns（嚴禁）

---

- UI component fetching data
- Inline business logic in JSX
- Boolean explosion (isLoading + isError + ...)
- Styling by guesswork
- Untyped state
- Skipping Design Page
- Direct Prisma calls in components or pages
- Multiple PrismaClient instances
- Raw SQL without justification
- Skipping migrations for schema changes
- Untyped database responses

---

## 13. Agent Operating Rules（總結）

The agent must:
- Design before implementation
- Type before coding
- Structure before optimization
- Consistency over creativity

If a decision violates:
- Data flow
- State model
- Typing constraints
- Design system

The decision is invalid.

---