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
