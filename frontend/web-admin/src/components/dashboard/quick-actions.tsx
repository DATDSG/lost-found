'use client'

import Link from 'next/link'
import { 
  PlusIcon, 
  EyeIcon, 
  Cog6ToothIcon,
  DocumentArrowDownIcon,
  FlagIcon,
  ChartBarIcon 
} from '@heroicons/react/24/outline'

export function QuickActions() {
  const actions = [
    {
      name: 'Review Claims',
      description: 'Review pending item claims',
      href: '/dashboard/claims?status=pending',
      icon: EyeIcon,
      color: 'bg-primary-600 hover:bg-primary-700',
    },
    {
      name: 'Manage Users',
      description: 'View and manage user accounts',
      href: '/dashboard/users',
      icon: PlusIcon,
      color: 'bg-success-600 hover:bg-success-700',
    },
    {
      name: 'System Settings',
      description: 'Configure system settings',
      href: '/dashboard/settings',
      icon: Cog6ToothIcon,
      color: 'bg-gray-600 hover:bg-gray-700',
    },
    {
      name: 'Export Data',
      description: 'Download system reports',
      href: '/dashboard/analytics?tab=export',
      icon: DocumentArrowDownIcon,
      color: 'bg-warning-600 hover:bg-warning-700',
    },
    {
      name: 'Feature Flags',
      description: 'Toggle system features',
      href: '/dashboard/features',
      icon: FlagIcon,
      color: 'bg-purple-600 hover:bg-purple-700',
    },
    {
      name: 'Analytics',
      description: 'View detailed analytics',
      href: '/dashboard/analytics',
      icon: ChartBarIcon,
      color: 'bg-indigo-600 hover:bg-indigo-700',
    },
  ]

  return (
    <div className="card p-6">
      <div className="mb-6">
        <h3 className="text-lg font-medium text-gray-900">Quick Actions</h3>
        <p className="text-sm text-gray-600">Common administrative tasks</p>
      </div>

      <div className="space-y-3">
        {actions.map((action) => (
          <Link
            key={action.name}
            href={action.href}
            className="group relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-4 py-3 shadow-sm hover:border-gray-400 hover:shadow-md transition-all duration-200"
          >
            <div className={`flex-shrink-0 rounded-lg p-2 ${action.color} transition-colors`}>
              <action.icon className="h-5 w-5 text-white" />
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-sm font-medium text-gray-900 group-hover:text-gray-700">
                {action.name}
              </div>
              <div className="text-sm text-gray-500 group-hover:text-gray-400">
                {action.description}
              </div>
            </div>
            <div className="flex-shrink-0">
              <svg
                className="h-5 w-5 text-gray-400 group-hover:text-gray-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </div>
          </Link>
        ))}
      </div>

      {/* System Status */}
      <div className="mt-6 pt-6 border-t border-gray-200">
        <h4 className="text-sm font-medium text-gray-900 mb-3">System Status</h4>
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600">API Status</span>
            <span className="flex items-center text-sm text-success-600">
              <div className="w-2 h-2 bg-success-500 rounded-full mr-2"></div>
              Online
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600">Database</span>
            <span className="flex items-center text-sm text-success-600">
              <div className="w-2 h-2 bg-success-500 rounded-full mr-2"></div>
              Connected
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-600">ML Services</span>
            <span className="flex items-center text-sm text-warning-600">
              <div className="w-2 h-2 bg-warning-500 rounded-full mr-2"></div>
              Partial
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}
