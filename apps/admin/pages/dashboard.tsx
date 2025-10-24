import React, { useState, useEffect } from "react";
import type { NextPage } from "next";
import { useRouter } from "next/router";
import {
  ChartBarIcon,
  UserGroupIcon,
  DocumentTextIcon,
  ExclamationTriangleIcon,
  ClockIcon,
  CheckCircleIcon,
  ArrowUpIcon,
  ArrowDownIcon,
} from "@heroicons/react/24/outline";
import AdminLayout from "../components/AdminLayout";
import { Card, Badge, LoadingSpinner } from "../components/ui";
import { DashboardStats } from "../types";
import apiService from "../services/api";

const Dashboard: NextPage = () => {
  const router = useRouter();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recentActivity, setRecentActivity] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [statsData, activityData] = await Promise.all([
        apiService.getDashboardStats(),
        apiService.getRecentActivity(),
      ]);

      setStats({
        ...statsData,
        recent_activity: activityData,
      });
    } catch (err) {
      setError("Failed to load dashboard data");
      console.error("Dashboard error:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleQuickAction = (action: string) => {
    switch (action) {
      case "reports":
        router.push("/reports");
        break;
      case "fraud":
        router.push("/fraud-detection");
        break;
      case "matches":
        router.push("/matching");
        break;
      case "users":
        router.push("/users");
        break;
      default:
        break;
    }
  };

  const StatCard = ({
    title,
    value,
    change,
    changeType,
    icon: Icon,
    color = "blue",
  }: {
    title: string;
    value: number | string;
    change?: number;
    changeType?: "increase" | "decrease";
    icon: React.ComponentType<{ className?: string }>;
    color?: string;
  }) => {
    const colorClasses = {
      blue: "bg-blue-500",
      green: "bg-green-500",
      yellow: "bg-yellow-500",
      red: "bg-red-500",
      purple: "bg-purple-500",
    };

    return (
      <Card className="p-6">
        <div className="flex items-center">
          <div
            className={`p-3 rounded-md ${
              colorClasses[color as keyof typeof colorClasses]
            }`}
          >
            <Icon className="h-6 w-6 text-white" />
          </div>
          <div className="ml-4 flex-1">
            <p className="text-sm font-medium text-gray-500">{title}</p>
            <div className="flex items-baseline">
              <p className="text-2xl font-semibold text-gray-900">{value}</p>
              {change !== undefined && (
                <div className="ml-2 flex items-baseline text-sm">
                  {changeType === "increase" ? (
                    <ArrowUpIcon className="h-4 w-4 text-green-500" />
                  ) : (
                    <ArrowDownIcon className="h-4 w-4 text-red-500" />
                  )}
                  <span
                    className={`ml-1 font-medium ${
                      changeType === "increase"
                        ? "text-green-500"
                        : "text-red-500"
                    }`}
                  >
                    {Math.abs(change)}%
                  </span>
                </div>
              )}
            </div>
          </div>
        </div>
      </Card>
    );
  };

  const ActivityItem = ({
    activity,
  }: {
    activity: DashboardStats["recent_activity"][0];
  }) => {
    const getActivityIcon = (type: string) => {
      switch (type) {
        case "report":
          return "📄";
        case "match":
          return "🔗";
        case "user":
          return "👤";
        case "fraud":
          return "⚠️";
        default:
          return "📋";
      }
    };

    const getActivityColor = (type: string) => {
      switch (type) {
        case "report":
          return "blue";
        case "match":
          return "green";
        case "user":
          return "purple";
        case "fraud":
          return "red";
        default:
          return "gray";
      }
    };

    return (
      <div className="flex items-center space-x-3 py-3 border-b border-gray-100 last:border-b-0">
        <div className="flex-shrink-0">
          <span className="text-lg">{getActivityIcon(activity.type)}</span>
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-gray-900 truncate">
            {activity.action}
          </p>
          <p className="text-sm text-gray-500 truncate">{activity.details}</p>
        </div>
        <div className="flex-shrink-0">
          <Badge variant={getActivityColor(activity.type) as any}>
            {new Date(activity.timestamp).toLocaleDateString()}
          </Badge>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <AdminLayout title="Dashboard" description="Admin dashboard overview">
        <div className="flex items-center justify-center min-h-96">
          <LoadingSpinner size="lg" />
        </div>
      </AdminLayout>
    );
  }

  if (error) {
    return (
      <AdminLayout title="Dashboard" description="Admin dashboard overview">
        <div className="text-center py-12">
          <ExclamationTriangleIcon className="mx-auto h-12 w-12 text-red-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">
            Error loading dashboard
          </h3>
          <p className="mt-1 text-sm text-gray-500">{error}</p>
          <div className="mt-6">
            <button
              onClick={fetchDashboardData}
              className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Try again
            </button>
          </div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout title="Dashboard" description="Admin dashboard overview">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">
          Welcome to the Lost & Found admin panel. Here's an overview of your
          system.
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="Total Users"
          value={stats?.total_users || 0}
          change={12}
          changeType="increase"
          icon={UserGroupIcon}
          color="blue"
        />
        <StatCard
          title="Total Reports"
          value={stats?.total_reports || 0}
          change={8}
          changeType="increase"
          icon={DocumentTextIcon}
          color="green"
        />
        <StatCard
          title="Pending Reports"
          value={stats?.pending_reports || 0}
          icon={ClockIcon}
          color="yellow"
        />
        <StatCard
          title="Total Matches"
          value={stats?.total_matches || 0}
          change={15}
          changeType="increase"
          icon={ChartBarIcon}
          color="purple"
        />
      </div>

      {/* Additional Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <StatCard
          title="Pending Matches"
          value={stats?.pending_matches || 0}
          icon={ClockIcon}
          color="yellow"
        />
        <StatCard
          title="Fraud Detections"
          value={stats?.fraud_detections || 0}
          icon={ExclamationTriangleIcon}
          color="red"
        />
        <StatCard
          title="Pending Fraud Reviews"
          value={stats?.pending_fraud_reviews || 0}
          icon={ExclamationTriangleIcon}
          color="red"
        />
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card title="Recent Activity" subtitle="Latest system activities">
          <div className="space-y-0">
            {stats?.recent_activity && stats.recent_activity.length > 0 ? (
              stats.recent_activity
                .slice(0, 5)
                .map((activity, index) => (
                  <ActivityItem key={index} activity={activity} />
                ))
            ) : (
              <div className="text-center py-8 text-gray-500">
                <ClockIcon className="mx-auto h-8 w-8 text-gray-400 mb-2" />
                <p>No recent activity</p>
              </div>
            )}
          </div>
        </Card>

        <Card title="Quick Actions" subtitle="Common administrative tasks">
          <div className="space-y-3">
            <button
              onClick={() => handleQuickAction("reports")}
              className="w-full text-left px-4 py-3 border border-gray-200 rounded-lg hover:bg-blue-50 hover:border-blue-300 transition-all duration-200 group"
            >
              <div className="flex items-center">
                <DocumentTextIcon className="h-5 w-5 text-blue-500 mr-3 group-hover:text-blue-600" />
                <div>
                  <p className="font-medium text-gray-900 group-hover:text-blue-900">
                    Review Pending Reports
                  </p>
                  <p className="text-sm text-gray-500">
                    {stats?.pending_reports || 0} reports waiting
                  </p>
                </div>
              </div>
            </button>

            <button
              onClick={() => handleQuickAction("fraud")}
              className="w-full text-left px-4 py-3 border border-gray-200 rounded-lg hover:bg-red-50 hover:border-red-300 transition-all duration-200 group"
            >
              <div className="flex items-center">
                <ExclamationTriangleIcon className="h-5 w-5 text-red-500 mr-3 group-hover:text-red-600" />
                <div>
                  <p className="font-medium text-gray-900 group-hover:text-red-900">
                    Review Fraud Detections
                  </p>
                  <p className="text-sm text-gray-500">
                    {stats?.pending_fraud_reviews || 0} items flagged
                  </p>
                </div>
              </div>
            </button>

            <button
              onClick={() => handleQuickAction("matches")}
              className="w-full text-left px-4 py-3 border border-gray-200 rounded-lg hover:bg-green-50 hover:border-green-300 transition-all duration-200 group"
            >
              <div className="flex items-center">
                <ChartBarIcon className="h-5 w-5 text-green-500 mr-3 group-hover:text-green-600" />
                <div>
                  <p className="font-medium text-gray-900 group-hover:text-green-900">
                    Review Matches
                  </p>
                  <p className="text-sm text-gray-500">
                    {stats?.pending_matches || 0} matches pending
                  </p>
                </div>
              </div>
            </button>

            <button
              onClick={() => handleQuickAction("users")}
              className="w-full text-left px-4 py-3 border border-gray-200 rounded-lg hover:bg-purple-50 hover:border-purple-300 transition-all duration-200 group"
            >
              <div className="flex items-center">
                <UserGroupIcon className="h-5 w-5 text-purple-500 mr-3 group-hover:text-purple-600" />
                <div>
                  <p className="font-medium text-gray-900 group-hover:text-purple-900">
                    Manage Users
                  </p>
                  <p className="text-sm text-gray-500">
                    {stats?.total_users || 0} total users
                  </p>
                </div>
              </div>
            </button>
          </div>
        </Card>
      </div>
    </AdminLayout>
  );
};

export default Dashboard;
