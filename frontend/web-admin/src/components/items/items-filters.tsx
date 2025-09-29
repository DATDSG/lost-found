'use client'

import { useState } from 'react'
import { FunnelIcon, XMarkIcon } from '@heroicons/react/24/outline'
import type { FilterOptions } from '@/types'

interface ItemsFiltersProps {
  filters: FilterOptions
  onFiltersChange: (filters: FilterOptions) => void
}

export function ItemsFilters({ filters, onFiltersChange }: ItemsFiltersProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [localFilters, setLocalFilters] = useState<FilterOptions>(filters)

  const statusOptions = [
    { value: 'lost', label: 'Lost' },
    { value: 'found', label: 'Found' },
    { value: 'claimed', label: 'Claimed' },
    { value: 'closed', label: 'Closed' },
  ]

  const categoryOptions = [
    { value: 'phone', label: 'Phone' },
    { value: 'wallet', label: 'Wallet' },
    { value: 'bag', label: 'Bag' },
    { value: 'keys', label: 'Keys' },
    { value: 'laptop', label: 'Laptop' },
    { value: 'watch', label: 'Watch' },
    { value: 'jewelry', label: 'Jewelry' },
  ]

  const languageOptions = [
    { value: 'en', label: 'English' },
    { value: 'si', label: 'Sinhala' },
    { value: 'ta', label: 'Tamil' },
  ]

  const handleApplyFilters = () => {
    onFiltersChange(localFilters)
    setIsOpen(false)
  }

  const handleClearFilters = () => {
    const clearedFilters = {}
    setLocalFilters(clearedFilters)
    onFiltersChange(clearedFilters)
    setIsOpen(false)
  }

  const activeFiltersCount = Object.values(filters).filter(value => 
    Array.isArray(value) ? value.length > 0 : value !== undefined && value !== null
  ).length

  return (
    <div className="relative">
      {/* Filter button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="btn-secondary flex items-center space-x-2"
      >
        <FunnelIcon className="h-4 w-4" />
        <span>Filters</span>
        {activeFiltersCount > 0 && (
          <span className="bg-primary-600 text-white text-xs rounded-full px-2 py-0.5">
            {activeFiltersCount}
          </span>
        )}
      </button>

      {/* Filter panel */}
      {isOpen && (
        <div className="absolute top-full left-0 mt-2 w-96 bg-white rounded-lg shadow-lg border border-gray-200 z-10">
          <div className="p-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">Filters</h3>
              <button
                onClick={() => setIsOpen(false)}
                className="text-gray-400 hover:text-gray-500"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-4">
              {/* Status filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Status
                </label>
                <div className="space-y-2">
                  {statusOptions.map((option) => (
                    <label key={option.value} className="flex items-center">
                      <input
                        type="checkbox"
                        checked={localFilters.status?.includes(option.value) || false}
                        onChange={(e) => {
                          const currentStatus = localFilters.status || []
                          const newStatus = e.target.checked
                            ? [...currentStatus, option.value]
                            : currentStatus.filter(s => s !== option.value)
                          setLocalFilters({
                            ...localFilters,
                            status: newStatus.length > 0 ? newStatus : undefined
                          })
                        }}
                        className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span className="ml-2 text-sm text-gray-700">{option.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Category filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Category
                </label>
                <div className="space-y-2">
                  {categoryOptions.map((option) => (
                    <label key={option.value} className="flex items-center">
                      <input
                        type="checkbox"
                        checked={localFilters.category?.includes(option.value) || false}
                        onChange={(e) => {
                          const currentCategory = localFilters.category || []
                          const newCategory = e.target.checked
                            ? [...currentCategory, option.value]
                            : currentCategory.filter(c => c !== option.value)
                          setLocalFilters({
                            ...localFilters,
                            category: newCategory.length > 0 ? newCategory : undefined
                          })
                        }}
                        className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span className="ml-2 text-sm text-gray-700">{option.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Language filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Language
                </label>
                <div className="space-y-2">
                  {languageOptions.map((option) => (
                    <label key={option.value} className="flex items-center">
                      <input
                        type="checkbox"
                        checked={localFilters.language?.includes(option.value) || false}
                        onChange={(e) => {
                          const currentLanguage = localFilters.language || []
                          const newLanguage = e.target.checked
                            ? [...currentLanguage, option.value]
                            : currentLanguage.filter(l => l !== option.value)
                          setLocalFilters({
                            ...localFilters,
                            language: newLanguage.length > 0 ? newLanguage : undefined
                          })
                        }}
                        className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <span className="ml-2 text-sm text-gray-700">{option.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Date range filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Date Range
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="date"
                    value={localFilters.dateRange?.start || ''}
                    onChange={(e) => {
                      setLocalFilters({
                        ...localFilters,
                        dateRange: {
                          ...localFilters.dateRange,
                          start: e.target.value,
                          end: localFilters.dateRange?.end || ''
                        }
                      })
                    }}
                    className="input text-sm"
                    placeholder="Start date"
                  />
                  <input
                    type="date"
                    value={localFilters.dateRange?.end || ''}
                    onChange={(e) => {
                      setLocalFilters({
                        ...localFilters,
                        dateRange: {
                          ...localFilters.dateRange,
                          start: localFilters.dateRange?.start || '',
                          end: e.target.value
                        }
                      })
                    }}
                    className="input text-sm"
                    placeholder="End date"
                  />
                </div>
              </div>
            </div>

            {/* Action buttons */}
            <div className="flex justify-between pt-4 mt-4 border-t border-gray-200">
              <button
                onClick={handleClearFilters}
                className="btn-ghost text-sm"
              >
                Clear All
              </button>
              <div className="flex space-x-2">
                <button
                  onClick={() => setIsOpen(false)}
                  className="btn-secondary text-sm"
                >
                  Cancel
                </button>
                <button
                  onClick={handleApplyFilters}
                  className="btn-primary text-sm"
                >
                  Apply Filters
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Active filters display */}
      {activeFiltersCount > 0 && (
        <div className="mt-2 flex flex-wrap gap-2">
          {filters.status?.map(status => (
            <span key={status} className="badge badge-primary">
              Status: {status}
              <button
                onClick={() => {
                  const newStatus = filters.status?.filter(s => s !== status)
                  onFiltersChange({
                    ...filters,
                    status: newStatus?.length ? newStatus : undefined
                  })
                }}
                className="ml-1 text-primary-600 hover:text-primary-800"
              >
                ×
              </button>
            </span>
          ))}
          {filters.category?.map(category => (
            <span key={category} className="badge badge-success">
              Category: {category}
              <button
                onClick={() => {
                  const newCategory = filters.category?.filter(c => c !== category)
                  onFiltersChange({
                    ...filters,
                    category: newCategory?.length ? newCategory : undefined
                  })
                }}
                className="ml-1 text-success-600 hover:text-success-800"
              >
                ×
              </button>
            </span>
          ))}
          {filters.language?.map(language => (
            <span key={language} className="badge badge-warning">
              Language: {language}
              <button
                onClick={() => {
                  const newLanguage = filters.language?.filter(l => l !== language)
                  onFiltersChange({
                    ...filters,
                    language: newLanguage?.length ? newLanguage : undefined
                  })
                }}
                className="ml-1 text-warning-600 hover:text-warning-800"
              >
                ×
              </button>
            </span>
          ))}
        </div>
      )}
    </div>
  )
}
