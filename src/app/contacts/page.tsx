import { auth } from '@clerk/nextjs/server';
import { redirect } from 'next/navigation';
import { prisma } from '@/lib/prisma';
import Link from 'next/link';
import { ViewLimitBanner } from '@/components/view-limit-banner';

export default async function ContactsPage({
  searchParams,
}: {
  searchParams: { page?: string; search?: string };
}) {
  const { userId } = await auth();
  if (!userId) redirect('/sign-in');

  const page = parseInt(searchParams.page || '1', 10);
  const search = searchParams.search || '';
  const limit = 10;
  const skip = (page - 1) * limit;

  const where = search
    ? {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' as const } },
          { lastName: { contains: search, mode: 'insensitive' as const } },
          { email: { contains: search, mode: 'insensitive' as const } },
        ],
      }
    : {};

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
          <input
            type="text"
            name="search"
            placeholder="Search contacts..."
            defaultValue={search}
            className="w-full max-w-md rounded-lg border px-4 py-2"
          />
        </form>

        {/* Contacts table */}
        <div className="overflow-x-auto rounded-lg border">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-900">
                  Email
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
            <tbody className="divide-y bg-white">
              {contacts.map((contact) => (
                <tr key={contact.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">
                    {contact.firstName} {contact.lastName}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {contact.email}
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
                      className="text-blue-600 hover:text-blue-800"
                    >
                      View Details
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="mt-4 flex items-center justify-between">
          <p className="text-sm text-gray-600">
            Showing {skip + 1} to {Math.min(skip + limit, total)} of {total}{' '}
            contacts
          </p>
          <div className="flex gap-2">
            {page > 1 && (
              <a
                href={`?page=${page - 1}&search=${search}`}
                className="rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
              >
                Previous
              </a>
            )}
            {page < totalPages && (
              <a
                href={`?page=${page + 1}&search=${search}`}
                className="rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
              >
                Next
              </a>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}