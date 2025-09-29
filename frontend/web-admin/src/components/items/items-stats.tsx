'use client'

import { useQuery } from '@tanstack/react-query'
import { systemApi } from '@/lib/api'
import { LoadingSpinner } from '@/components/ui/loading-spinner'
import { formatNumber } from '@/lib/utils'

export function ItemsStats() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['system-stats'],
    queryFn: () => systemApi.getStats(),
  })

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="card p-6">
            <div className="flex items-center justify-center h-16">
              <LoadingSpinner size="sm" />
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (!stats?.data) {
    return null
  }

  const itemStats = [
    {
      name: 'Lost Items',
      value: stats.data.itemsByStatus.lost,
      color: 'text-danger-600',
      bgColor: 'bg-danger-100',
      change: '+12%',
      changeType: 'increase' as const,
    },
    {
      name: 'Found Items',
      value: stats.data.itemsByStatus.found,
      color: 'text-success-600',
      bgColor: 'bg-success-100',
      change: '+8%',
      changeType: 'increase' as const,
    },
    {
      name: 'Claimed Items',
      value: stats.data.itemsByStatus.claimed,
      color: 'text-primary-600',
      bgColor: 'bg-primary-100',
      change: '+15%',
      changeType: 'increase' as const,
    },
    {
      name: 'Closed Items',
      value: stats.data.itemsByStatus.closed,
      color: 'text-gray-600',
      bgColor: 'bg-gray-100',
      change: '+3%',
      changeType: 'increase' as const,
    },
  ]

  return (
    <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
      {itemStats.map((stat) => (
        <div key={stat.name} className="card p-6">
          <div className="flex items-center">
            <div className={`flex-shrink-0 rounded-md p-3 ${stat.bgColor}`}>
              <div className={`text-2xl font-bold ${stat.color}`}>
                {formatNumber(stat.value)}
              </div>
            </div>
            <div className="ml-4 flex-1">
              <div className="text-sm font-medium text-gray-500">
                {stat.name}
              </div>
              <div className="flex items-center text-sm">
                <span className="text-success-600 font-medium">
                  {stat.change}
                </span>
                <span className="text-gray-500 ml-1">from last month</span>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}
