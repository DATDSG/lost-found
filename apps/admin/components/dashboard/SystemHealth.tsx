"use client";

import { useQuery } from "react-query";
import apiClient from "@/lib/api";

interface SystemHealth {
  status: "healthy" | "degraded" | "unhealthy";
  services: {
    api: boolean;
    database: boolean;
    redis: boolean;
    storage: boolean;
    nlp: boolean;
    vision: boolean;
  };
  uptime: string;
  version: string;
  last_backup?: string;
}

export function SystemHealth() {
  const { data: health, isLoading } = useQuery<SystemHealth>(
    "system-health",
    async () => {
      return await apiClient.getSystemHealth();
    },
    {
      refetchInterval: 30000, // Refetch every 30 seconds
    }
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case "healthy":
        return "text-green-600 bg-green-100";
      case "degraded":
        return "text-yellow-600 bg-yellow-100";
      case "unhealthy":
        return "text-red-600 bg-red-100";
      default:
        return "text-gray-600 bg-gray-100";
    }
  };

  const getServiceIcon = (isHealthy: boolean) => {
    return isHealthy ? "✅" : "❌";
  };

  const getServiceColor = (isHealthy: boolean) => {
    return isHealthy ? "text-green-600" : "text-red-600";
  };

  if (isLoading) {
    return (
      <div className="card p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-3">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="h-8 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-medium text-gray-900">System Health</h3>
        <span
          className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(
            health?.status || "unknown"
          )}`}
        >
          {health?.status?.toUpperCase() || "UNKNOWN"}
        </span>
      </div>

      <div className="space-y-4">
        {/* Services Status */}
        <div>
          <h4 className="text-sm font-medium text-gray-700 mb-3">Services</h4>
          <div className="grid grid-cols-2 gap-3">
            {health?.services &&
              Object.entries(health.services).map(([service, isHealthy]) => (
                <div key={service} className="flex items-center space-x-2">
                  <span className={getServiceColor(isHealthy)}>
                    {getServiceIcon(isHealthy)}
                  </span>
                  <span className="text-sm text-gray-600 capitalize">
                    {service}
                  </span>
                </div>
              ))}
          </div>
        </div>

        {/* System Info */}
        <div className="border-t pt-4">
          <h4 className="text-sm font-medium text-gray-700 mb-3">
            System Info
          </h4>
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Version:</span>
              <span className="text-gray-900 font-mono">
                {health?.version || "Unknown"}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Uptime:</span>
              <span className="text-gray-900">
                {health?.uptime || "Unknown"}
              </span>
            </div>
            {health?.last_backup && (
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Last Backup:</span>
                <span className="text-gray-900">{health.last_backup}</span>
              </div>
            )}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="border-t pt-4">
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <div className="text-lg font-bold text-gray-900">
                {health?.services
                  ? Object.values(health.services).filter(Boolean).length
                  : 0}
              </div>
              <div className="text-xs text-gray-500">Services Up</div>
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">
                {health?.services ? Object.keys(health.services).length : 0}
              </div>
              <div className="text-xs text-gray-500">Total Services</div>
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">
                {health?.status === "healthy"
                  ? "100%"
                  : health?.status === "degraded"
                  ? "75%"
                  : "0%"}
              </div>
              <div className="text-xs text-gray-500">Health Score</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
