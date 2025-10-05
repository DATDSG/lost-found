"use client";

import { useQuery } from "@tanstack/react-query";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import { systemApi } from "@/lib/api";
import { LoadingSpinner } from "@/components/ui/loading-spinner";

const COLORS = ["#0ea5e9", "#22c55e", "#f59e0b", "#ef4444"];

export function SystemOverview() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ["system-stats"],
    queryFn: () => systemApi.getStats(),
  });

  if (isLoading) {
    return (
      <div className="card p-6">
        <div className="flex items-center justify-center h-64">
          <LoadingSpinner size="lg" />
        </div>
      </div>
    );
  }

  if (!stats) {
    return null;
  }

  const itemsData = [
    { name: "Lost", value: stats.itemsByStatus.lost, color: "#ef4444" },
    { name: "Found", value: stats.itemsByStatus.found, color: "#22c55e" },
    { name: "Claimed", value: stats.itemsByStatus.claimed, color: "#0ea5e9" },
    { name: "Closed", value: stats.itemsByStatus.closed, color: "#6b7280" },
  ];

  const matchesData = [
    { name: "Pending", value: stats.matchesByStatus.pending },
    { name: "Accepted", value: stats.matchesByStatus.accepted },
    { name: "Rejected", value: stats.matchesByStatus.rejected },
  ];

  return (
    <div className="card p-6">
      <div className="mb-6">
        <h3 className="text-lg font-medium text-gray-900">System Overview</h3>
        <p className="text-sm text-gray-600">
          Current status of items and matches in the system
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Items by Status - Pie Chart */}
        <div>
          <h4 className="text-sm font-medium text-gray-900 mb-4">
            Items by Status
          </h4>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={itemsData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) =>
                    `${name} ${(percent * 100).toFixed(0)}%`
                  }
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {itemsData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Matches by Status - Bar Chart */}
        <div>
          <h4 className="text-sm font-medium text-gray-900 mb-4">
            Matches by Status
          </h4>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={matchesData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#0ea5e9" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="mt-6 pt-6 border-t border-gray-200">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="text-center">
            <div className="text-2xl font-semibold text-gray-900">
              {(
                (stats.matchesByStatus.accepted / stats.totalMatches) *
                100
              ).toFixed(1)}
              %
            </div>
            <div className="text-sm text-gray-600">Match Success Rate</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-semibold text-gray-900">
              {((stats.itemsByStatus.claimed / stats.totalItems) * 100).toFixed(
                1
              )}
              %
            </div>
            <div className="text-sm text-gray-600">Items Claimed</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-semibold text-gray-900">
              {stats.claimsByStatus.pending}
            </div>
            <div className="text-sm text-gray-600">Pending Claims</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-semibold text-gray-900">
              {stats.recentActivity.newItems + stats.recentActivity.newMatches}
            </div>
            <div className="text-sm text-gray-600">Recent Activity</div>
          </div>
        </div>
      </div>
    </div>
  );
}
