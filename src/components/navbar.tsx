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
