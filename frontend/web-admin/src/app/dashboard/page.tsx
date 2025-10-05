"use client";

import { useQuery } from "@tanstack/react-query";
import { systemApi } from "@/lib/api";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { StatsCards } from "@/components/dashboard/stats-cards";
import { RecentActivity } from "@/components/dashboard/recent-activity";
import { SystemOverview } from "@/components/dashboard/system-overview";
import { QuickActions } from "@/components/dashboard/quick-actions";
import type { SystemStats } from "@/types";

export default function DashboardPage() {
  const {
    data: stats,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["system-stats"],
    queryFn: () => systemApi.getStats(),
    retry: false,
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  // In development, show a notice if API is not available
  if (error && process.env.NODE_ENV === "development") {
    // Mock data for development
    const mockStats: SystemStats = {
      totalItems: 156,
      totalUsers: 432,
      totalMatches: 89,
      totalClaims: 45,
      itemsByStatus: {
        lost: 72,
        found: 67,
        claimed: 12,
        closed: 5,
      },
      matchesByStatus: {
        pending: 15,
        accepted: 67,
        rejected: 7,
      },
      claimsByStatus: {
        pending: 8,
        approved: 32,
        rejected: 5,
      },
      recentActivity: {
        newItems: 12,
        newMatches: 5,
        newClaims: 3,
      },
    };

    return (
      <div className="space-y-6">
        {/* Warning banner */}
        <div className="rounded-md bg-yellow-50 p-4 border border-yellow-200">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg
                className="h-5 w-5 text-yellow-400"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fillRule="evenodd"
                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                  clipRule="evenodd"
                />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-yellow-800">
                Backend API Not Connected
              </h3>
              <div className="mt-2 text-sm text-yellow-700">
                <p>
                  The backend API at{" "}
                  <code className="font-mono bg-yellow-100 px-1 rounded">
                    http://localhost:8000
                  </code>{" "}
                  is not responding.
                </p>
                <p className="mt-1">
                  Showing demo data. Please start the backend server to see real
                  data.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Demo content */}
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            Dashboard{" "}
            <span className="text-sm font-normal text-gray-500">
              (Demo Mode)
            </span>
          </h1>
          <p className="mt-2 text-gray-600">
            This is a preview of the admin panel. Connect the backend to see
            real data.
          </p>
        </div>

        {/* Stats cards with demo data */}
        <StatsCards stats={mockStats} />

        {/* Main content grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <SystemOverview />
            <RecentActivity />
          </div>
          <div className="space-y-6">
            <QuickActions />
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="text-red-600 mb-4">
          <svg
            className="mx-auto h-12 w-12"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
            />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">
          Failed to load dashboard
        </h3>
        <p className="text-gray-600">
          Please try refreshing the page or contact support if the problem
          persists.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">
          Welcome to the Lost & Found admin panel. Here's an overview of your
          system.
        </p>
      </div>

      {/* Stats cards */}
      {stats && <StatsCards stats={stats} />}

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
  );
}
