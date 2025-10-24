import React, { useState, useEffect } from "react";
import type { NextPage } from "next";
import {
  ChartBarIcon,
  MagnifyingGlassIcon,
  EyeIcon,
  CheckCircleIcon,
  XCircleIcon,
  ClockIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";
import AdminLayout from "../components/AdminLayout";
import {
  Card,
  Button,
  Select,
  Badge,
  LoadingSpinner,
  EmptyState,
} from "../components/ui";
import { Match, MatchFilters, PaginatedResponse } from "../types";
import apiService from "../services/api";

const Matching: NextPage = () => {
  const [matches, setMatches] = useState<Match[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<MatchFilters>({});

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [matchesResponse, statsResponse] = await Promise.all([
        apiService.getMatches(filters),
        apiService.getMatchStats(),
      ]);

      // Add safety checks for the data
      const safeMatches = (matchesResponse.items || []).map((match) => ({
        ...match,
        overall_score: match.overall_score ?? 0,
        source_report: match.source_report || {
          title: "Unknown",
          category: "Unknown",
          location_city: "Unknown",
          type: "Unknown",
        },
        candidate_report: match.candidate_report || {
          title: "Unknown",
          category: "Unknown",
          location_city: "Unknown",
          type: "Unknown",
        },
      }));

      setMatches(safeMatches);
      setStats(statsResponse);
    } catch (err) {
      setError("Failed to fetch matching data");
      console.error("Matching error:", err);
    } finally {
      setLoading(false);
    }
  };

  const updateMatchStatus = async (matchId: string, status: string) => {
    try {
      await apiService.updateMatchStatus(matchId, status);
      fetchData(); // Refresh data
    } catch (err) {
      console.error("Status update error:", err);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "promoted":
        return "success";
      case "candidate":
        return "warning";
      case "suppressed":
        return "danger";
      case "dismissed":
        return "info";
      default:
        return "default";
    }
  };

  const getSimilarityColor = (score: number) => {
    if (score >= 80) return "text-green-600";
    if (score >= 60) return "text-yellow-600";
    return "text-red-600";
  };

  const statusOptions = [
    { value: "", label: "All Status" },
    { value: "candidate", label: "Candidate" },
    { value: "promoted", label: "Promoted" },
    { value: "suppressed", label: "Suppressed" },
    { value: "dismissed", label: "Dismissed" },
  ];

  const similarityOptions = [
    { value: "", label: "All Similarity Scores" },
    { value: "90", label: "90%+ Similarity" },
    { value: "80", label: "80%+ Similarity" },
    { value: "70", label: "70%+ Similarity" },
    { value: "60", label: "60%+ Similarity" },
  ];

  return (
    <AdminLayout
      title="Matching Management"
      description="Manage and review matching results"
    >
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">
          Matching Management
        </h1>
        <p className="mt-2 text-gray-600">
          Review and manage matching results between reports
        </p>
      </div>

      {error && (
        <Card className="mb-6 bg-red-50 border-red-200">
          <div className="flex items-center">
            <ExclamationTriangleIcon className="h-5 w-5 text-red-400 mr-2" />
            <p className="text-red-800">{error}</p>
          </div>
        </Card>
      )}

      {/* Stats Cards */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6 mb-8">
          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-blue-500">
                <ChartBarIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">
                  Total Matches
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.total}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-yellow-500">
                <ClockIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Candidate</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.candidate}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-green-500">
                <CheckCircleIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Promoted</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.promoted}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-red-500">
                <XCircleIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Suppressed</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.suppressed}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-purple-500">
                <ExclamationTriangleIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">
                  Avg Similarity
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {typeof stats.avg_score === "number" &&
                  !isNaN(stats.avg_score)
                    ? stats.avg_score.toFixed(1)
                    : "0.0"}
                  %
                </p>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Filters */}
      <Card title="Filters" className="mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Select
            label="Status"
            options={statusOptions}
            value={filters.status || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                status: e.target.value || undefined,
              }))
            }
          />

          <Select
            label="Similarity Score"
            options={similarityOptions}
            value={filters.min_score ? filters.min_score.toString() : ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                min_score: e.target.value
                  ? parseInt(e.target.value)
                  : undefined,
              }))
            }
          />

          <div className="flex items-end">
            <Button onClick={fetchData} className="w-full">
              <MagnifyingGlassIcon className="h-5 w-5 inline mr-2" />
              Filter
            </Button>
          </div>
        </div>
      </Card>

      {/* Matches Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Source Report
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Candidate Report
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Similarity Score
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Created
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center">
                    <LoadingSpinner size="lg" />
                  </td>
                </tr>
              ) : matches.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center">
                    <EmptyState
                      title="No matches found"
                      description="Try adjusting your filters or check back later"
                      icon={
                        <ChartBarIcon className="mx-auto h-12 w-12 text-gray-400" />
                      }
                    />
                  </td>
                </tr>
              ) : (
                matches.map((match) => (
                  <tr key={match.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {match.source_report.title}
                        </div>
                        <div className="text-sm text-gray-500">
                          {match.source_report.category} •{" "}
                          {match.source_report.location_city}
                        </div>
                        <div className="text-xs text-gray-400">
                          {match.source_report.type}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {match.candidate_report.title}
                        </div>
                        <div className="text-sm text-gray-500">
                          {match.candidate_report.category} •{" "}
                          {match.candidate_report.location_city}
                        </div>
                        <div className="text-xs text-gray-400">
                          {match.candidate_report.type}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`text-sm font-medium ${getSimilarityColor(
                          match.overall_score ?? 0
                        )}`}
                      >
                        {typeof match.overall_score === "number" &&
                        !isNaN(match.overall_score)
                          ? (match.overall_score * 100).toFixed(1)
                          : "0.0"}
                        %
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={getStatusColor(match.status) as any}>
                        {match.status}
                      </Badge>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(match.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex space-x-2">
                        {match.status === "candidate" && (
                          <>
                            <Button
                              size="sm"
                              variant="success"
                              onClick={() =>
                                updateMatchStatus(match.id, "promoted")
                              }
                              title="Promote Match"
                            >
                              <CheckCircleIcon className="h-4 w-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() =>
                                updateMatchStatus(match.id, "suppressed")
                              }
                              title="Suppress Match"
                            >
                              <XCircleIcon className="h-4 w-4" />
                            </Button>
                          </>
                        )}
                        <Button
                          size="sm"
                          variant="secondary"
                          title="View Details"
                        >
                          <EyeIcon className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </AdminLayout>
  );
};

export default Matching;
