#!/bin/bash

# =============================================================================
# Dashboard App Setup Script
# =============================================================================
# This script creates a complete Next.js dashboard application with:
# - User authentication (Clerk)
# - Agency and Contact management
# - Daily contact view rate limiting (50/day)
# - Upgrade page when limit is exceeded
# - PostgreSQL database with Prisma ORM
# - Docker containerization
#
# Usage: ./setup.sh [directory_name]
# If no directory is provided, creates files in current directory
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Target directory
TARGET_DIR="${1:-.}"

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}                    Dashboard App Project Setup                              ${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""

# Create target directory if specified
if [ "$TARGET_DIR" != "." ]; then
    echo -e "${YELLOW}Creating project directory: ${TARGET_DIR}${NC}"
    mkdir -p "$TARGET_DIR"
fi

cd "$TARGET_DIR"

echo -e "${GREEN}Setting up project in: $(pwd)${NC}"
echo ""

# =============================================================================
# Create Directory Structure
# =============================================================================
echo -e "${YELLOW}Creating directory structure...${NC}"

mkdir -p data
mkdir -p prisma
mkdir -p scripts
mkdir -p src/app/agencies
mkdir -p 'src/app/contacts/[id]'
mkdir -p src/app/upgrade
mkdir -p src/app/api/agencies
mkdir -p 'src/app/api/contacts/[id]'
mkdir -p src/app/api/view-stats
mkdir -p src/components
mkdir -p src/lib

echo -e "${GREEN}✓ Directory structure created${NC}"

# =============================================================================
# Create package.json
# =============================================================================
echo -e "${YELLOW}Creating package.json...${NC}"

cat > package.json << 'PACKAGEJSONEOF'
{
  "name": "dashboard-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "prisma generate && next build",
    "start": "next start",
    "lint": "next lint",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:studio": "prisma studio",
    "import:data": "tsx scripts/import-data.ts",
    "docker:up": "docker-compose up -d",
    "docker:down": "docker-compose down"
  },
  "dependencies": {
    "@clerk/nextjs": "^5.0.0",
    "@prisma/client": "^5.9.0",
    "lucide-react": "^0.344.0",
    "next": "^15.0.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.4.17",
    "csv-parse": "^5.5.3",
    "eslint": "9.39.1",
    "eslint-config-next": "16.0.4",
    "postcss": "^8.4.35",
    "prisma": "^5.9.0",
    "tailwindcss": "^3.4.1",
    "tsx": "^4.7.1",
    "typescript": "^5"
  }
}
PACKAGEJSONEOF

echo -e "${GREEN}✓ package.json created${NC}"

# =============================================================================
# Create TypeScript Configuration
# =============================================================================
echo -e "${YELLOW}Creating tsconfig.json...${NC}"

cat > tsconfig.json << 'TSCONFIGEOF'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TSCONFIGEOF

echo -e "${GREEN}✓ tsconfig.json created${NC}"

# =============================================================================
# Create Next.js Configuration
# =============================================================================
echo -e "${YELLOW}Creating next.config.js...${NC}"

cat > next.config.js << 'NEXTCONFIGEOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  eslint: {
    // Warning: ESLint 9 has configuration issues with Next.js 15
    // Disable during builds until compatibility is fixed
    ignoreDuringBuilds: true,
  },
};

module.exports = nextConfig;
NEXTCONFIGEOF

echo -e "${GREEN}✓ next.config.js created${NC}"

# =============================================================================
# Create Tailwind Configuration
# =============================================================================
echo -e "${YELLOW}Creating tailwind.config.ts...${NC}"

cat > tailwind.config.ts << 'TAILWINDEOF'
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
export default config
TAILWINDEOF

echo -e "${GREEN}✓ tailwind.config.ts created${NC}"

# =============================================================================
# Create PostCSS Configuration
# =============================================================================
echo -e "${YELLOW}Creating postcss.config.js...${NC}"

cat > postcss.config.js << 'POSTCSSEOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
POSTCSSEOF

echo -e "${GREEN}✓ postcss.config.js created${NC}"

# =============================================================================
# Create ESLint Configuration
# =============================================================================
echo -e "${YELLOW}Creating .eslintrc.json...${NC}"

cat > .eslintrc.json << 'ESLINTEOF'
{
  "extends": "next/core-web-vitals"
}
ESLINTEOF

echo -e "${GREEN}✓ .eslintrc.json created${NC}"

# =============================================================================
# Create .gitignore
# =============================================================================
echo -e "${YELLOW}Creating .gitignore...${NC}"

cat > .gitignore << 'GITIGNOREEOF'
# See https://help.github.com/articles/ignoring-files/ for more about ignoring files.

# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local
.env

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts

# prisma
node_modules/.prisma/
GITIGNOREEOF

echo -e "${GREEN}✓ .gitignore created${NC}"

# =============================================================================
# Create Environment Example File
# =============================================================================
echo -e "${YELLOW}Creating .env.example...${NC}"

cat > .env.example << 'ENVEXAMPLEEOF'
# Database
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/dashboard?schema=public"
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=dashboard

# Clerk Authentication
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_key_here
CLERK_SECRET_KEY=sk_test_your_key_here
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/agencies
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/agencies

# App Configuration
DAILY_CONTACT_VIEW_LIMIT=50
ENVEXAMPLEEOF

echo -e "${GREEN}✓ .env.example created${NC}"

# =============================================================================
# Create Docker Configuration
# =============================================================================
echo -e "${YELLOW}Creating docker-compose.yml...${NC}"

cat > docker-compose.yml << 'DOCKERCOMPOSEEOF'
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: dashboard-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-dashboard}
    ports:
      - '5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: dashboard-app
    restart: unless-stopped
    ports:
      - '3000:3000'
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY}
      - CLERK_SECRET_KEY=${CLERK_SECRET_KEY}
      - NODE_ENV=production
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - .:/app
      - /app/node_modules
      - /app/.next

volumes:
  postgres_data:
DOCKERCOMPOSEEOF

echo -e "${GREEN}✓ docker-compose.yml created${NC}"

# =============================================================================
# Create Dockerfile
# =============================================================================
echo -e "${YELLOW}Creating Dockerfile...${NC}"

cat > Dockerfile << 'DOCKERFILEEOF'
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build Next.js application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
DOCKERFILEEOF

echo -e "${GREEN}✓ Dockerfile created${NC}"

# =============================================================================
# Create Prisma Schema
# =============================================================================
echo -e "${YELLOW}Creating prisma/schema.prisma...${NC}"

cat > prisma/schema.prisma << 'PRISMAEOF'
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Agency {
  id          String    @id @default(cuid())
  name        String    @unique
  email       String?
  phone       String?
  address     String?
  website     String?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  contacts    Contact[]

  @@index([name])
}

model Contact {
  id          String    @id @default(cuid())
  firstName   String
  lastName    String
  email       String    @unique
  phone       String?
  position    String?
  notes       String?
  agencyId    String
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  agency      Agency    @relation(fields: [agencyId], references: [id], onDelete: Cascade)

  @@index([agencyId])
  @@index([email])
  @@index([lastName])
}

