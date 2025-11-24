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
                className={`h-full transition-all ${
                  percentageUsed >= 100
                    ? 'bg-red-600'
                    : percentageUsed >= 80
                    ? 'bg-yellow-600'
                    : 'bg-blue-600'
                }`}
                style={{ width: `${Math.min(100, percentageUsed)}%` }}
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
