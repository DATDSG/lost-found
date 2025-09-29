'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { itemsApi } from '@/lib/api'
import { LoadingSpinner } from '@/components/ui/loading-spinner'
import { ItemsTable } from '@/components/items/items-table'
import { ItemsFilters } from '@/components/items/items-filters'
import { ItemsStats } from '@/components/items/items-stats'
import type { FilterOptions, SortOptions } from '@/types'

export default function ItemsPage() {
  const [page, setPage] = useState(1)
  const [filters, setFilters] = useState<FilterOptions>({})
  const [sort, setSort] = useState<SortOptions>({ field: 'reportedAt', direction: 'desc' })
  const limit = 20

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['items', page, filters, sort],
    queryFn: () => itemsApi.getItems(page, limit, filters, sort),
  })

  const handleFilterChange = (newFilters: FilterOptions) => {
    setFilters(newFilters)
    setPage(1) // Reset to first page when filters change
  }

  const handleSortChange = (newSort: SortOptions) => {
    setSort(newSort)
    setPage(1)
  }

  const handlePageChange = (newPage: number) => {
    setPage(newPage)
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="text-red-600 mb-4">
          <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">Failed to load items</h3>
        <p className="text-gray-600 mb-4">Please try refreshing the page or contact support if the problem persists.</p>
        <button
          onClick={() => refetch()}
          className="btn-primary"
        >
          Try Again
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Items Management</h1>
          <p className="mt-2 text-gray-600">
            Manage lost and found items reported by users
          </p>
        </div>
        <div className="flex space-x-3">
          <button
            onClick={() => refetch()}
            className="btn-secondary"
            disabled={isLoading}
          >
            {isLoading ? <LoadingSpinner size="sm" className="mr-2" /> : null}
            Refresh
          </button>
        </div>
      </div>

      {/* Stats */}
      <ItemsStats />

      {/* Filters */}
      <ItemsFilters
        filters={filters}
        onFiltersChange={handleFilterChange}
      />

      {/* Items table */}
      {isLoading ? (
        <div className="card p-8">
          <div className="flex items-center justify-center">
            <LoadingSpinner size="lg" />
          </div>
        </div>
      ) : (
        <ItemsTable
          items={data?.data || []}
          total={data?.total || 0}
          page={page}
          limit={limit}
          sort={sort}
          onSortChange={handleSortChange}
          onPageChange={handlePageChange}
          onRefresh={refetch}
        />
      )}
    </div>
  )
}
