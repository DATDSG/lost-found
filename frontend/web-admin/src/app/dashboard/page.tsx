'use client'

import { useQuery } from '@tanstack/react-query'
import { systemApi } from '@/lib/api'
import { LoadingSpinner } from '@/components/ui/loading-spinner'
import { StatsCards } from '@/components/dashboard/stats-cards'
import { RecentActivity } from '@/components/dashboard/recent-activity'
import { SystemOverview } from '@/components/dashboard/system-overview'
import { QuickActions } from '@/components/dashboard/quick-actions'

export default function DashboardPage() {
  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['system-stats'],
    queryFn: () => systemApi.getStats(),
  })

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="text-red-600 mb-4">
          <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">Failed to load dashboard</h3>
        <p className="text-gray-600">Please try refreshing the page or contact support if the problem persists.</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">
          Welcome to the Lost & Found admin panel. Here's an overview of your system.
        </p>
      </div>

      {/* Stats cards */}
      {stats && <StatsCards stats={stats.data} />}

      {/* Main content grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left column - 2/3 width */}
        <div className="lg:col-span-2 space-y-6">
          <SystemOverview />
          <RecentActivity />
        </div>

        {/* Right column - 1/3 width */}
        <div className="space-y-6">
          <QuickActions />
        </div>
      </div>
    </div>
  )
}
