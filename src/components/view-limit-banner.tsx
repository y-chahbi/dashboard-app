'use client';

import { useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';

interface ViewStats {
  remaining: number;
  limit: number;
  used: number;
}

export function ViewLimitBanner() {
  const [stats, setStats] = useState<ViewStats | null>(null);

  useEffect(() => {
    fetch('/api/view-stats')
      .then((res) => res.json())
      .then((data) => setStats(data))
      .catch((err) => console.error('Failed to fetch view stats:', err));
  }, []);

  if (!stats) return null;

  const percentage = (stats.used / stats.limit) * 100;
  const isWarning = percentage >= 80;
  const isCritical = percentage >= 95;

  return (
    <div
      className={`rounded-lg border p-4 ${
        isCritical
          ? 'border-red-200 bg-red-50'
          : isWarning
          ? 'border-yellow-200 bg-yellow-50'
          : 'border-blue-200 bg-blue-50'
      }`}
    >
      <div className="flex items-center gap-3">
        <AlertCircle
          className={`h-5 w-5 ${
            isCritical
              ? 'text-red-600'
              : isWarning
              ? 'text-yellow-600'
              : 'text-blue-600'
          }`}
        />
        <div className="flex-1">
          <p
            className={`text-sm font-medium ${
              isCritical
                ? 'text-red-900'
                : isWarning
                ? 'text-yellow-900'
                : 'text-blue-900'
            }`}
          >
            Daily Contact Views: {stats.remaining} remaining of {stats.limit}
          </p>
          <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-gray-200">
            <div
              className={`h-full transition-all ${
                isCritical
                  ? 'bg-red-600'
                  : isWarning
                  ? 'bg-yellow-600'
                  : 'bg-blue-600'
              }`}
              style={{ width: `${percentage}%` }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}