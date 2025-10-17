"use client";

import { useQuery } from "react-query";
import { useState } from "react";
import apiClient from "@/lib/api";
import { StatsCard } from "@/components/dashboard/StatsCard";
import { ReportsChart } from "@/components/dashboard/ReportsChart";
import { RecentReports } from "@/components/dashboard/RecentReports";
import { RecentMatches } from "@/components/dashboard/RecentMatches";
import { ActivityFeed } from "@/components/dashboard/ActivityFeed";
import { QuickActions } from "@/components/dashboard/QuickActions";
import { SystemHealth } from "@/components/dashboard/SystemHealth";
import { toast } from "react-toastify";
import {
  ArrowPathIcon,
  ChartBarIcon,
  UsersIcon,
  DocumentTextIcon,
  LinkIcon,
} from "@heroicons/react/24/outline";

interface DashboardStats {
  total_reports: number;
  total_users: number;
  total_matches: number;
  resolved_reports: number;
  pending_reports: number;
  reports_this_month: number;
  users_this_month: number;
  resolution_rate: number;
}

export default function DashboardPage() {
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  // Real-time dashboard stats with shorter refresh interval
  const { data: stats, isLoading: statsLoading, refetch: refetchStats } = useQuery<DashboardStats>(
    "dashboard-stats",
    async () => {
      return await apiClient.getDashboardStats();
    },
    {
      refetchInterval: 10000, // Refetch every 10 seconds for real-time feel
      refetchOnWindowFocus: true,
      refetchOnMount: true,
    }
  );

  // Real-time reports chart
  const { data: chartData, refetch: refetchChart } = useQuery(
    "reports-chart",
    () => apiClient.getReportsChart(30),
    {
      refetchInterval: 30000, // Refetch every 30 seconds
      refetchOnWindowFocus: true,
    }
  );

  // Real-time system health
  const { data: healthData, refetch: refetchHealth } = useQuery(
    "system-health",
    apiClient.getSystemHealth,
    {
      refetchInterval: 15000, // Refetch every 15 seconds
      refetchOnWindowFocus: true,
    }
  );

  // Real-time activity feed
  const { data: activityData, refetch: refetchActivity } = useQuery(
    "activity-feed",
    () => apiClient.getAuditLogs({ skip: "0", limit: "5" }),
    {
      refetchInterval: 20000, // Refetch every 20 seconds
      refetchOnWindowFocus: true,
    }
  );

  const handleRefreshAll = async () => {
    try {
      await Promise.all([
        refetchStats(),
        refetchChart(),
        refetchHealth(),
        refetchActivity(),
      ]);
      setLastRefresh(new Date());
      toast.success("Dashboard refreshed successfully!");
    } catch (error) {
      toast.error("Failed to refresh dashboard data");
    }
  };

  const handleQuickAction = async (action: string) => {
    try {
      switch (action) {
        case "clear-cache":
          await apiClient.clearCache();
          toast.success("Cache cleared successfully!");
          // Refresh all data after cache clear
          handleRefreshAll();
          break;
        case "refresh-data":
          handleRefreshAll();
          break;
        case "view-reports":
          window.location.href = "/reports";
          break;
        case "view-matches":
          window.location.href = "/matches";
          break;
        case "view-users":
          window.location.href = "/users";
          break;
        default:
          toast.info(`Action "${action}" not implemented yet`);
      }
    } catch (error: any) {
      toast.error(`Failed to execute action: ${error.message}`);
    }
  };

  if (statsLoading) {
    return (
      <div className="space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/4 mb-6"></div>
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-24 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with Refresh Button */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="mt-1 text-sm text-gray-500">
            Overview of your Lost & Found platform
            {lastRefresh && (
              <span className="ml-2 text-xs text-gray-400">
                • Last updated: {lastRefresh.toLocaleTimeString()}
              </span>
            )}
          </p>
        </div>
        <button
          onClick={handleRefreshAll}
          className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          <ArrowPathIcon className="h-4 w-4 mr-2" />
          Refresh All
        </button>
      </div>

      {/* Real-time Stats Cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <StatsCard
          title="Total Reports"
          value={stats?.total_reports || 0}
          change={`+${stats?.reports_this_month || 0} this month`}
          changeType="positive"
          trend="up"
          icon="📄"
          description="Lost and found items reported"
          color="blue"
        />
        <StatsCard
          title="Total Users"
          value={stats?.total_users || 0}
          change={`+${stats?.users_this_month || 0} this month`}
          changeType="positive"
          trend="up"
          icon="👥"
          description="Registered platform users"
          color="green"
        />
        <StatsCard
          title="Total Matches"
          value={stats?.total_matches || 0}
          change=""
          changeType="neutral"
          trend="stable"
          icon="🔗"
          description="Potential item matches found"
          color="purple"
        />
        <StatsCard
          title="Resolution Rate"
          value={`${Math.round(stats?.resolution_rate || 0)}%`}
          change=""
          changeType={stats?.resolution_rate && stats.resolution_rate > 70 ? "positive" : "neutral"}
          trend={stats?.resolution_rate && stats.resolution_rate > 70 ? "up" : "stable"}
          icon="✅"
          description="Successfully resolved cases"
          color="indigo"
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Left Column - Charts and Reports */}
        <div className="lg:col-span-2 space-y-6">
          {/* Enhanced Reports Chart */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900 flex items-center">
                  <ChartBarIcon className="h-5 w-5 mr-2" />
                  Reports Over Time
                </h3>
                <div className="flex items-center space-x-2">
                  <div className="flex items-center text-sm text-gray-500">
                    <div className="w-3 h-3 bg-blue-500 rounded-full mr-2"></div>
                    Total Reports
                  </div>
                  <div className="flex items-center text-sm text-gray-500">
                    <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                    Resolved
                  </div>
                </div>
              </div>
            </div>
            <div className="p-6">
              <ReportsChart />
            </div>
          </div>

          {/* Recent Reports */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900 flex items-center">
                  <DocumentTextIcon className="h-5 w-5 mr-2" />
                  Recent Reports
                </h3>
                <button
                  onClick={() => window.location.href = "/reports"}
                  className="text-sm text-indigo-600 hover:text-indigo-500"
                >
                  View all
                </button>
              </div>
            </div>
            <div className="p-6">
              <RecentReports />
            </div>
          </div>
        </div>

        {/* Right Column - Activity and Actions */}
        <div className="space-y-6">
          {/* Enhanced Activity Feed */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900">Recent Activity</h3>
                <div className="flex items-center text-xs text-gray-500">
                  <div className="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
                  Live
                </div>
              </div>
            </div>
            <div className="p-6">
              <ActivityFeed />
            </div>
          </div>

          {/* Enhanced Quick Actions */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Quick Actions</h3>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <button
                  onClick={() => handleQuickAction("view-reports")}
                  className="group relative bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200 border border-gray-200"
                >
                  <div className="flex items-center space-x-3">
                    <div className="flex-shrink-0">
                      <DocumentTextIcon className="h-6 w-6 text-blue-500 group-hover:text-blue-600" />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-sm font-medium text-gray-900">View Reports</h4>
                      <p className="text-xs text-gray-500">Manage all reports</p>
                    </div>
                  </div>
                </button>

                <button
                  onClick={() => handleQuickAction("view-matches")}
                  className="group relative bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200 border border-gray-200"
                >
                  <div className="flex items-center space-x-3">
                    <div className="flex-shrink-0">
                      <LinkIcon className="h-6 w-6 text-purple-500 group-hover:text-purple-600" />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-sm font-medium text-gray-900">Review Matches</h4>
                      <p className="text-xs text-gray-500">Check potential matches</p>
                    </div>
                  </div>
                </button>

                <button
                  onClick={() => handleQuickAction("view-users")}
                  className="group relative bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200 border border-gray-200"
                >
                  <div className="flex items-center space-x-3">
                    <div className="flex-shrink-0">
                      <UsersIcon className="h-6 w-6 text-green-500 group-hover:text-green-600" />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-sm font-medium text-gray-900">Manage Users</h4>
                      <p className="text-xs text-gray-500">User management</p>
                    </div>
                  </div>
                </button>

                <button
                  onClick={() => handleQuickAction("clear-cache")}
                  className="group relative bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200 border border-gray-200"
                >
                  <div className="flex items-center space-x-3">
                    <div className="flex-shrink-0">
                      <ArrowPathIcon className="h-6 w-6 text-yellow-500 group-hover:text-yellow-600" />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-sm font-medium text-gray-900">Clear Cache</h4>
                      <p className="text-xs text-gray-500">Refresh system cache</p>
                    </div>
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Row - Matches and System Health */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Recent Matches */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900 flex items-center">
                <LinkIcon className="h-5 w-5 mr-2" />
                Recent Matches
              </h3>
              <button
                onClick={() => window.location.href = "/matches"}
                className="text-sm text-indigo-600 hover:text-indigo-500"
              >
                View all
              </button>
            </div>
          </div>
          <div className="p-6">
            <RecentMatches />
          </div>
        </div>

        {/* System Health */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900">System Health</h3>
              <div className="flex items-center text-xs text-gray-500">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
                Live
              </div>
            </div>
          </div>
          <div className="p-6">
            <SystemHealth />
          </div>
        </div>
      </div>
    </div>
  );
}