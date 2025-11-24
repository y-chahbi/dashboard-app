# Dashboard App

A production-ready full-stack dashboard application for managing agencies and contacts with daily view rate limiting.

## Features

- **Authentication**: Clerk-based authentication for all protected routes
- **Agencies Management**: View, search, and paginate agencies
- **Contacts Management**: View, search, and paginate contacts with agency associations
- **Contact View Limiting**: Daily limit of 50 contact views per user
- **Upgrade Page**: Shown when users exceed their daily view limit
- **Responsive Design**: Works on desktop and mobile devices

## Technology Stack

- **Frontend**: Next.js 15 (App Router), React 18, TypeScript
- **Styling**: TailwindCSS
- **Authentication**: Clerk
- **Database**: PostgreSQL with Prisma ORM
- **Containerization**: Docker + docker-compose

## Project Structure

```
project/
├── docker-compose.yml      # Container orchestration
├── Dockerfile              # Multi-stage build for Next.js
├── .env.example            # Environment variables template
├── prisma/
│   └── schema.prisma       # Database models
├── scripts/
│   └── import-data.ts      # Data import script
├── data/
│   ├── agencies.json       # Sample agencies data
│   └── contacts.json       # Sample contacts data
├── src/
│   ├── app/
│   │   ├── page.tsx               # Home page
│   │   ├── layout.tsx             # Root layout with Clerk
│   │   ├── globals.css            # Global styles
│   │   ├── agencies/
│   │   │   └── page.tsx           # Agencies list page
│   │   ├── contacts/
│   │   │   ├── page.tsx           # Contacts list page
│   │   │   └── [id]/
│   │   │       └── page.tsx       # Contact detail page
│   │   ├── upgrade/
│   │   │   └── page.tsx           # Upgrade plan page
│   │   └── api/
│   │       ├── agencies/
│   │       │   └── route.ts       # GET /api/agencies
│   │       ├── contacts/
│   │       │   ├── route.ts       # GET /api/contacts
│   │       │   └── [id]/
│   │       │       └── route.ts   # GET /api/contacts/:id
│   │       └── view-stats/
│   │           └── route.ts       # GET /api/view-stats
│   ├── components/
│   │   ├── navbar.tsx             # Navigation bar
│   │   ├── view-limit-banner.tsx  # Daily view stats banner
│   │   ├── data-table.tsx         # Generic data table
│   │   └── pagination.tsx         # Pagination controls
│   ├── lib/
│   │   ├── prisma.ts              # Prisma singleton
│   │   └── contact-view-limit.ts  # Rate limiting logic
│   └── middleware.ts              # Clerk auth middleware
└── README.md
```

## Getting Started

### Prerequisites

- Node.js 20+
- Docker and docker-compose
- Clerk account (for authentication)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dashboard-app
   ```

2. **Copy environment file**
   ```bash
   cp .env.example .env
   ```

3. **Configure Clerk**
   - Go to [Clerk Dashboard](https://dashboard.clerk.dev)
   - Create a new application
   - Copy the Publishable Key and Secret Key
   - Update `.env` with your Clerk keys:
     ```
     NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
     CLERK_SECRET_KEY=sk_test_...
     ```

4. **Start the database**
   ```bash
   docker-compose up -d postgres
   ```

5. **Install dependencies**
   ```bash
   npm install
   ```

6. **Run database migrations**
   ```bash
   npx prisma migrate dev
   ```

7. **Import sample data**
   ```bash
   npm run import:data
   ```

8. **Start the development server**
   ```bash
   npm run dev
   ```

9. **Access the app**
   Open [http://localhost:3000](http://localhost:3000)

### Docker Production Build

To run the entire stack in Docker:

```bash
docker-compose up -d
```

This starts:
- PostgreSQL database on port 5432
- Next.js application on port 3000

## API Endpoints

### GET /api/agencies
Fetch paginated list of agencies with optional search.

**Query Parameters:**
- `page` (default: 1): Page number
- `limit` (default: 10): Items per page
- `search`: Search term for name, email, or website

**Response:**
```json
{
  "agencies": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 4,
    "totalPages": 1
  }
}
```

### GET /api/contacts
Fetch paginated list of contacts with optional search and agency filter.

**Query Parameters:**
- `page` (default: 1): Page number
- `limit` (default: 10): Items per page
- `search`: Search term for firstName, lastName, email, or position
- `agencyId`: Filter by agency ID

**Response:**
```json
{
  "contacts": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 6,
    "totalPages": 1
  }
}
```

### GET /api/contacts/:id
Fetch single contact details. Increments daily view count.

**Response (200):**
```json
{
  "contact": {
    "id": "...",
    "firstName": "John",
    "lastName": "Smith",
    "email": "john@example.com",
    "agency": {...}
  }
}
```

**Response (429 - Rate Limited):**
```json
{
  "error": "Daily contact view limit reached",
  "limitReached": true
}
```

### GET /api/view-stats
Get current user's daily view statistics.

**Response:**
```json
{
  "used": 10,
  "remaining": 40,
  "limit": 50
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | - |
| `POSTGRES_USER` | Database username | postgres |
| `POSTGRES_PASSWORD` | Database password | postgres |
| `POSTGRES_DB` | Database name | dashboard |
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | Clerk publishable key | - |
| `CLERK_SECRET_KEY` | Clerk secret key | - |
| `NEXT_PUBLIC_CLERK_SIGN_IN_URL` | Sign-in URL | /sign-in |
| `NEXT_PUBLIC_CLERK_SIGN_UP_URL` | Sign-up URL | /sign-up |
| `NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL` | Redirect after sign-in | /agencies |
| `NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL` | Redirect after sign-up | /agencies |
| `DAILY_CONTACT_VIEW_LIMIT` | Max daily contact views | 50 |

## Database Schema

### Agency
- `id`: Unique identifier (CUID)
- `name`: Agency name (unique)
- `email`: Email address
- `phone`: Phone number
- `address`: Physical address
- `website`: Website URL
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Contact
- `id`: Unique identifier (CUID)
- `firstName`: First name
- `lastName`: Last name
- `email`: Email address (unique)
- `phone`: Phone number
- `position`: Job position
- `agencyId`: Foreign key to Agency
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### ContactViewLimit
- `id`: Unique identifier (CUID)
- `userId`: Clerk user ID
- `date`: Date (midnight UTC)
- `count`: View count for the day
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

Unique constraint: (userId, date)

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run linter
- `npm run import:data` - Import sample data from JSON files
- `npm run prisma:generate` - Generate Prisma client
- `npm run prisma:migrate` - Run database migrations
- `npm run prisma:studio` - Open Prisma Studio
- `npm run docker:up` - Start Docker containers
- `npm run docker:down` - Stop Docker containers

## License

MIT