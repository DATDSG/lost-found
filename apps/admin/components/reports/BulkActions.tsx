"use client";

import { useState } from "react";

interface BulkActionsProps {
  selectedCount: number;
  onBulkUpdate: (status: string) => void;
  onClearSelection: () => void;
}

export function BulkActions({
  selectedCount,
  onBulkUpdate,
  onClearSelection,
}: BulkActionsProps) {
  const [showActions, setShowActions] = useState(false);

  const handleBulkAction = (status: string) => {
    onBulkUpdate(status);
    setShowActions(false);
  };

  return (
    <div className="card p-4 bg-primary-50 border-primary-200">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <span className="text-sm font-medium text-primary-900">
            {selectedCount} report{selectedCount !== 1 ? "s" : ""} selected
          </span>
          <button
            onClick={onClearSelection}
            className="text-sm text-primary-600 hover:text-primary-500"
          >
            Clear selection
          </button>
        </div>

        <div className="relative">
          <button
            onClick={() => setShowActions(!showActions)}
            className="btn btn-primary"
          >
            Bulk Actions
          </button>

          {showActions && (
            <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg z-10 border border-gray-200">
              <div className="py-1">
                <button
                  onClick={() => handleBulkAction("approved")}
                  className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                >
                  Approve Selected
                </button>
                <button
                  onClick={() => handleBulkAction("hidden")}
                  className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                >
                  Hide Selected
                </button>
                <button
                  onClick={() => handleBulkAction("removed")}
                  className="block w-full text-left px-4 py-2 text-sm text-red-700 hover:bg-red-50"
                >
                  Remove Selected
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
