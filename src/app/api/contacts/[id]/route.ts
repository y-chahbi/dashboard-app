import { auth } from '@clerk/nextjs/server';
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { hasReachedDailyLimit, incrementViewCount } from '@/lib/contact-view-limit';

/**
 * GET /api/contacts/[id]
 * Fetch single contact with rate limiting
 */
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    // Check authentication
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = params;

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

    return NextResponse.json({ contact });
  } catch (error) {
    console.error('Error fetching contact:', error);
    return NextResponse.json(
      { error: 'Failed to fetch contact' },
      { status: 500 }
    );
  }
}