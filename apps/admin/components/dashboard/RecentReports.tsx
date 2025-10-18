"use client";

import { useQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api";
import Link from "next/link";
import { formatDistanceToNow } from "date-fns";

interface Report {
  id: string;
  title: string;
  type: "lost" | "found";
  status: "pending" | "approved" | "hidden" | "removed" | "rejected";
  category: string;
  location_city: string;
  created_at: string;
  media: Array<{ url: string }>;
}

export function RecentReports() {
  const { data: reports, isLoading } = useQuery<Report[]>(
    "recent-reports",
    async () => {
      const result = await apiClient.getReports({ skip: "0", limit: "5" });
      return result.items || [];
    }
  );

  if (isLoading) {
    return (
      <div className="card p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-3">
            {[...Array(3)].map((_, i) => (
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
        <h3 className="text-lg font-medium text-gray-900">Recent Reports</h3>
        <Link
          href="/reports"
          className="text-sm text-primary-600 hover:text-primary-500"
        >
          View all
        </Link>
      </div>

      <div className="space-y-3">
        {reports?.map((report) => (
          <div
            key={report.id}
            className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg"
          >
            {report.media?.[0] && (
              <img
                src={report.media[0].url}
                alt={report.title}
                className="h-10 w-10 rounded-lg object-cover"
              />
            )}
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">
                {report.title}
              </p>
              <div className="flex items-center space-x-2 text-xs text-gray-500">
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    report.type === "lost"
                      ? "bg-red-100 text-red-800"
                      : "bg-green-100 text-green-800"
                  }`}
                >
                  {report.type}
                </span>
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    report.status === "approved"
                      ? "bg-green-100 text-green-800"
                      : report.status === "pending"
                      ? "bg-yellow-100 text-yellow-800"
                      : "bg-gray-100 text-gray-800"
                  }`}
                >
                  {report.status}
                </span>
                <span>{report.location_city}</span>
              </div>
            </div>
            <div className="text-xs text-gray-400">
              {report.created_at
                ? formatDistanceToNow(new Date(report.created_at), {
                    addSuffix: true,
                  })
                : "Unknown"}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
