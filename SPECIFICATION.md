# Dashboard Application Specification

This document contains the complete specification and engineering prompt used to build this dashboard application.

---

## Engineering Prompt

You are a senior full-stack engineer.
Your task is to build an end-to-end dashboard application using:

- Next.js 16 (App Router, TypeScript)
- Clerk Authentication
- PostgreSQL + Prisma
- Docker & docker-compose
- TailwindCSS or ShadCN UI
- Vercel Deployment

You must generate production-grade code, folder structure, documentation, and architecture.
Follow best engineering patterns and write code that is complete, clean, and ready to run.

---

## 🎯 PROJECT REQUIREMENTS

### 1. Authentication (Clerk)

- Users must sign in before accessing the dashboard
- Protect all dashboard routes
- Provide Clerk frontend integration + server-side verification

### 2. Agencies Page

- Server-side rendered or client-side table
- Fetch all agencies from PostgreSQL
- Pagination + search
- Columns: agency name, city, address

### 3. Contacts Page

- Paginated and searchable table
- Each contact belongs to an agency
- "View Contact" button → open /contacts/[id]
- Display metadata: name, email, phone, agency

### 4. Daily Contact View Limit — 50/day

Implement rate-limit logic:

- Create table `ContactViewLimit` (userId, date, count)
- When user opens a contact detail page:
  - Increment count
  - If count >= 50 → block access
- Show "Upgrade Plan" modal/page when blocked
- Limit logic must be in API route and referenced by contacts detail fetch.

### 5. Database Schema (Prisma)

Generate models:

- Agency
- Contact
- ContactViewLimit

With relations, indexes, and constraints.

### 6. Data Import Script

Create `scripts/import-data.ts` that will:

- Read CSV/JSON input for agencies
- Read CSV/JSON for contacts
- Normalize mismatched agency names
- Insert data into PostgreSQL via Prisma
- Log duplicates or unmatched rows

### 7. API Endpoints (Next.js Route Handlers)

Create:

- `GET /api/agencies`
- `GET /api/contacts`
- `GET /api/contacts/[id]` (with limit logic)
- `POST /api/track-view` (optional helper)

Responses must be typed and follow clean patterns.

### 8. Docker Requirements

Generate:

- Dockerfile for Next.js (production optimized)
- docker-compose.yml including:
  - next-app service
  - postgres service
  - hot-reload volumes for development
- Add `.env.example`

### 9. Folder Structure

Output:

```
project/
  docker-compose.yml
  Dockerfile
  prisma/
    schema.prisma
  scripts/
    import-data.ts
  src/
    app/
      agencies/
      contacts/
      upgrade/
      api/
    components/
    lib/
  README.md
```

### 10. Documentation

Produce:

- Setup instructions
- How to run Docker environment
- How to migrate Prisma
- How to import data
- How to deploy to Vercel
- Mermaid system diagram

---

## 📣 CODING STYLE

You must follow:

- Clean architecture
- Modular, reusable React components
- Fully typed Prisma client
- Centralized DB utilities
- Error handling and validation
- Comments explaining logic
- Use async/await everywhere

---

## 🧠 INSTRUCTIONS

When asked to "generate", "scaffold", or "write", produce:

- Full file contents
- Required imports
- Routes, components, schemas
- Scripts and configs
- Explanations only when asked

Avoid placeholders unless necessary.

---

## System Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        A[Browser] --> B[Next.js App Router]
    end
    
    subgraph "Authentication"
        B --> C[Clerk Auth]
        C --> D[Middleware Protection]
    end
    
    subgraph "Application Layer"
        D --> E[Pages]
        D --> F[API Routes]
        
        subgraph "Pages"
            E --> G[Home Page]
            E --> H[Agencies Page]
            E --> I[Contacts Page]
            E --> J[Contact Detail Page]
            E --> K[Upgrade Page]
        end
        
        subgraph "API Endpoints"
            F --> L[GET /api/agencies]
            F --> M[GET /api/contacts]
            F --> N[GET /api/contacts/:id]
            F --> O[GET /api/view-stats]
        end
    end
    
    subgraph "Business Logic"
        N --> P[Rate Limit Check]
        P --> Q{Limit Reached?}
        Q -->|Yes| R[429 Error / Redirect to Upgrade]
        Q -->|No| S[Increment Count + Return Contact]
    end
    
    subgraph "Data Layer"
        L --> T[(PostgreSQL)]
        M --> T
        S --> T
        P --> T
        
        subgraph "Prisma Models"
            T --> U[Agency]
            T --> V[Contact]
            T --> W[ContactViewLimit]
        end
    end
    
    subgraph "Infrastructure"
        X[Docker Compose]
        X --> Y[Next.js Container]
        X --> Z[PostgreSQL Container]
    end
```

## Data Flow Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant C as Clerk Auth
    participant M as Middleware
    participant P as Contact Detail Page
    participant API as API Route
    participant DB as PostgreSQL
    
    U->>C: Sign In
    C-->>U: Session Token
    
    U->>M: Access /contacts/123
    M->>C: Verify Token
    C-->>M: User ID
    
    M->>P: Render Page
    P->>API: Check hasReachedDailyLimit(userId)
    API->>DB: Query ContactViewLimit
    DB-->>API: View Count
    
    alt Limit Reached (count >= 50)
        API-->>P: Limit Reached
        P-->>U: Redirect to /upgrade
    else Under Limit
        API->>DB: Fetch Contact
        DB-->>API: Contact Data
        API->>DB: Increment View Count
        API-->>P: Contact + View Stats
        P-->>U: Render Contact Details
    end
```

## Entity Relationship Diagram

```mermaid
erDiagram
    Agency ||--o{ Contact : "has many"
    Agency {
        string id PK
        string name UK
        string email
        string phone
        string address
        string website
        datetime createdAt
        datetime updatedAt
    }
    
    Contact {
        string id PK
        string firstName
        string lastName
        string email UK
        string phone
        string position
        string notes
        string agencyId FK
        datetime createdAt
        datetime updatedAt
    }
    
    ContactViewLimit {
        string id PK
        string userId
        datetime date
        int count
        datetime createdAt
        datetime updatedAt
    }
```

---

## Implementation Status

| Requirement | Status | Location |
|------------|--------|----------|
| Clerk Authentication | ✅ Complete | `src/middleware.ts`, `src/app/layout.tsx` |
| Agencies Page | ✅ Complete | `src/app/agencies/page.tsx` |
| Contacts Page | ✅ Complete | `src/app/contacts/page.tsx` |
| Contact Detail Page | ✅ Complete | `src/app/contacts/[id]/page.tsx` |
| Daily View Limit (50/day) | ✅ Complete | `src/lib/contact-view-limit.ts` |
| Upgrade Page | ✅ Complete | `src/app/upgrade/page.tsx` |
| API: GET /api/agencies | ✅ Complete | `src/app/api/agencies/route.ts` |
| API: GET /api/contacts | ✅ Complete | `src/app/api/contacts/route.ts` |
| API: GET /api/contacts/[id] | ✅ Complete | `src/app/api/contacts/[id]/route.ts` |
| API: GET /api/view-stats | ✅ Complete | `src/app/api/view-stats/route.ts` |
| Prisma Schema | ✅ Complete | `prisma/schema.prisma` |
| Data Import Script | ✅ Complete | `scripts/import-data.ts` |
| Dockerfile | ✅ Complete | `Dockerfile` |
| docker-compose.yml | ✅ Complete | `docker-compose.yml` |
| Environment Config | ✅ Complete | `.env.example` |
| Documentation | ✅ Complete | `README.md` |
