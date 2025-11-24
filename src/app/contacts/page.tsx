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
                        href={`/contacts/${contact.id}`}
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
              baseUrl={`/contacts?search=${encodeURIComponent(search)}${agencyId ? `&agencyId=${agencyId}` : ''}`}
            />
          )}
        </div>
      </div>
    </div>
  );
}