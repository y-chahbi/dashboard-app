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
                    href={`mailto:${contact.email}`}
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
                      href={`mailto:${contact.agency.email}`}
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
