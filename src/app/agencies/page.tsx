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
                      href={`/contacts?agencyId=${agency.id}`}
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
            baseUrl={`/agencies?search=${encodeURIComponent(search)}`}
          />
        )}
      </div>
    </div>
  );
}
