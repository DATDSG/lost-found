"use client";

import { useState } from "react";
import { MagnifyingGlassIcon, FunnelIcon } from "@heroicons/react/24/outline";

interface Filters {
  search: string;
  status: string;
  min_score: string;
  max_score: string;
  type: string;
}

interface MatchFiltersProps {
  filters: Filters;
  onFiltersChange: (filters: Filters) => void;
}

export function MatchFilters({ filters, onFiltersChange }: MatchFiltersProps) {
  const [isExpanded, setIsExpanded] = useState(false);

  const handleFilterChange = (key: keyof Filters, value: string) => {
    onFiltersChange({ ...filters, [key]: value });
  };

  const clearFilters = () => {
    onFiltersChange({
      search: "",
      status: "",
      min_score: "",
      max_score: "",
      type: "",
    });
  };

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-medium text-gray-900">Filters</h3>
        <button
          onClick={() => setIsExpanded(!isExpanded)}
          className="flex items-center text-sm text-gray-500 hover:text-gray-700"
        >
          <FunnelIcon className="h-4 w-4 mr-1" />
          {isExpanded ? "Hide" : "Show"} filters
        </button>
      </div>

      <div className="space-y-4">
        {/* Search */}
        <div className="relative">
          <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search matches..."
            value={filters.search}
            onChange={(e) => handleFilterChange("search", e.target.value)}
            className="input pl-10"
          />
        </div>

        {isExpanded && (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {/* Status Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Status
              </label>
              <select
                value={filters.status}
                onChange={(e) => handleFilterChange("status", e.target.value)}
                className="input"
                aria-label="Filter by status"
                title="Select status to filter matches"
              >
                <option value="">All Statuses</option>
                <option value="candidate">Candidate</option>
                <option value="promoted">Promoted</option>
                <option value="suppressed">Suppressed</option>
                <option value="dismissed">Dismissed</option>
              </select>
            </div>

            {/* Type Filter */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Type
              </label>
              <select
                value={filters.type}
                onChange={(e) => handleFilterChange("type", e.target.value)}
                className="input"
                aria-label="Filter by type"
                title="Select type to filter matches"
              >
                <option value="">All Types</option>
                <option value="lost">Lost Items</option>
                <option value="found">Found Items</option>
              </select>
            </div>

            {/* Min Score */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Min Score (%)
              </label>
              <input
                type="number"
                min="0"
                max="100"
                placeholder="0"
                value={filters.min_score}
                onChange={(e) =>
                  handleFilterChange("min_score", e.target.value)
                }
                className="input"
              />
            </div>

            {/* Max Score */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Max Score (%)
              </label>
              <input
                type="number"
                min="0"
                max="100"
                placeholder="100"
                value={filters.max_score}
                onChange={(e) =>
                  handleFilterChange("max_score", e.target.value)
                }
                className="input"
              />
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex items-center justify-between">
          <button
            onClick={clearFilters}
            className="text-sm text-gray-500 hover:text-gray-700"
          >
            Clear all filters
          </button>
        </div>
      </div>
    </div>
  );
}
