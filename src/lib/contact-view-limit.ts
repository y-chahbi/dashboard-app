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
 */
async function getOrCreateViewLimit(userId: string) {
  const today = getStartOfToday();
  
  // Try to find existing record
  let viewLimit = await prisma.contactViewLimit.findUnique({
    where: {
      userId_date: {
        userId,
        date: today,
      },
    },
  });
  
  // Create if not exists
  if (!viewLimit) {
    viewLimit = await prisma.contactViewLimit.create({
      data: {
        userId,
        date: today,
        count: 0,
      },
    });
  }
  
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
