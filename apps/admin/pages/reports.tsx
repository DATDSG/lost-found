import React, { useState, useEffect } from "react";
import type { NextPage } from "next";
import {
  DocumentTextIcon,
  MagnifyingGlassIcon,
  EyeIcon,
  PencilIcon,
  TrashIcon,
  CheckCircleIcon,
  XCircleIcon,
  ExclamationTriangleIcon,
  ClockIcon,
  FunnelIcon,
} from "@heroicons/react/24/outline";
import AdminLayout from "../components/AdminLayout";
import {
  Card,
  Button,
  Input,
  Select,
  Badge,
  LoadingSpinner,
  EmptyState,
} from "../components/ui";
import { Report, ReportFilters, PaginatedResponse } from "../types";
import apiService from "../services/api";

const Reports: NextPage = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 25,
    total: 0,
    totalPages: 0,
  });
  const [filters, setFilters] = useState<ReportFilters>({});
  const [selectedReports, setSelectedReports] = useState<string[]>([]);
  const [bulkAction, setBulkAction] = useState<string>("");

  useEffect(() => {
    fetchReports();
  }, [filters, pagination.page]);

  const fetchReports = async () => {
    try {
      setLoading(true);
      setError(null);
      const response: PaginatedResponse<Report> = await apiService.getReports(
        filters
      );
      setReports(response.items);
      setPagination((prev) => ({
        ...prev,
        total: response.total,
        totalPages: response.total_pages,
      }));
    } catch (err) {
      setError("Failed to load reports");
      console.error("Reports error:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key: keyof ReportFilters, value: string) => {
    setFilters((prev) => ({ ...prev, [key]: value || undefined }));
    setPagination((prev) => ({ ...prev, page: 1 }));
  };

  const handleBulkAction = async () => {
    if (!bulkAction || selectedReports.length === 0) return;

    try {
      // Update each report individually for now
      await Promise.all(
        selectedReports.map((reportId) =>
          apiService.updateReportStatus(reportId, bulkAction)
        )
      );
      setSelectedReports([]);
      setBulkAction("");
      fetchReports();
    } catch (err) {
      console.error("Bulk action error:", err);
    }
  };

  const handleReportStatusUpdate = async (reportId: string, status: string) => {
    try {
      await apiService.updateReportStatus(reportId, status);
      fetchReports();
    } catch (err) {
      console.error("Status update error:", err);
    }
  };

  const handleDeleteReport = async (reportId: string) => {
    if (!confirm("Are you sure you want to delete this report?")) return;

    try {
      await apiService.deleteReport(reportId);
      fetchReports();
    } catch (err) {
      console.error("Delete error:", err);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "approved":
        return "success";
      case "pending":
        return "warning";
      case "rejected":
        return "danger";
      case "resolved":
        return "info";
      case "hidden":
        return "default";
      default:
        return "default";
    }
  };

  const getFraudStatusColor = (status?: string) => {
    switch (status) {
      case "flagged":
        return "danger";
      case "clean":
        return "success";
      case "reviewed":
        return "info";
      case "false_positive":
        return "warning";
      case "rejected":
        return "danger";
      default:
        return "default";
    }
  };

  const statusOptions = [
    { value: "", label: "All Statuses" },
    { value: "pending", label: "Pending" },
    { value: "approved", label: "Approved" },
    { value: "rejected", label: "Rejected" },
    { value: "resolved", label: "Resolved" },
    { value: "hidden", label: "Hidden" },
  ];

  const typeOptions = [
    { value: "", label: "All Types" },
    { value: "lost", label: "Lost" },
    { value: "found", label: "Found" },
  ];

  const fraudStatusOptions = [
    { value: "", label: "All Fraud Statuses" },
    { value: "clean", label: "Clean" },
    { value: "flagged", label: "Flagged" },
    { value: "reviewed", label: "Reviewed" },
    { value: "false_positive", label: "False Positive" },
    { value: "rejected", label: "Rejected" },
  ];

  const bulkActionOptions = [
    { value: "", label: "Select Action" },
    { value: "approved", label: "Approve Selected" },
    { value: "rejected", label: "Reject Selected" },
    { value: "hidden", label: "Hide Selected" },
  ];

  return (
    <AdminLayout
      title="Reports Management"
      description="Manage and review all reports"
    >
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              Reports Management
            </h1>
            <p className="mt-2 text-gray-600">
              Review, approve, and manage all submitted reports
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <Badge variant="info">{pagination.total} total reports</Badge>
            <Button onClick={fetchReports} variant="secondary">
              <MagnifyingGlassIcon className="h-4 w-4 mr-2" />
              Refresh
            </Button>
          </div>
        </div>
      </div>

      {/* Filters */}
      <Card title="Filters" className="mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <Input
            label="Search"
            placeholder="Search reports..."
            value={filters.search || ""}
            onChange={(e) => handleFilterChange("search", e.target.value)}
          />

          <Select
            label="Status"
            options={statusOptions}
            value={filters.status || ""}
            onChange={(e) => handleFilterChange("status", e.target.value)}
          />

          <Select
            label="Type"
            options={typeOptions}
            value={filters.type || ""}
            onChange={(e) => handleFilterChange("type", e.target.value)}
          />

          <div className="flex items-end">
            <Button onClick={fetchReports} className="w-full">
              <FunnelIcon className="h-4 w-4 mr-2" />
              Apply Filters
            </Button>
          </div>
        </div>
      </Card>

      {/* Bulk Actions */}
      {selectedReports.length > 0 && (
        <Card className="mb-6 bg-blue-50 border-blue-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <span className="text-sm font-medium text-blue-900">
                {selectedReports.length} report(s) selected
              </span>
              <Select
                options={bulkActionOptions}
                value={bulkAction}
                onChange={(e) => setBulkAction(e.target.value)}
                className="w-48"
              />
            </div>
            <div className="flex items-center space-x-2">
              <Button
                onClick={handleBulkAction}
                disabled={!bulkAction}
                variant="primary"
              >
                Apply Action
              </Button>
              <Button
                onClick={() => setSelectedReports([])}
                variant="secondary"
              >
                Clear Selection
              </Button>
            </div>
          </div>
        </Card>
      )}

      {/* Reports Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <input
                    type="checkbox"
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    aria-label="Select all reports"
                    checked={
                      selectedReports.length === reports.length &&
                      reports.length > 0
                    }
                    onChange={(e) => {
                      if (e.target.checked) {
                        setSelectedReports(reports.map((r) => r.id));
                      } else {
                        setSelectedReports([]);
                      }
                    }}
                  />
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Report
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Owner
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fraud Status
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
                  <td colSpan={8} className="px-6 py-12 text-center">
                    <LoadingSpinner size="lg" />
                  </td>
                </tr>
              ) : reports.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center">
                    <EmptyState
                      title="No reports found"
                      description="Try adjusting your filters or check back later"
                      icon={
                        <DocumentTextIcon className="mx-auto h-12 w-12 text-gray-400" />
                      }
                    />
                  </td>
                </tr>
              ) : (
                reports.map((report) => (
                  <tr key={report.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <input
                        type="checkbox"
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        aria-label={`Select report ${report.title}`}
                        checked={selectedReports.includes(report.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedReports((prev) => [...prev, report.id]);
                          } else {
                            setSelectedReports((prev) =>
                              prev.filter((id) => id !== report.id)
                            );
                          }
                        }}
                      />
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className="flex-shrink-0">
                          <DocumentTextIcon className="h-8 w-8 text-gray-400" />
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {report.title}
                          </div>
                          <div className="text-sm text-gray-500">
                            {report.category} • {report.location_city}
                          </div>
                          {report.reward_offered && (
                            <div className="text-xs text-green-600">
                              Reward: ${report.reward_amount}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={getStatusColor(report.status) as any}>
                        {report.status}
                      </Badge>
                    </td>
                    <td className="px-6 py-4">
                      <Badge
                        variant={report.type === "lost" ? "warning" : "success"}
                      >
                        {report.type}
                      </Badge>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {report.owner?.display_name ||
                          `${report.owner?.first_name} ${report.owner?.last_name}`}
                      </div>
                      <div className="text-sm text-gray-500">
                        {report.owner?.email || report.owner_email}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {report.fraud_status ? (
                        <div className="space-y-1">
                          <Badge
                            variant={
                              getFraudStatusColor(report.fraud_status) as any
                            }
                          >
                            {report.fraud_status}
                          </Badge>
                          {report.fraud_score && (
                            <div className="text-xs text-gray-500">
                              Score:{" "}
                              {typeof report.fraud_score === "number" &&
                              !isNaN(report.fraud_score)
                                ? report.fraud_score.toFixed(1)
                                : "0.0"}
                              %
                            </div>
                          )}
                        </div>
                      ) : (
                        <span className="text-sm text-gray-400">
                          Not checked
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(report.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-2">
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => {
                            /* View details */
                          }}
                        >
                          <EyeIcon className="h-4 w-4" />
                        </Button>

                        {report.status === "pending" && (
                          <>
                            <Button
                              size="sm"
                              variant="success"
                              onClick={() =>
                                handleReportStatusUpdate(report.id, "approved")
                              }
                            >
                              <CheckCircleIcon className="h-4 w-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() =>
                                handleReportStatusUpdate(report.id, "rejected")
                              }
                            >
                              <XCircleIcon className="h-4 w-4" />
                            </Button>
                          </>
                        )}

                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => {
                            /* Edit report */
                          }}
                        >
                          <PencilIcon className="h-4 w-4" />
                        </Button>

                        <Button
                          size="sm"
                          variant="danger"
                          onClick={() => handleDeleteReport(report.id)}
                        >
                          <TrashIcon className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {pagination.totalPages > 1 && (
          <div className="px-6 py-4 border-t border-gray-200">
            <div className="flex items-center justify-between">
              <div className="text-sm text-gray-700">
                Showing {(pagination.page - 1) * pagination.limit + 1} to{" "}
                {Math.min(pagination.page * pagination.limit, pagination.total)}{" "}
                of {pagination.total} results
              </div>
              <div className="flex items-center space-x-2">
                <Button
                  variant="secondary"
                  size="sm"
                  disabled={pagination.page === 1}
                  onClick={() =>
                    setPagination((prev) => ({ ...prev, page: prev.page - 1 }))
                  }
                >
                  Previous
                </Button>
                <span className="text-sm text-gray-700">
                  Page {pagination.page} of {pagination.totalPages}
                </span>
                <Button
                  variant="secondary"
                  size="sm"
                  disabled={pagination.page === pagination.totalPages}
                  onClick={() =>
                    setPagination((prev) => ({ ...prev, page: prev.page + 1 }))
                  }
                >
                  Next
                </Button>
              </div>
            </div>
          </div>
        )}
      </Card>
    </AdminLayout>
  );
};

export default Reports;