model ContactViewLimit {
  id        String   @id @default(cuid())
  userId    String
  date      DateTime @default(now())
  count     Int      @default(0)
  createdAt DateTime @default(now())
  updatedAt DateTime @default(now())

  @@unique([userId, date])
  @@index([userId, date])
}
PRISMAEOF

echo -e "${GREEN}✓ prisma/schema.prisma created${NC}"

# =============================================================================
# Create Sample Data Files
# =============================================================================
echo -e "${YELLOW}Creating data/agencies.json...${NC}"

cat > data/agencies.json << 'AGENCIESDATAEOF'
[
  {
    "name": "Acme Digital Agency",
    "email": "info@acmedigital.com",
    "phone": "+1 (555) 123-4567",
    "address": "123 Tech Boulevard, San Francisco, CA 94105",
    "website": "https://www.acmedigital.com"
  },
  {
    "name": "Global Marketing Solutions",
    "email": "contact@globalmarketing.com",
    "phone": "+1 (555) 234-5678",
    "address": "456 Madison Avenue, New York, NY 10022",
    "website": "https://www.globalmarketing.com"
  },
  {
    "name": "Creative Studios Inc.",
    "email": "hello@creativestudios.com",
    "phone": "+1 (555) 345-6789",
    "address": "789 Design Street, Los Angeles, CA 90028",
    "website": "https://www.creativestudios.com"
  },
  {
    "name": "Tech Innovators LLC",
    "email": "support@techinnovators.com",
    "phone": "+1 (555) 456-7890",
    "address": "321 Innovation Way, Austin, TX 78701",
    "website": "https://www.techinnovators.com"
  }
]
AGENCIESDATAEOF

echo -e "${GREEN}✓ data/agencies.json created${NC}"

echo -e "${YELLOW}Creating data/contacts.json...${NC}"

cat > data/contacts.json << 'CONTACTSDATAEOF'
[
  {
    "firstName": "John",
    "lastName": "Smith",
    "email": "john.smith@acmedigital.com",
    "phone": "+1 (555) 111-2222",
    "position": "Senior Developer",
    "agencyName": "Acme Digital Agency"
  },
  {
    "firstName": "Sarah",
    "lastName": "Johnson",
    "email": "sarah.j@acmedigital.com",
    "phone": "+1 (555) 111-3333",
    "position": "Project Manager",
    "agencyName": "acme digital agency"
  },
  {
    "firstName": "Michael",
    "lastName": "Brown",
    "email": "m.brown@globalmarketing.com",
    "phone": "+1 (555) 222-4444",
    "position": "Marketing Director",
    "agencyName": "Global Marketing Solutions"
  },
  {
    "firstName": "Emily",
    "lastName": "Davis",
    "email": "emily.davis@creativestudios.com",
    "phone": "+1 (555) 333-5555",
    "position": "Art Director",
    "agencyName": "Creative Studios Inc."
  },
  {
    "firstName": "David",
    "lastName": "Wilson",
    "email": "d.wilson@techinnovators.com",
    "phone": "+1 (555) 444-6666",
    "position": "CTO",
    "agencyName": "TECH INNOVATORS LLC"
  },
  {
    "firstName": "Jennifer",
    "lastName": "Martinez",
    "email": "jennifer.m@globalmarketing.com",
    "phone": "+1 (555) 222-7777",
    "position": "Account Executive",
    "agencyName": "Global Marketing Solutions"
  }
]
CONTACTSDATAEOF

echo -e "${GREEN}✓ data/contacts.json created${NC}"

# =============================================================================
# Create Source Files - Part 1: Library Files
# =============================================================================

echo -e "${YELLOW}Creating src/lib/prisma.ts...${NC}"

cat > src/lib/prisma.ts << 'PRISMATSEOF'
import { PrismaClient } from '@prisma/client';

/**
 * Prisma Client Singleton
 * Prevents multiple instances in development due to hot reloading
 */
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
PRISMATSEOF

echo -e "${GREEN}✓ src/lib/prisma.ts created${NC}"

echo -e "${YELLOW}Creating src/lib/contact-view-limit.ts...${NC}"

cat > src/lib/contact-view-limit.ts << 'CONTACTVIEWLIMITSEOF'
import { prisma } from './prisma';

/**
 * Daily contact view limit configuration
 * Default: 50 views per user per day
 */
const DAILY_LIMIT = parseInt(process.env.DAILY_CONTACT_VIEW_LIMIT || '50', 10);

/**
 * Get the start of today (midnight) in UTC
 */
function getStartOfToday(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

/**
 * Get or create the view limit record for a user for today
 * Uses upsert to handle race conditions safely
 */
async function getOrCreateViewLimit(userId: string) {
  const today = getStartOfToday();
  
  // Use upsert to handle race conditions - multiple requests
  // trying to create the same record simultaneously
  const viewLimit = await prisma.contactViewLimit.upsert({
    where: {
      userId_date: {
        userId,
        date: today,
      },
    },
    update: {},  // No update needed, just return existing
    create: {
      userId,
      date: today,
      count: 0,
    },
  });
  
  return viewLimit;
}

/**
 * Check if a user has reached their daily contact view limit
 * @param userId - The Clerk user ID
 * @returns true if limit reached, false otherwise
 */
export async function hasReachedDailyLimit(userId: string): Promise<boolean> {
  const viewLimit = await getOrCreateViewLimit(userId);
  return viewLimit.count >= DAILY_LIMIT;
}

/**
 * Increment the view count for a user
 * @param userId - The Clerk user ID
 */
export async function incrementViewCount(userId: string): Promise<void> {
  const today = getStartOfToday();
  
  await prisma.contactViewLimit.upsert({
    where: {
      userId_date: {
        userId,
        date: today,
      },
    },
    update: {
      count: { increment: 1 },
      updatedAt: new Date(),
    },
    create: {
      userId,
      date: today,
      count: 1,
    },
  });
}

/**
 * Get the current view statistics for a user
 * @param userId - The Clerk user ID
 * @returns View statistics object with used, remaining, and limit
 */
export async function getViewStats(userId: string): Promise<{
  used: number;
  remaining: number;
  limit: number;
}> {
  const viewLimit = await getOrCreateViewLimit(userId);
  const used = viewLimit.count;
  const remaining = Math.max(0, DAILY_LIMIT - used);
  
  return {
    used,
    remaining,
    limit: DAILY_LIMIT,
  };
}

/**
 * Get the daily limit value
 * @returns The daily contact view limit
 */
export function getDailyLimit(): number {
  return DAILY_LIMIT;
}
CONTACTVIEWLIMITSEOF

echo -e "${GREEN}✓ src/lib/contact-view-limit.ts created${NC}"

# =============================================================================
# Create Middleware
# =============================================================================
echo -e "${YELLOW}Creating src/middleware.ts...${NC}"

cat > src/middleware.ts << 'MIDDLEWARETSEOF'
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';

const isPublicRoute = createRouteMatcher(['/sign-in(.*)', '/sign-up(.*)']);

export default clerkMiddleware((auth, request) => {
  if (!isPublicRoute(request)) {
    auth().protect();
  }
});

export const config = {
  matcher: [
    // Skip Next.js internals and all static files
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    // Always run for API routes
    '/(api|trpc)(.*)',
  ],
};
MIDDLEWARETSEOF

echo -e "${GREEN}✓ src/middleware.ts created${NC}"

# =============================================================================
# Create Global CSS
# =============================================================================
echo -e "${YELLOW}Creating src/app/globals.css...${NC}"

cat > src/app/globals.css << 'GLOBALSCSSEOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
GLOBALSCSSEOF

echo -e "${GREEN}✓ src/app/globals.css created${NC}"

# =============================================================================
# Create Root Layout
# =============================================================================
echo -e "${YELLOW}Creating src/app/layout.tsx...${NC}"

cat > src/app/layout.tsx << 'LAYOUTTSXEOF'
import type { Metadata } from 'next';
import { ClerkProvider } from '@clerk/nextjs';
import { Navbar } from '@/components/navbar';
import './globals.css';

export const metadata: Metadata = {
  title: 'Dashboard App',
  description: 'Agency and Contact Management Dashboard',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className="min-h-screen bg-gray-50">
          <Navbar />
          <main>{children}</main>
        </body>
      </html>
    </ClerkProvider>
  );
}
LAYOUTTSXEOF

