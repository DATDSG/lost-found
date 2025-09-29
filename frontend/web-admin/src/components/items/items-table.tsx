'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { itemsApi } from '@/lib/api'
import { formatDateTime, formatRelativeTime, getStatusColor, truncateText } from '@/lib/utils'
import { LoadingSpinner } from '@/components/ui/loading-spinner'
import { 
  EyeIcon, 
  PencilIcon, 
  TrashIcon,
  CheckCircleIcon,
  XCircleIcon,
  ChevronUpDownIcon,
  ChevronLeftIcon,
  ChevronRightIcon
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import type { Item, SortOptions } from '@/types'

interface ItemsTableProps {
  items: Item[]
  total: number
  page: number
  limit: number
  sort: SortOptions
  onSortChange: (sort: SortOptions) => void
  onPageChange: (page: number) => void
  onRefresh: () => void
}

export function ItemsTable({
  items,
  total,
  page,
  limit,
  sort,
  onSortChange,
  onPageChange,
  onRefresh,
}: ItemsTableProps) {
  const [selectedItems, setSelectedItems] = useState<number[]>([])
  const queryClient = useQueryClient()

  const verifyMutation = useMutation({
    mutationFn: itemsApi.verifyItem,
    onSuccess: () => {
      toast.success('Item verified successfully')
      queryClient.invalidateQueries({ queryKey: ['items'] })
      onRefresh()
    },
    onError: () => {
      toast.error('Failed to verify item')
    },
  })

  const closeMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason?: string }) => 
      itemsApi.closeItem(id, reason),
    onSuccess: () => {
      toast.success('Item closed successfully')
      queryClient.invalidateQueries({ queryKey: ['items'] })
      onRefresh()
    },
    onError: () => {
      toast.error('Failed to close item')
    },
  })

  const deleteMutation = useMutation({
    mutationFn: itemsApi.deleteItem,
    onSuccess: () => {
      toast.success('Item deleted successfully')
      queryClient.invalidateQueries({ queryKey: ['items'] })
      onRefresh()
    },
    onError: () => {
      toast.error('Failed to delete item')
    },
  })

  const handleSort = (field: string) => {
    const direction = sort.field === field && sort.direction === 'asc' ? 'desc' : 'asc'
    onSortChange({ field, direction })
  }

  const handleSelectAll = () => {
    if (selectedItems.length === items.length) {
      setSelectedItems([])
    } else {
      setSelectedItems(items.map(item => item.id))
    }
  }

  const handleSelectItem = (id: number) => {
    setSelectedItems(prev => 
      prev.includes(id) 
        ? prev.filter(itemId => itemId !== id)
        : [...prev, id]
    )
  }

  const totalPages = Math.ceil(total / limit)

  const SortButton = ({ field, children }: { field: string; children: React.ReactNode }) => (
    <button
      onClick={() => handleSort(field)}
      className="group inline-flex items-center space-x-1 text-left font-medium text-gray-900 hover:text-gray-700"
    >
      <span>{children}</span>
      <ChevronUpDownIcon className="h-4 w-4 text-gray-400 group-hover:text-gray-500" />
    </button>
  )

  return (
    <div className="card overflow-hidden">
      {/* Table header with bulk actions */}
      {selectedItems.length > 0 && (
        <div className="bg-primary-50 px-6 py-3 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <span className="text-sm text-primary-700">
              {selectedItems.length} item{selectedItems.length > 1 ? 's' : ''} selected
            </span>
            <div className="flex space-x-2">
              <button
                onClick={() => {
                  selectedItems.forEach(id => verifyMutation.mutate(id))
                  setSelectedItems([])
                }}
                className="btn-primary text-xs"
                disabled={verifyMutation.isPending}
              >
                Verify Selected
              </button>
              <button
                onClick={() => {
                  selectedItems.forEach(id => closeMutation.mutate({ id }))
                  setSelectedItems([])
                }}
                className="btn-secondary text-xs"
                disabled={closeMutation.isPending}
              >
                Close Selected
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left">
                <input
                  type="checkbox"
                  checked={selectedItems.length === items.length && items.length > 0}
                  onChange={handleSelectAll}
                  className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                />
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <SortButton field="title">Item</SortButton>
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <SortButton field="status">Status</SortButton>
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <SortButton field="owner.fullName">Owner</SortButton>
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <SortButton field="reportedAt">Reported</SortButton>
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Matches
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Verified
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {items.map((item) => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <input
                    type="checkbox"
                    checked={selectedItems.includes(item.id)}
                    onChange={() => handleSelectItem(item.id)}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center">
                    {item.images.length > 0 ? (
                      <img
                        className="h-10 w-10 rounded-lg object-cover mr-3"
                        src={item.images[0].url}
                        alt={item.title}
                      />
                    ) : (
                      <div className="h-10 w-10 rounded-lg bg-gray-200 flex items-center justify-center mr-3">
                        <span className="text-gray-500 text-xs">No img</span>
                      </div>
                    )}
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {truncateText(item.title, 30)}
                      </div>
                      <div className="text-sm text-gray-500">
                        {item.description ? truncateText(item.description, 50) : 'No description'}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`badge ${getStatusColor(item.status)}`}>
                    {item.status}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="text-sm text-gray-900">{item.owner.fullName}</div>
                  <div className="text-sm text-gray-500">{item.owner.email}</div>
                </td>
                <td className="px-6 py-4">
                  <div className="text-sm text-gray-900">
                    {formatDateTime(item.reportedAt)}
                  </div>
                  <div className="text-sm text-gray-500">
                    {formatRelativeTime(item.reportedAt)}
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className="text-sm text-gray-900">
                    {item.matches.length}
                  </span>
                </td>
                <td className="px-6 py-4">
                  {item.isVerified ? (
                    <CheckCircleIcon className="h-5 w-5 text-success-500" />
                  ) : (
                    <XCircleIcon className="h-5 w-5 text-gray-400" />
                  )}
                </td>
                <td className="px-6 py-4 text-right text-sm font-medium">
                  <div className="flex items-center justify-end space-x-2">
                    <Link
                      href={`/dashboard/items/${item.id}`}
                      className="text-primary-600 hover:text-primary-900"
                    >
                      <EyeIcon className="h-4 w-4" />
                    </Link>
                    {!item.isVerified && (
                      <button
                        onClick={() => verifyMutation.mutate(item.id)}
                        disabled={verifyMutation.isPending}
                        className="text-success-600 hover:text-success-900"
                        title="Verify item"
                      >
                        {verifyMutation.isPending ? (
                          <LoadingSpinner size="sm" />
                        ) : (
                          <CheckCircleIcon className="h-4 w-4" />
                        )}
                      </button>
                    )}
                    <button
                      onClick={() => closeMutation.mutate({ id: item.id })}
                      disabled={closeMutation.isPending}
                      className="text-warning-600 hover:text-warning-900"
                      title="Close item"
                    >
                      <XCircleIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => {
                        if (confirm('Are you sure you want to delete this item?')) {
                          deleteMutation.mutate(item.id)
                        }
                      }}
                      disabled={deleteMutation.isPending}
                      className="text-danger-600 hover:text-danger-900"
                      title="Delete item"
                    >
                      <TrashIcon className="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
          <div className="flex-1 flex justify-between sm:hidden">
            <button
              onClick={() => onPageChange(page - 1)}
              disabled={page === 1}
              className="btn-secondary"
            >
              Previous
            </button>
            <button
              onClick={() => onPageChange(page + 1)}
              disabled={page === totalPages}
              className="btn-secondary"
            >
              Next
            </button>
          </div>
          <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p className="text-sm text-gray-700">
                Showing <span className="font-medium">{(page - 1) * limit + 1}</span> to{' '}
                <span className="font-medium">
                  {Math.min(page * limit, total)}
                </span>{' '}
                of <span className="font-medium">{total}</span> results
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                <button
                  onClick={() => onPageChange(page - 1)}
                  disabled={page === 1}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                >
                  <ChevronLeftIcon className="h-5 w-5" />
                </button>
                {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                  const pageNum = i + 1
                  return (
                    <button
                      key={pageNum}
                      onClick={() => onPageChange(pageNum)}
                      className={`relative inline-flex items-center px-4 py-2 border text-sm font-medium ${
                        page === pageNum
                          ? 'z-10 bg-primary-50 border-primary-500 text-primary-600'
                          : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'
                      }`}
                    >
                      {pageNum}
                    </button>
                  )
                })}
                <button
                  onClick={() => onPageChange(page + 1)}
                  disabled={page === totalPages}
                  className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                >
                  <ChevronRightIcon className="h-5 w-5" />
                </button>
              </nav>
            </div>
          </div>
        </div>
      )}

      {items.length === 0 && (
        <div className="text-center py-12">
          <svg
            className="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2 2v-5m16 0h-2M4 13h2m13-8V4a1 1 0 00-1-1H7a1 1 0 00-1 1v1m8 0V4a1 1 0 00-1-1H9a1 1 0 00-1 1v1"
            />
          </svg>
          <h3 className="mt-2 text-sm font-medium text-gray-900">No items found</h3>
          <p className="mt-1 text-sm text-gray-500">
            Try adjusting your search or filter criteria.
          </p>
        </div>
      )}
    </div>
  )
}
