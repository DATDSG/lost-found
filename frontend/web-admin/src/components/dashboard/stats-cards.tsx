'use client'

import { 
  PackageIcon, 
  UsersIcon, 
  LinkIcon, 
  ClipboardListIcon 
} from '@heroicons/react/24/outline'
import { formatNumber } from '@/lib/utils'
import type { SystemStats } from '@/types'

interface StatsCardsProps {
  stats: SystemStats
}

export function StatsCards({ stats }: StatsCardsProps) {
  const cards = [
    {
      name: 'Total Items',
      value: stats.totalItems,
      icon: PackageIcon,
      change: `+${stats.recentActivity.newItems}`,
      changeType: 'increase' as const,
      description: 'New items this week',
    },
    {
      name: 'Total Users',
      value: stats.totalUsers,
      icon: UsersIcon,
      change: '+12%',
      changeType: 'increase' as const,
      description: 'From last month',
    },
    {
      name: 'Active Matches',
      value: stats.totalMatches,
      icon: LinkIcon,
      change: `+${stats.recentActivity.newMatches}`,
      changeType: 'increase' as const,
      description: 'New matches this week',
    },
    {
      name: 'Pending Claims',
      value: stats.claimsByStatus.pending,
      icon: ClipboardListIcon,
      change: `+${stats.recentActivity.newClaims}`,
      changeType: 'increase' as const,
      description: 'Awaiting review',
    },
  ]

  return (
    <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
      {cards.map((card) => (
        <div key={card.name} className="card p-6">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <card.icon className="h-8 w-8 text-gray-400" />
            </div>
            <div className="ml-5 w-0 flex-1">
              <dl>
                <dt className="text-sm font-medium text-gray-500 truncate">
                  {card.name}
                </dt>
                <dd className="flex items-baseline">
                  <div className="text-2xl font-semibold text-gray-900">
                    {formatNumber(card.value)}
                  </div>
                  <div className="ml-2 flex items-baseline text-sm font-semibold text-success-600">
                    <svg
                      className="self-center flex-shrink-0 h-4 w-4 text-success-500"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fillRule="evenodd"
                        d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                    <span className="sr-only">Increased by</span>
                    {card.change}
                  </div>
                </dd>
                <dd className="text-sm text-gray-500 mt-1">
                  {card.description}
                </dd>
              </dl>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}
