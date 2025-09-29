'use client'

import { useQuery } from '@tanstack/react-query'
import { itemsApi, matchesApi, claimsApi } from '@/lib/api'
import { LoadingSpinner } from '@/components/ui/loading-spinner'
import { formatRelativeTime, getStatusColor } from '@/lib/utils'
import { 
  PackageIcon, 
  LinkIcon, 
  ClipboardListIcon,
  UserIcon 
} from '@heroicons/react/24/outline'

export function RecentActivity() {
  const { data: recentItems, isLoading: itemsLoading } = useQuery({
    queryKey: ['recent-items'],
    queryFn: () => itemsApi.getItems(1, 5, undefined, { field: 'createdAt', direction: 'desc' }),
  })

  const { data: recentMatches, isLoading: matchesLoading } = useQuery({
    queryKey: ['recent-matches'],
    queryFn: () => matchesApi.getMatches(1, 5),
  })

  const { data: recentClaims, isLoading: claimsLoading } = useQuery({
    queryKey: ['recent-claims'],
    queryFn: () => claimsApi.getClaims(1, 5),
  })

  const isLoading = itemsLoading || matchesLoading || claimsLoading

  if (isLoading) {
    return (
      <div className="card p-6">
        <div className="flex items-center justify-center h-64">
          <LoadingSpinner size="lg" />
        </div>
      </div>
    )
  }

  const activities = [
    ...(recentItems?.data || []).map(item => ({
      id: `item-${item.id}`,
      type: 'item' as const,
      title: `New ${item.status} item: ${item.title}`,
      description: `Reported by ${item.owner.fullName}`,
      time: item.reportedAt,
      status: item.status,
      icon: PackageIcon,
    })),
    ...(recentMatches?.data || []).map(match => ({
      id: `match-${match.id}`,
      type: 'match' as const,
      title: `New match found`,
      description: `${match.lostItem.title} matched with ${match.foundItem.title}`,
      time: match.createdAt,
      status: match.status,
      icon: LinkIcon,
    })),
    ...(recentClaims?.data || []).map(claim => ({
      id: `claim-${claim.id}`,
      type: 'claim' as const,
      title: `New claim submitted`,
      description: `${claim.claimant.fullName} claimed ${claim.item.title}`,
      time: claim.submittedAt,
      status: claim.status,
      icon: ClipboardListIcon,
    })),
  ].sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()).slice(0, 10)

  return (
    <div className="card p-6">
      <div className="mb-6">
        <h3 className="text-lg font-medium text-gray-900">Recent Activity</h3>
        <p className="text-sm text-gray-600">Latest items, matches, and claims in the system</p>
      </div>

      <div className="flow-root">
        <ul className="-mb-8">
          {activities.map((activity, activityIdx) => (
            <li key={activity.id}>
              <div className="relative pb-8">
                {activityIdx !== activities.length - 1 ? (
                  <span
                    className="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200"
                    aria-hidden="true"
                  />
                ) : null}
                <div className="relative flex space-x-3">
                  <div>
                    <span className="h-8 w-8 rounded-full bg-gray-100 flex items-center justify-center ring-8 ring-white">
                      <activity.icon className="h-4 w-4 text-gray-500" />
                    </span>
                  </div>
                  <div className="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div>
                      <p className="text-sm text-gray-900">{activity.title}</p>
                      <p className="text-sm text-gray-500">{activity.description}</p>
                      <div className="mt-1">
                        <span className={`badge ${getStatusColor(activity.status)}`}>
                          {activity.status}
                        </span>
                      </div>
                    </div>
                    <div className="whitespace-nowrap text-right text-sm text-gray-500">
                      <time dateTime={activity.time}>
                        {formatRelativeTime(activity.time)}
                      </time>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>

      {activities.length === 0 && (
        <div className="text-center py-8">
          <UserIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">No recent activity</h3>
          <p className="mt-1 text-sm text-gray-500">
            Recent items, matches, and claims will appear here.
          </p>
        </div>
      )}
    </div>
  )
}
