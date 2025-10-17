"use client";

import { useQuery } from "react-query";
import apiClient from "@/lib/api";
import { formatDistanceToNow } from "date-fns";

interface ActivityItem {
  id: string;
  action: string;
  resource: string;
  resource_id: string;
  actor_id: string;
  actor_email?: string;
  created_at: string;
  changes?: any;
}

export function ActivityFeed() {
  const { data: activities, isLoading } = useQuery<ActivityItem[]>(
    "activity-feed",
    async () => {
      const result = await apiClient.getAuditLogs({ skip: "0", limit: "10" });
      return result.items || [];
    },
    {
      refetchInterval: 30000, // Refetch every 30 seconds
    }
  );

  const getActionIcon = (action: string) => {
    switch (action) {
      case "create":
        return "➕";
      case "update":
        return "✏️";
      case "delete":
        return "🗑️";
      case "login":
        return "🔐";
      case "logout":
        return "🚪";
      case "ban":
        return "🚫";
      case "unban":
        return "✅";
      default:
        return "📝";
    }
  };

  const getActionColor = (action: string) => {
    switch (action) {
      case "create":
        return "text-green-600 bg-green-100";
      case "update":
        return "text-blue-600 bg-blue-100";
      case "delete":
        return "text-red-600 bg-red-100";
      case "login":
        return "text-indigo-600 bg-indigo-100";
      case "logout":
        return "text-gray-600 bg-gray-100";
      case "ban":
        return "text-red-600 bg-red-100";
      case "unban":
        return "text-green-600 bg-green-100";
      default:
        return "text-gray-600 bg-gray-100";
    }
  };

  if (isLoading) {
    return (
      <div className="card p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-3">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-16 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-medium text-gray-900">Recent Activity</h3>
        <span className="text-sm text-gray-500">
          {activities?.length || 0} activities
        </span>
      </div>

      <div className="space-y-4">
        {activities?.length === 0 ? (
          <div className="text-center py-8">
            <div className="text-gray-400 text-4xl mb-2">📝</div>
            <p className="text-gray-500">No recent activity</p>
          </div>
        ) : (
          activities?.map((activity) => (
            <div key={activity.id} className="flex items-start space-x-3">
              <div
                className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm ${getActionColor(
                  activity.action
                )}`}
              >
                {getActionIcon(activity.action)}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center space-x-2">
                  <p className="text-sm font-medium text-gray-900">
                    {activity.action.charAt(0).toUpperCase() +
                      activity.action.slice(1)}
                  </p>
                  <span className="text-sm text-gray-500">
                    {activity.resource}
                  </span>
                  {activity.resource_id && (
                    <span className="text-xs text-gray-400 font-mono">
                      #{activity.resource_id.slice(-8)}
                    </span>
                  )}
                </div>
                <div className="flex items-center space-x-2 mt-1">
                  <span className="text-xs text-gray-500">
                    by{" "}
                    {activity.actor_email ||
                      `User ${activity.actor_id.slice(-8)}`}
                  </span>
                  <span className="text-xs text-gray-400">
                    {activity.created_at
                      ? formatDistanceToNow(new Date(activity.created_at), {
                          addSuffix: true,
                        })
                      : "Unknown"}
                  </span>
                </div>
                {activity.changes && (
                  <div className="mt-2 text-xs text-gray-600 bg-gray-50 p-2 rounded">
                    <pre className="whitespace-pre-wrap">
                      {JSON.stringify(activity.changes, null, 2)}
                    </pre>
                  </div>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
