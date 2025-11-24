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
