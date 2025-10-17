"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import apiClient from "@/lib/api";

interface QuickAction {
  title: string;
  description: string;
  icon: string;
  href?: string;
  onClick?: () => void;
  color: "blue" | "green" | "yellow" | "red" | "purple" | "indigo";
}

export function QuickActions() {
  const router = useRouter();

  const actions: QuickAction[] = [
    {
      title: "Create Report",
      description: "Add a new lost or found item",
      icon: "📝",
      href: "/reports",
      color: "blue",
    },
    {
      title: "Review Matches",
      description: "Check and approve potential matches",
      icon: "🔗",
      href: "/matches",
      color: "green",
    },
    {
      title: "Manage Users",
      description: "View and manage user accounts",
      icon: "👥",
      href: "/users",
      color: "indigo",
    },
    {
      title: "System Health",
      description: "Check service status and performance",
      icon: "💚",
      onClick: () => {
        // You could add a modal or redirect to health page
        console.log("System health check");
      },
      color: "green",
    },
    {
      title: "Backup Database",
      description: "Create a backup of the database",
      icon: "💾",
      onClick: () => {
        // You could trigger a backup API call
        console.log("Database backup initiated");
      },
      color: "purple",
    },
    {
      title: "Clear Cache",
      description: "Clear system cache and refresh data",
      icon: "🔄",
      onClick: async () => {
        try {
          await apiClient.clearCache();
          router.refresh();
        } catch (error) {
          console.error("Failed to clear cache:", error);
        }
      },
      color: "yellow",
    },
  ];

  const colorClasses = {
    blue: "hover:bg-blue-50 border-blue-200",
    green: "hover:bg-green-50 border-green-200",
    yellow: "hover:bg-yellow-50 border-yellow-200",
    red: "hover:bg-red-50 border-red-200",
    purple: "hover:bg-purple-50 border-purple-200",
    indigo: "hover:bg-indigo-50 border-indigo-200",
  };

  const iconColorClasses = {
    blue: "text-blue-600",
    green: "text-green-600",
    yellow: "text-yellow-600",
    red: "text-red-600",
    purple: "text-purple-600",
    indigo: "text-indigo-600",
  };

  return (
    <div className="card p-6">
      <h3 className="text-lg font-medium text-gray-900 mb-4">Quick Actions</h3>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        {actions.map((action, index) => {
          const content = (
            <div
              className={`p-4 rounded-lg border transition-colors cursor-pointer ${
                colorClasses[action.color]
              }`}
            >
              <div className="flex items-center space-x-3">
                <span className={`text-xl ${iconColorClasses[action.color]}`}>
                  {action.icon}
                </span>
                <div className="flex-1 min-w-0">
                  <h4 className="text-sm font-medium text-gray-900">
                    {action.title}
                  </h4>
                  <p className="text-xs text-gray-500 mt-1">
                    {action.description}
                  </p>
                </div>
              </div>
            </div>
          );

          if (action.href) {
            return (
              <Link key={index} href={action.href}>
                {content}
              </Link>
            );
          }

          return (
            <div key={index} onClick={action.onClick}>
              {content}
            </div>
          );
        })}
      </div>
    </div>
  );
}