echo -e "${GREEN}✓ src/app/layout.tsx created${NC}"

# =============================================================================
# Create Home Page
# =============================================================================
echo -e "${YELLOW}Creating src/app/page.tsx...${NC}"

cat > src/app/page.tsx << 'HOMEPAGETSXEOF'
import { auth } from '@clerk/nextjs/server';
import Link from 'next/link';
import { Building2, Users, ArrowRight } from 'lucide-react';

/**
 * Home page - Landing page with navigation to main features
 */
export default async function HomePage() {
  const { userId } = await auth();

  return (
    <div className="container mx-auto px-4 py-16">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 sm:text-5xl">
          Welcome to Dashboard
        </h1>
        <p className="mt-4 text-lg text-gray-600">
          Manage your agencies and contacts in one place
        </p>

        {userId ? (
          <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:max-w-3xl lg:mx-auto">
            {/* Agencies Card */}
            <Link
              href="/agencies"
              className="group rounded-lg border bg-white p-6 shadow-sm transition hover:border-blue-500 hover:shadow-md"
            >
              <div className="flex items-center gap-4">
                <div className="rounded-lg bg-blue-100 p-3">
                  <Building2 className="h-6 w-6 text-blue-600" />
                </div>
                <div className="text-left">
                  <h2 className="text-xl font-semibold text-gray-900">Agencies</h2>
                  <p className="text-sm text-gray-600">View and manage agencies</p>
                </div>
                <ArrowRight className="ml-auto h-5 w-5 text-gray-400 transition group-hover:text-blue-500" />
              </div>
            </Link>

            {/* Contacts Card */}
            <Link
              href="/contacts"
              className="group rounded-lg border bg-white p-6 shadow-sm transition hover:border-blue-500 hover:shadow-md"
            >
              <div className="flex items-center gap-4">
                <div className="rounded-lg bg-green-100 p-3">
                  <Users className="h-6 w-6 text-green-600" />
                </div>
                <div className="text-left">
                  <h2 className="text-xl font-semibold text-gray-900">Contacts</h2>
                  <p className="text-sm text-gray-600">View and manage contacts</p>
                </div>
                <ArrowRight className="ml-auto h-5 w-5 text-gray-400 transition group-hover:text-blue-500" />
              </div>
            </Link>
          </div>
        ) : (
          <div className="mt-12">
            <p className="mb-6 text-gray-600">
              Sign in to access your dashboard
            </p>
            <Link
              href="/sign-in"
              className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-6 py-3 font-medium text-white hover:bg-blue-700"
            >
              Get Started
              <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
HOMEPAGETSXEOF

echo -e "${GREEN}✓ src/app/page.tsx created${NC}"

echo -e "${YELLOW}Script Part 1 complete. Continuing with source files...${NC}"

# =============================================================================
# Create Components - Navbar
# =============================================================================
echo -e "${YELLOW}Creating src/components/navbar.tsx...${NC}"

cat > src/components/navbar.tsx << 'NAVBARTSXEOF'
'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { UserButton, SignedIn, SignedOut, SignInButton } from '@clerk/nextjs';
import { Building2, Users, Home } from 'lucide-react';

/**
 * Navigation bar component with authentication status
 */
export function Navbar() {
  const pathname = usePathname();

  // Helper to check if a path is active
  const isActive = (path: string) => pathname?.startsWith(path);

  return (
    <nav className="border-b bg-white">
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          {/* Logo/Brand */}
          <Link href="/" className="flex items-center gap-2 font-semibold">
            <Home className="h-6 w-6 text-blue-600" />
            <span className="text-xl">Dashboard</span>
          </Link>

          {/* Navigation Links */}
          <div className="flex items-center gap-6">
            <SignedIn>
              <Link
                href="/agencies"
                className={`flex items-center gap-2 text-sm font-medium transition-colors ${
                  isActive('/agencies')
                    ? 'text-blue-600'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                <Building2 className="h-4 w-4" />
                Agencies
              </Link>
              <Link
                href="/contacts"
                className={`flex items-center gap-2 text-sm font-medium transition-colors ${
                  isActive('/contacts')
                    ? 'text-blue-600'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                <Users className="h-4 w-4" />
                Contacts
              </Link>
            </SignedIn>
          </div>

          {/* Auth Section */}
          <div className="flex items-center gap-4">
            <SignedIn>
              <UserButton afterSignOutUrl="/" />
            </SignedIn>
            <SignedOut>
              <SignInButton mode="modal">
                <button className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">
                  Sign In
                </button>
              </SignInButton>
            </SignedOut>
          </div>
        </div>
      </div>
    </nav>
  );
}
NAVBARTSXEOF

echo -e "${GREEN}✓ src/components/navbar.tsx created${NC}"

# =============================================================================
# Create Components - Pagination
# =============================================================================
echo -e "${YELLOW}Creating src/components/pagination.tsx...${NC}"

cat > src/components/pagination.tsx << 'PAGINATIONTSXEOF'
import Link from 'next/link';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  baseUrl: string;
}

/**
 * Pagination component with Previous/Next buttons and page numbers
 * Shows max 5 pages with ellipsis for hidden pages
 */
export function Pagination({ currentPage, totalPages, baseUrl }: PaginationProps) {
  // Generate page numbers to display
  const getPageNumbers = (): (number | string)[] => {
    const pages: (number | string)[] = [];
    const maxVisible = 5;

    if (totalPages <= maxVisible) {
      // Show all pages if total is less than max visible
      for (let i = 1; i <= totalPages; i++) {
        pages.push(i);
      }
    } else {
      // Always show first page
      pages.push(1);

      if (currentPage > 3) {
        pages.push('...');
      }

      // Show pages around current page
      const start = Math.max(2, currentPage - 1);
      const end = Math.min(totalPages - 1, currentPage + 1);

      for (let i = start; i <= end; i++) {
        pages.push(i);
      }

      if (currentPage < totalPages - 2) {
        pages.push('...');
      }

      // Always show last page
      pages.push(totalPages);
    }

    return pages;
  };

  const pageNumbers = getPageNumbers();

  // Build URL with page parameter
  const buildUrl = (page: number) => {
    const separator = baseUrl.includes('?') ? '&' : '?';
    return `${baseUrl}${separator}page=${page}`;
  };

  return (
    <nav className="flex items-center gap-1" aria-label="Pagination">
      {/* Previous Button */}
      {currentPage > 1 ? (
        <Link
          href={buildUrl(currentPage - 1)}
          className="flex items-center gap-1 rounded-lg border px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          <ChevronLeft className="h-4 w-4" />
          Previous
        </Link>
      ) : (
        <span className="flex cursor-not-allowed items-center gap-1 rounded-lg border px-3 py-2 text-sm font-medium text-gray-400">
          <ChevronLeft className="h-4 w-4" />
          Previous
        </span>
      )}

      {/* Page Numbers */}
      <div className="hidden items-center gap-1 sm:flex">
        {pageNumbers.map((page, index) =>
          typeof page === 'string' ? (
            <span
              key={`ellipsis-${index}`}
              className="px-3 py-2 text-sm text-gray-500"
            >
              {page}
            </span>
          ) : (
            <Link
              key={page}
              href={buildUrl(page)}
              className={`rounded-lg px-3 py-2 text-sm font-medium ${
                page === currentPage
                  ? 'bg-blue-600 text-white'
                  : 'border text-gray-700 hover:bg-gray-50'
              }`}
            >
              {page}
            </Link>
          )
        )}
      </div>

      {/* Mobile page indicator */}
      <span className="px-3 py-2 text-sm text-gray-600 sm:hidden">
        Page {currentPage} of {totalPages}
      </span>

      {/* Next Button */}
      {currentPage < totalPages ? (
        <Link
          href={buildUrl(currentPage + 1)}
          className="flex items-center gap-1 rounded-lg border px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Next
          <ChevronRight className="h-4 w-4" />
        </Link>
      ) : (
        <span className="flex cursor-not-allowed items-center gap-1 rounded-lg border px-3 py-2 text-sm font-medium text-gray-400">
          Next
          <ChevronRight className="h-4 w-4" />
        </span>
      )}
    </nav>
  );
}
PAGINATIONTSXEOF

echo -e "${GREEN}✓ src/components/pagination.tsx created${NC}"

# =============================================================================
# Create Components - View Limit Banner
# =============================================================================
echo -e "${YELLOW}Creating src/components/view-limit-banner.tsx...${NC}"

cat > src/components/view-limit-banner.tsx << 'VIEWLIMITBANNEREOF'
'use client';

import { useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';

interface ViewStats {
  remaining: number;
  limit: number;
  used: number;
}

export function ViewLimitBanner() {
  const [stats, setStats] = useState<ViewStats | null>(null);

  useEffect(() => {
    fetch('/api/view-stats')
      .then((res) => res.json())
      .then((data) => setStats(data))
      .catch((err) => console.error('Failed to fetch view stats:', err));
  }, []);

  if (!stats) return null;

  const percentage = (stats.used / stats.limit) * 100;
  const isWarning = percentage >= 80;
  const isCritical = percentage >= 95;

  return (
    <div
      className={`rounded-lg border p-4 ${
        isCritical
          ? 'border-red-200 bg-red-50'
          : isWarning
          ? 'border-yellow-200 bg-yellow-50'
          : 'border-blue-200 bg-blue-50'
      }`}
    >
      <div className="flex items-center gap-3">
        <AlertCircle
          className={`h-5 w-5 ${
            isCritical
              ? 'text-red-600'
              : isWarning
              ? 'text-yellow-600'
              : 'text-blue-600'
          }`}
        />
        <div className="flex-1">
          <p
            className={`text-sm font-medium ${
              isCritical
                ? 'text-red-900'
                : isWarning
                ? 'text-yellow-900'
                : 'text-blue-900'
            }`}
          >
            Daily Contact Views: {stats.remaining} remaining of {stats.limit}
          </p>
          <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-gray-200">
            <div
              className={`h-full transition-all ${
                isCritical
                  ? 'bg-red-600'
                  : isWarning
                  ? 'bg-yellow-600'
                  : 'bg-blue-600'
              }`}
              style={{ width: `${percentage}%` }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
VIEWLIMITBANNEREOF

echo -e "${GREEN}✓ src/components/view-limit-banner.tsx created${NC}"

# =============================================================================
# Create Components - Data Table
# =============================================================================
echo -e "${YELLOW}Creating src/components/data-table.tsx...${NC}"

cat > src/components/data-table.tsx << 'DATATABLETSXEOF'
'use client';

import { ReactNode } from 'react';
import { Search, Loader2 } from 'lucide-react';

/**
 * Column definition for the data table
 */
export interface Column<T> {
  header: string;
  accessor: keyof T | ((row: T) => ReactNode);
  className?: string;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  keyExtractor: (row: T) => string;
  isLoading?: boolean;
  searchValue?: string;
  onSearchChange?: (value: string) => void;
  searchPlaceholder?: string;
  emptyMessage?: string;
}

/**
 * Generic data table component with TypeScript generics
 * Supports search bar, loading state, empty state, and custom column rendering
 */
export function DataTable<T>({
  columns,
  data,
  keyExtractor,
  isLoading = false,
  searchValue,
  onSearchChange,
  searchPlaceholder = 'Search...',
  emptyMessage = 'No data found.',
}: DataTableProps<T>) {
  // Render cell content based on accessor type
  const renderCell = (row: T, accessor: Column<T>['accessor']): ReactNode => {
    if (typeof accessor === 'function') {
      return accessor(row);
    }
    const value = row[accessor];
    if (value === null || value === undefined) {
      return '—';
    }
    return String(value);
  };

  return (
    <div className="space-y-4">
      {/* Search Bar */}
      {onSearchChange && (
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            value={searchValue || ''}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder={searchPlaceholder}
            className="w-full rounded-lg border py-2 pl-10 pr-4 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>
      )}

      {/* Table */}
      <div className="overflow-x-auto rounded-lg border bg-white">
        <table className="w-full">
          <thead className="border-b bg-gray-50">
            <tr>
              {columns.map((column, index) => (
                <th
                  key={index}
                  className={`px-6 py-3 text-left text-sm font-medium text-gray-900 ${
                    column.className || ''
                  }`}
                >
                  {column.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y">
            {isLoading ? (
              <tr>
                <td
                  colSpan={columns.length}
                  className="px-6 py-12 text-center"
                >
                  <div className="flex items-center justify-center gap-2 text-gray-500">
                    <Loader2 className="h-5 w-5 animate-spin" />
                    Loading...
                  </div>
                </td>
              </tr>
            ) : data.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length}
                  className="px-6 py-12 text-center text-gray-500"
                >
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              data.map((row) => (
                <tr key={keyExtractor(row)} className="hover:bg-gray-50">
                  {columns.map((column, index) => (
                    <td
                      key={index}
                      className={`px-6 py-4 text-sm text-gray-600 ${
                        column.className || ''
                      }`}
                    >
                      {renderCell(row, column.accessor)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
DATATABLETSXEOF

echo -e "${GREEN}✓ src/components/data-table.tsx created${NC}"

# =============================================================================
# Create Agencies Page
# =============================================================================
echo -e "${YELLOW}Creating src/app/agencies/page.tsx...${NC}"

cat > src/app/agencies/page.tsx << 'AGENCIESPAGETSXEOF'
import { auth } from '@clerk/nextjs/server';
import { redirect } from 'next/navigation';
import { prisma } from '@/lib/prisma';
import Link from 'next/link';
import { Pagination } from '@/components/pagination';

/**
 * Agencies listing page with search and pagination
 */
export default async function AgenciesPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const { userId } = await auth();
  if (!userId) redirect('/sign-in');

  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';
  const limit = 10;
  const skip = (page - 1) * limit;

  // Build search query
  const where = search
    ? {
        OR: [
          { name: { contains: search, mode: 'insensitive' as const } },
          { email: { contains: search, mode: 'insensitive' as const } },
          { website: { contains: search, mode: 'insensitive' as const } },
        ],
      }
    : {};

  // Fetch agencies with contact count
  const [agencies, total] = await Promise.all([
    prisma.agency.findMany({
      where,
      skip,
      take: limit,
      orderBy: { name: 'asc' },
      include: {
        _count: {
          select: { contacts: true },
        },
      },
    }),
    prisma.agency.count({ where }),
  ]);

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Agencies</h1>
        <p className="text-gray-600">Manage and view all agencies</p>
      </div>

      {/* Search Form */}
      <form method="GET" className="mb-6">
        <div className="flex gap-2">
          <input
            type="text"
            name="search"
            placeholder="Search by name, email, or website..."
            defaultValue={search}
            className="w-full max-w-md rounded-lg border px-4 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
          <button
            type="submit"
            className="rounded-lg bg-blue-600 px-6 py-2 text-white hover:bg-blue-700"
          >
            Search
          </button>
        </div>
      </form>

      {/* Agencies Table */}
      <div className="overflow-x-auto rounded-lg border bg-white">
        <table className="w-full">
          <thead className="border-b bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                Name
              </th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                Email
              </th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                Phone
              </th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                Website
              </th>
              <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                Contacts
              </th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {agencies.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                  {search ? 'No agencies found matching your search.' : 'No agencies found.'}
                </td>
              </tr>
            ) : (
              agencies.map((agency) => (
                <tr key={agency.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">
                    {agency.name}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {agency.email || '—'}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {agency.phone || '—'}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {agency.website ? (
                      <a
                        href={agency.website}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-600 hover:underline"
                      >
                        {agency.website}
                      </a>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    <Link
                      href={'/contacts?agencyId=' + agency.id}
                      className="text-blue-600 hover:underline"
                    >
                      {agency._count.contacts} contacts
                    </Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="mt-6 flex items-center justify-between">
        <p className="text-sm text-gray-600">
          {total > 0 ? (
            <>
              Showing {skip + 1} to {Math.min(skip + limit, total)} of {total} agencies
            </>
          ) : (
            'No results'
          )}
        </p>
        {totalPages > 1 && (
          <Pagination
            currentPage={page}
            totalPages={totalPages}
            baseUrl={'/agencies?search=' + encodeURIComponent(search)}
          />
        )}
      </div>
    </div>
  );
}
AGENCIESPAGETSXEOF

echo -e "${GREEN}✓ src/app/agencies/page.tsx created${NC}"

# =============================================================================
# Create Contacts Page
# =============================================================================
echo -e "${YELLOW}Creating src/app/contacts/page.tsx...${NC}"

cat > src/app/contacts/page.tsx << 'CONTACTSPAGETSXEOF'
import { auth } from '@clerk/nextjs/server';
import { redirect } from 'next/navigation';
import { prisma } from '@/lib/prisma';
import Link from 'next/link';
import { ViewLimitBanner } from '@/components/view-limit-banner';
import { Pagination } from '@/components/pagination';

/**
 * Contacts listing page with search and pagination
 */
export default async function ContactsPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string; agencyId?: string }>;
}) {
  const { userId } = await auth();
  if (!userId) redirect('/sign-in');

  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';
  const agencyId = params.agencyId || '';
  const limit = 10;
  const skip = (page - 1) * limit;

  // Build where clause for search and agency filter
  const where: {
    agencyId?: string;
    OR?: Array<{
      firstName?: { contains: string; mode: 'insensitive' };
      lastName?: { contains: string; mode: 'insensitive' };
      email?: { contains: string; mode: 'insensitive' };
      position?: { contains: string; mode: 'insensitive' };
    }>;
  } = {};

  if (agencyId) {
    where.agencyId = agencyId;
  }

  if (search) {
    where.OR = [
      { firstName: { contains: search, mode: 'insensitive' } },
      { lastName: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
      { position: { contains: search, mode: 'insensitive' } },
    ];
  }

  const [contacts, total] = await Promise.all([
    prisma.contact.findMany({
      where,
      skip,
      take: limit,
      orderBy: { lastName: 'asc' },
      include: {
        agency: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    }),
    prisma.contact.count({ where }),
  ]);

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Contacts</h1>
        <p className="text-gray-600">Manage and view all contacts</p>
      </div>

      <ViewLimitBanner />

      <div className="mt-6">
        {/* Search input */}
        <form method="GET" className="mb-4">
          <div className="flex gap-2">
            <input
              type="text"
              name="search"
              placeholder="Search by name, email, or position..."
              defaultValue={search}
              className="w-full max-w-md rounded-lg border px-4 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {agencyId && <input type="hidden" name="agencyId" value={agencyId} />}
            <button
              type="submit"
              className="rounded-lg bg-blue-600 px-6 py-2 text-white hover:bg-blue-700"
            >
              Search
            </button>
          </div>
        </form>

        {/* Contacts table */}
        <div className="overflow-x-auto rounded-lg border bg-white">
          <table className="w-full">
            <thead className="border-b bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Phone
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Position
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Agency
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {contacts.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                    {search ? 'No contacts found matching your search.' : 'No contacts found.'}
                  </td>
                </tr>
              ) : (
                contacts.map((contact) => (
                  <tr key={contact.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">
                      {contact.firstName} {contact.lastName}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {contact.email}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {contact.phone || '—'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {contact.position || '—'}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {contact.agency.name}
                    </td>
                    <td className="px-6 py-4 text-sm">
                      <Link
                        href={'/contacts/' + contact.id}
                        className="rounded-lg bg-blue-600 px-3 py-1.5 text-white hover:bg-blue-700"
                      >
                        View
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="mt-6 flex items-center justify-between">
          <p className="text-sm text-gray-600">
            {total > 0 ? (
              <>
                Showing {skip + 1} to {Math.min(skip + limit, total)} of {total} contacts
              </>
            ) : (
              'No results'
            )}
          </p>
          {totalPages > 1 && (
            <Pagination
              currentPage={page}
              totalPages={totalPages}
              baseUrl={'/contacts?search=' + encodeURIComponent(search) + (agencyId ? '&agencyId=' + agencyId : '')}
            />
          )}
        </div>
      </div>
    </div>
  );
}
CONTACTSPAGETSXEOF

echo -e "${GREEN}✓ src/app/contacts/page.tsx created${NC}"

# =============================================================================
# Create Contact Detail Page
# =============================================================================
echo -e "${YELLOW}Creating src/app/contacts/[id]/page.tsx...${NC}"

cat > 'src/app/contacts/[id]/page.tsx' << 'CONTACTDETAILEOF'
import { auth } from '@clerk/nextjs/server';
import { redirect } from 'next/navigation';
import { prisma } from '@/lib/prisma';
import { hasReachedDailyLimit, incrementViewCount, getViewStats } from '@/lib/contact-view-limit';
import Link from 'next/link';
import { ArrowLeft, Building2, Mail, Phone, Briefcase, FileText } from 'lucide-react';
import { ViewLimitBanner } from '@/components/view-limit-banner';

/**
 * Contact detail page with rate limiting
 * Increments view count and redirects to upgrade page if limit reached
 */
export default async function ContactDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { userId } = await auth();
  if (!userId) redirect('/sign-in');

  const { id } = await params;

  // Check if user has reached daily limit before showing contact
  const limitReached = await hasReachedDailyLimit(userId);
  if (limitReached) {
    redirect('/upgrade');
  }

  // Fetch contact with agency information
  const contact = await prisma.contact.findUnique({
    where: { id },
    include: {
      agency: true,
    },
  });

  if (!contact) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="rounded-lg border border-red-200 bg-red-50 p-6 text-center">
          <h2 className="text-xl font-semibold text-red-800">Contact Not Found</h2>
          <p className="mt-2 text-red-600">
            The contact you&apos;re looking for doesn&apos;t exist or has been removed.
          </p>
          <Link
            href="/contacts"
            className="mt-4 inline-block rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
          >
            Back to Contacts
          </Link>
        </div>
      </div>
    );
  }

  // Increment view count (this is a successful view)
  await incrementViewCount(userId);

  // Get updated view stats
  const viewStats = await getViewStats(userId);

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Back Link */}
      <Link
        href="/contacts"
        className="mb-6 inline-flex items-center gap-2 text-blue-600 hover:text-blue-800"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to Contacts
      </Link>

      {/* View Limit Banner */}
      <div className="mb-6">
        <ViewLimitBanner />
      </div>

      {/* Contact Information Card */}
      <div className="rounded-lg border bg-white shadow-sm">
        <div className="border-b px-6 py-4">
          <h1 className="text-2xl font-bold text-gray-900">
            {contact.firstName} {contact.lastName}
          </h1>
          <p className="text-gray-600">{contact.position || 'No position'}</p>
        </div>

        <div className="grid gap-6 p-6 md:grid-cols-2">
          {/* Contact Details */}
          <div>
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              Contact Information
            </h2>
            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <Mail className="mt-0.5 h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Email</p>
                  <a
                    href={'mailto:' + contact.email}
                    className="text-blue-600 hover:underline"
                  >
                    {contact.email}
                  </a>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Phone className="mt-0.5 h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Phone</p>
                  <p className="text-gray-900">
                    {contact.phone || 'Not provided'}
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Briefcase className="mt-0.5 h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Position</p>
                  <p className="text-gray-900">
                    {contact.position || 'Not provided'}
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Agency Details */}
          <div>
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              Agency Information
            </h2>
            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <Building2 className="mt-0.5 h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Agency Name</p>
                  <p className="text-gray-900">{contact.agency.name}</p>
                </div>
              </div>

              {contact.agency.email && (
                <div className="flex items-start gap-3">
                  <Mail className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Agency Email</p>
                    <a
                      href={'mailto:' + contact.agency.email}
                      className="text-blue-600 hover:underline"
                    >
                      {contact.agency.email}
                    </a>
                  </div>
                </div>
              )}

              {contact.agency.phone && (
                <div className="flex items-start gap-3">
                  <Phone className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Agency Phone</p>
                    <p className="text-gray-900">{contact.agency.phone}</p>
                  </div>
                </div>
              )}

              {contact.agency.website && (
                <div className="flex items-start gap-3">
                  <FileText className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Website</p>
                    <a
                      href={contact.agency.website}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:underline"
                    >
                      {contact.agency.website}
                    </a>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* View Stats Footer */}
        <div className="border-t bg-gray-50 px-6 py-4">
          <p className="text-sm text-gray-600">
            Daily views: {viewStats.used} of {viewStats.limit} ({viewStats.remaining} remaining)
          </p>
        </div>
      </div>
    </div>
  );
}
CONTACTDETAILEOF

echo -e "${GREEN}✓ src/app/contacts/[id]/page.tsx created${NC}"

# =============================================================================
# Create Upgrade Page
# =============================================================================
echo -e "${YELLOW}Creating src/app/upgrade/page.tsx...${NC}"

cat > src/app/upgrade/page.tsx << 'UPGRADEPAGETSXEOF'
import { auth } from '@clerk/nextjs/server';
import { redirect } from 'next/navigation';
import { getViewStats } from '@/lib/contact-view-limit';
import Link from 'next/link';
import { AlertTriangle, Check, Zap, Crown, ArrowLeft } from 'lucide-react';

/**
 * Upgrade plan page - shown when user exceeds daily contact view limit
 * Displays current usage and upgrade options
 */
export default async function UpgradePage() {
  const { userId } = await auth();
  if (!userId) redirect('/sign-in');

  // Get current view statistics
  const viewStats = await getViewStats(userId);
  const percentageUsed = Math.round((viewStats.used / viewStats.limit) * 100);

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Back Link */}
      <Link
        href="/contacts"
        className="mb-6 inline-flex items-center gap-2 text-blue-600 hover:text-blue-800"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to Contacts
      </Link>

      {/* Warning Banner */}
      <div className="mb-8 rounded-lg border border-yellow-200 bg-yellow-50 p-6">
        <div className="flex items-start gap-4">
          <AlertTriangle className="h-6 w-6 flex-shrink-0 text-yellow-600" />
          <div>
            <h2 className="text-lg font-semibold text-yellow-800">
              Daily Contact View Limit Reached
            </h2>
            <p className="mt-1 text-yellow-700">
              You&apos;ve used {viewStats.used} of your {viewStats.limit} daily contact views.
              Upgrade your plan to unlock unlimited access.
            </p>
          </div>
        </div>
      </div>

      {/* Usage Statistics */}
      <div className="mb-8 rounded-lg border bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-lg font-semibold text-gray-900">Your Usage Today</h3>
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-gray-600">Contact views used</span>
            <span className="font-medium text-gray-900">{viewStats.used}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-gray-600">Daily limit</span>
            <span className="font-medium text-gray-900">{viewStats.limit}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-gray-600">Remaining today</span>
            <span className="font-medium text-gray-900">{viewStats.remaining}</span>
          </div>
          <div className="mt-4">
            <div className="h-3 w-full overflow-hidden rounded-full bg-gray-200">
              <div
                className={'h-full transition-all ' + (
                  percentageUsed >= 100
                    ? 'bg-red-600'
                    : percentageUsed >= 80
                    ? 'bg-yellow-600'
                    : 'bg-blue-600'
                )}
                style={{ width: Math.min(100, percentageUsed) + '%' }}
              />
            </div>
            <p className="mt-1 text-sm text-gray-500">{percentageUsed}% of daily limit used</p>
          </div>
        </div>
      </div>

      {/* Pricing Plans */}
      <h3 className="mb-6 text-2xl font-bold text-gray-900">Upgrade Your Plan</h3>
      <div className="grid gap-6 md:grid-cols-3">
        {/* Free Plan */}
        <div className="rounded-lg border bg-white p-6 shadow-sm">
          <div className="mb-4">
            <h4 className="text-xl font-semibold text-gray-900">Free</h4>
            <p className="text-gray-600">Current plan</p>
          </div>
          <div className="mb-6">
            <span className="text-4xl font-bold text-gray-900">$0</span>
            <span className="text-gray-600">/month</span>
          </div>
          <ul className="mb-6 space-y-3">
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              {viewStats.limit} contact views/day
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Access to all agencies
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Basic search
            </li>
          </ul>
          <button
            disabled
            className="w-full rounded-lg border border-gray-300 bg-gray-100 px-4 py-2 text-gray-500"
          >
            Current Plan
          </button>
        </div>

        {/* Pro Plan */}
        <div className="relative rounded-lg border-2 border-blue-500 bg-white p-6 shadow-sm">
          <div className="absolute -top-3 left-1/2 -translate-x-1/2">
            <span className="rounded-full bg-blue-500 px-3 py-1 text-xs font-medium text-white">
              Popular
            </span>
          </div>
          <div className="mb-4">
            <div className="flex items-center gap-2">
              <Zap className="h-5 w-5 text-blue-500" />
              <h4 className="text-xl font-semibold text-gray-900">Pro</h4>
            </div>
            <p className="text-gray-600">For professionals</p>
          </div>
          <div className="mb-6">
            <span className="text-4xl font-bold text-gray-900">$29</span>
            <span className="text-gray-600">/month</span>
          </div>
          <ul className="mb-6 space-y-3">
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              500 contact views/day
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Access to all agencies
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Advanced search filters
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Export to CSV
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Priority support
            </li>
          </ul>
          <button className="w-full rounded-lg bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700">
            Upgrade to Pro
          </button>
        </div>

        {/* Enterprise Plan */}
        <div className="rounded-lg border bg-white p-6 shadow-sm">
          <div className="mb-4">
            <div className="flex items-center gap-2">
              <Crown className="h-5 w-5 text-purple-500" />
              <h4 className="text-xl font-semibold text-gray-900">Enterprise</h4>
            </div>
            <p className="text-gray-600">For organizations</p>
          </div>
          <div className="mb-6">
            <span className="text-4xl font-bold text-gray-900">$99</span>
            <span className="text-gray-600">/month</span>
          </div>
          <ul className="mb-6 space-y-3">
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Unlimited contact views
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Access to all agencies
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Advanced search filters
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Export to CSV &amp; Excel
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              API access
            </li>
            <li className="flex items-center gap-2 text-sm text-gray-600">
              <Check className="h-4 w-4 text-green-500" />
              Dedicated support
            </li>
          </ul>
          <button className="w-full rounded-lg border border-purple-500 px-4 py-2 font-medium text-purple-600 hover:bg-purple-50">
            Contact Sales
          </button>
        </div>
      </div>

      {/* Note */}
      <p className="mt-8 text-center text-sm text-gray-500">
        Your limit resets daily at midnight UTC. Need help?{' '}
        <a href="#" className="text-blue-600 hover:underline">
          Contact support
        </a>
      </p>
    </div>
  );
}
UPGRADEPAGETSXEOF

echo -e "${GREEN}✓ src/app/upgrade/page.tsx created${NC}"

# =============================================================================
# Create API Routes - Agencies
# =============================================================================
echo -e "${YELLOW}Creating src/app/api/agencies/route.ts...${NC}"

cat > src/app/api/agencies/route.ts << 'AGENCIESAPIEOF'
import { auth } from '@clerk/nextjs/server';
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/agencies
 * Fetch paginated list of agencies with search
 */
export async function GET(request: NextRequest) {
  try {
    // Check authentication
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '10', 10);
    const search = searchParams.get('search') || '';

    const skip = (page - 1) * limit;

    // Build where clause for search
    const where = search
      ? {
          OR: [
            { name: { contains: search, mode: 'insensitive' as const } },
            { email: { contains: search, mode: 'insensitive' as const } },
          ],
        }
      : {};

    // Fetch agencies with pagination
    const [agencies, total] = await Promise.all([
      prisma.agency.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: 'asc' },
        include: {
          _count: {
            select: { contacts: true },
          },
        },
      }),
      prisma.agency.count({ where }),
    ]);

    return NextResponse.json({
      agencies,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching agencies:', error);
    return NextResponse.json(
      { error: 'Failed to fetch agencies' },
      { status: 500 }
    );
  }
}
AGENCIESAPIEOF

echo -e "${GREEN}✓ src/app/api/agencies/route.ts created${NC}"

# =============================================================================
# Create API Routes - Contacts List
# =============================================================================
echo -e "${YELLOW}Creating src/app/api/contacts/route.ts...${NC}"

cat > src/app/api/contacts/route.ts << 'CONTACTSAPIEOF'
import { auth } from '@clerk/nextjs/server';
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/contacts
 * Fetch paginated list of contacts with search and optional agency filter
 */
export async function GET(request: NextRequest) {
  try {
    // Check authentication
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '10', 10);
    const search = searchParams.get('search') || '';
    const agencyId = searchParams.get('agencyId') || undefined;

    const skip = (page - 1) * limit;

    // Build where clause for search and agency filter
    const where: {
      agencyId?: string;
      OR?: Array<{
        firstName?: { contains: string; mode: 'insensitive' };
        lastName?: { contains: string; mode: 'insensitive' };
        email?: { contains: string; mode: 'insensitive' };
        position?: { contains: string; mode: 'insensitive' };
      }>;
    } = {};

    if (agencyId) {
      where.agencyId = agencyId;
    }

    if (search) {
      where.OR = [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { position: { contains: search, mode: 'insensitive' } },
      ];
    }

    // Fetch contacts with pagination
    const [contacts, total] = await Promise.all([
      prisma.contact.findMany({
        where,
        skip,
        take: limit,
        orderBy: { lastName: 'asc' },
        include: {
          agency: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      prisma.contact.count({ where }),
    ]);

    return NextResponse.json({
      contacts,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching contacts:', error);
    return NextResponse.json(
      { error: 'Failed to fetch contacts' },
      { status: 500 }
    );
  }
}
CONTACTSAPIEOF

echo -e "${GREEN}✓ src/app/api/contacts/route.ts created${NC}"

# =============================================================================
# Create API Routes - Contact Detail
# =============================================================================
echo -e "${YELLOW}Creating src/app/api/contacts/[id]/route.ts...${NC}"

cat > 'src/app/api/contacts/[id]/route.ts' << 'CONTACTDETAILAPIEOF'
import { auth } from '@clerk/nextjs/server';
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { hasReachedDailyLimit, incrementViewCount, getViewStats } from '@/lib/contact-view-limit';

/**
 * GET /api/contacts/[id]
 * Fetch single contact with rate limiting
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    // Check authentication
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    // Check if user has reached daily limit
    const limitReached = await hasReachedDailyLimit(userId);
    if (limitReached) {
      return NextResponse.json(
        { error: 'Daily contact view limit reached', limitReached: true },
        { status: 429 }
      );
    }

    // Fetch contact
    const contact = await prisma.contact.findUnique({
      where: { id },
      include: {
        agency: true,
      },
    });

    if (!contact) {
      return NextResponse.json({ error: 'Contact not found' }, { status: 404 });
    }

    // Increment view count
    await incrementViewCount(userId);

    // Get updated view stats
    const viewStats = await getViewStats(userId);

    return NextResponse.json({ contact, viewStats });
  } catch (error) {
    console.error('Error fetching contact:', error);
    return NextResponse.json(
      { error: 'Failed to fetch contact' },
      { status: 500 }
    );
  }
}
CONTACTDETAILAPIEOF

echo -e "${GREEN}✓ src/app/api/contacts/[id]/route.ts created${NC}"

# =============================================================================
# Create API Routes - View Stats
# =============================================================================
echo -e "${YELLOW}Creating src/app/api/view-stats/route.ts...${NC}"

cat > src/app/api/view-stats/route.ts << 'VIEWSTATSAPIEOF'
import { auth } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';
import { getViewStats } from '@/lib/contact-view-limit';

/**
 * GET /api/view-stats
 * Get the current user's daily view statistics
 */
export async function GET() {
  try {
    // Check authentication
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get view statistics for the user
    const stats = await getViewStats(userId);

    return NextResponse.json(stats);
  } catch (error) {
    console.error('Error fetching view stats:', error);
    return NextResponse.json(
      { error: 'Failed to fetch view stats' },
      { status: 500 }
    );
  }
}
VIEWSTATSAPIEOF

echo -e "${GREEN}✓ src/app/api/view-stats/route.ts created${NC}"

# =============================================================================
# Create Data Import Script
# =============================================================================
echo -e "${YELLOW}Creating scripts/import-data.ts...${NC}"

cat > scripts/import-data.ts << 'IMPORTDATATSEOF'
import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();

interface AgencyData {
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  website?: string;
}

interface ContactData {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  position?: string;
  agencyName: string;
}

/**
 * Normalize agency name for matching
 * - Trim whitespace
 * - Convert to lowercase
 * - Remove special characters
 */
function normalizeAgencyName(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s]/gi, '')
    .replace(/\s+/g, ' ');
}

/**
 * Import agencies from JSON file
 */
async function importAgencies(filePath: string): Promise<Map<string, string>> {
  console.log('📥 Importing agencies...');

  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const records: AgencyData[] = JSON.parse(fileContent);

  const agencyMap = new Map<string, string>(); // normalized name -> id
  let successCount = 0;
  let failCount = 0;

  for (const record of records) {
    try {
      const agency = await prisma.agency.upsert({
        where: { name: record.name },
        update: {
          email: record.email || null,
          phone: record.phone || null,
          address: record.address || null,
          website: record.website || null,
        },
        create: {
          name: record.name,
          email: record.email || null,
          phone: record.phone || null,
          address: record.address || null,
          website: record.website || null,
        },
      });

      const normalizedName = normalizeAgencyName(record.name);
      agencyMap.set(normalizedName, agency.id);
      successCount++;
      console.log('✅ Agency: ' + record.name);
    } catch (error) {
      console.error('❌ Failed to import agency: ' + record.name, error);
      failCount++;
    }
  }

  console.log('\n✨ Imported ' + successCount + ' agencies');
  if (failCount > 0) {
    console.log('⚠️  Failed to import ' + failCount + ' agencies');
  }
  console.log('');
  return agencyMap;
}

/**
 * Import contacts from JSON file
 */
async function importContacts(
  filePath: string,
  agencyMap: Map<string, string>
): Promise<void> {
  console.log('📥 Importing contacts...');

  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const records: ContactData[] = JSON.parse(fileContent);

  let successCount = 0;
  let failCount = 0;

  for (const record of records) {
    try {
      const normalizedAgencyName = normalizeAgencyName(record.agencyName);
      const agencyId = agencyMap.get(normalizedAgencyName);

      if (!agencyId) {
        console.warn('⚠️  Agency not found for contact: ' + record.email + ' (' + record.agencyName + ')');
        failCount++;
        continue;
      }

      await prisma.contact.upsert({
        where: { email: record.email },
        update: {
          firstName: record.firstName,
          lastName: record.lastName,
          phone: record.phone || null,
          position: record.position || null,
          agencyId,
        },
        create: {
          firstName: record.firstName,
          lastName: record.lastName,
          email: record.email,
          phone: record.phone || null,
          position: record.position || null,
          agencyId,
        },
      });

      successCount++;
      console.log('✅ Contact: ' + record.firstName + ' ' + record.lastName);
    } catch (error) {
      console.error('❌ Failed to import contact: ' + record.email, error);
      failCount++;
    }
  }

  console.log('\n✨ Imported ' + successCount + ' contacts');
  if (failCount > 0) {
    console.log('⚠️  Failed to import ' + failCount + ' contacts');
  }
}

/**
 * Main import function
 */
async function main() {
  try {
    const agenciesPath = path.join(process.cwd(), 'data', 'agencies.json');
    const contactsPath = path.join(process.cwd(), 'data', 'contacts.json');

    // Check if files exist
    if (!fs.existsSync(agenciesPath)) {
      throw new Error('Agencies file not found: ' + agenciesPath);
    }
    if (!fs.existsSync(contactsPath)) {
      throw new Error('Contacts file not found: ' + contactsPath);
    }

    console.log('Starting data import...\n');

    // Import agencies first
    const agencyMap = await importAgencies(agenciesPath);

    // Import contacts with agency mapping
    await importContacts(contactsPath, agencyMap);

    console.log('\nData import completed successfully!');
  } catch (error) {
    console.error('💥 Import failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
IMPORTDATATSEOF

echo -e "${GREEN}✓ scripts/import-data.ts created${NC}"

# =============================================================================
# Create README
# =============================================================================
echo -e "${YELLOW}Creating README.md...${NC}"

cat > README.md << 'READMEEOF'
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
READMEEOF

echo -e "${GREEN}✓ README.md created${NC}"

# =============================================================================
# Finalization
# =============================================================================

echo ""
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${GREEN}                    Setup Complete!                                          ${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy .env.example to .env and configure your Clerk keys"
echo "2. Run: docker-compose up -d postgres"
echo "3. Run: npm install"
echo "4. Run: npx prisma migrate dev"
echo "5. Run: npm run import:data"
echo "6. Run: npm run dev"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
