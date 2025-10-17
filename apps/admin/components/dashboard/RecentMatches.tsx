"use client";

import { useQuery } from "react-query";
import apiClient from "@/lib/api";
import Link from "next/link";
import { formatDistanceToNow } from "date-fns";

interface Match {
  id: string;
  score_total: number;
  status: "candidate" | "promoted" | "suppressed" | "dismissed";
  created_at: string;
  source_report: {
    id: string;
    title: string;
    type: "lost" | "found";
    media: Array<{ url: string }>;
  };
  candidate_report: {
    id: string;
    title: string;
    type: "lost" | "found";
    media: Array<{ url: string }>;
  };
}

export function RecentMatches() {
  const { data: matches, isLoading } = useQuery<Match[]>(
    "recent-matches",
    async () => {
      const result = await apiClient.getMatches({ skip: "0", limit: "5" });
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
              <div key={i} className="h-20 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-medium text-gray-900">Recent Matches</h3>
        <Link
          href="/matches"
          className="text-sm text-primary-600 hover:text-primary-500"
        >
          View all
        </Link>
      </div>

      <div className="space-y-4">
        {matches?.map((match) => (
          <div
            key={match.id}
            className="flex items-center space-x-4 p-4 bg-gray-50 rounded-lg"
          >
            {/* Source Report */}
            <div className="flex items-center space-x-2">
              {match.source_report.media?.[0] && (
                <img
                  src={match.source_report.media[0].url}
                  alt={match.source_report.title}
                  className="h-12 w-12 rounded-lg object-cover"
                />
              )}
              <div>
                <p className="text-sm font-medium text-gray-900 truncate max-w-32">
                  {match.source_report.title}
                </p>
                <span
                  className={`text-xs px-2 py-1 rounded-full ${
                    match.source_report.type === "lost"
                      ? "bg-red-100 text-red-800"
                      : "bg-green-100 text-green-800"
                  }`}
                >
                  {match.source_report.type}
                </span>
              </div>
            </div>

            {/* Match Score */}
            <div className="flex flex-col items-center">
              <div className="text-lg font-bold text-primary-600">
                {Math.round(match.score_total * 100)}%
              </div>
              <span
                className={`text-xs px-2 py-1 rounded-full ${
                  match.status === "promoted"
                    ? "bg-green-100 text-green-800"
                    : match.status === "candidate"
                    ? "bg-blue-100 text-blue-800"
                    : "bg-gray-100 text-gray-800"
                }`}
              >
                {match.status}
              </span>
            </div>

            {/* Candidate Report */}
            <div className="flex items-center space-x-2">
              <div>
                <p className="text-sm font-medium text-gray-900 truncate max-w-32">
                  {match.candidate_report.title}
                </p>
                <span
                  className={`text-xs px-2 py-1 rounded-full ${
                    match.candidate_report.type === "lost"
                      ? "bg-red-100 text-red-800"
                      : "bg-green-100 text-green-800"
                  }`}
                >
                  {match.candidate_report.type}
                </span>
              </div>
              {match.candidate_report.media?.[0] && (
                <img
                  src={match.candidate_report.media[0].url}
                  alt={match.candidate_report.title}
                  className="h-12 w-12 rounded-lg object-cover"
                />
              )}
            </div>

            <div className="text-xs text-gray-400 ml-auto">
              {formatDistanceToNow(new Date(match.created_at), {
                addSuffix: true,
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
