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
  MapPinIcon,
  UserIcon,
  CalendarIcon,
  TagIcon,
  CurrencyDollarIcon,
  ShieldCheckIcon,
  ShieldExclamationIcon,
  LinkIcon,
  ChartBarIcon,
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
  Modal,
  ImageGallery,
  StatusBadge,
} from "../components/ui";
import {
  Report,
  ReportFilters,
  PaginatedResponse,
  Match,
  FraudDetectionResult,
} from "../types";
import { apiService } from "../services/api";

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

  // Modal states
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [showReportModal, setShowReportModal] = useState(false);
  const [showMatchingModal, setShowMatchingModal] = useState(false);
  const [showFraudModal, setShowFraudModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [reportToDelete, setReportToDelete] = useState<string | null>(null);

  // Additional data states
  const [reportMatches, setReportMatches] = useState<Match[]>([]);
  const [fraudData, setFraudData] = useState<FraudDetectionResult | null>(null);
  const [loadingMatches, setLoadingMatches] = useState(false);
  const [loadingFraud, setLoadingFraud] = useState(false);

  useEffect(() => {
    fetchReports();
  }, [filters, pagination.page]);

  const fetchReports = async () => {
    try {
      setLoading(true);
      setError(null);
      const response: PaginatedResponse<Report> = await apiService.getReports({
        ...filters,
        page: pagination.page,
        limit: pagination.limit,
      });
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

  // Modal handlers
  const handleViewReport = async (report: Report) => {
    setSelectedReport(report);
    setShowReportModal(true);
  };

  const handleViewMatching = async (report: Report) => {
    setSelectedReport(report);
    setLoadingMatches(true);
    setShowMatchingModal(true);

    try {
      // Fetch matches for this report
      const matches = await apiService.getMatches({});
      setReportMatches(matches.items || []);
    } catch (err) {
      console.error("Error fetching matches:", err);
      setReportMatches([]);
    } finally {
      setLoadingMatches(false);
    }
  };

  const handleViewFraudDetection = async (report: Report) => {
    setSelectedReport(report);
    setLoadingFraud(true);
    setShowFraudModal(true);

    try {
      // Fetch fraud detection data for this report
      const fraudResults = await apiService.getFraudReports({});
      setFraudData(fraudResults.items?.[0] || null);
    } catch (err) {
      console.error("Error fetching fraud data:", err);
      setFraudData(null);
    } finally {
      setLoadingFraud(false);
    }
  };

  const handleDeleteClick = (reportId: string) => {
    setReportToDelete(reportId);
    setShowDeleteModal(true);
  };

  const confirmDelete = async () => {
    if (!reportToDelete) return;

    try {
      await apiService.deleteReport(reportToDelete);
      setShowDeleteModal(false);
      setReportToDelete(null);
      fetchReports();
    } catch (err) {
      console.error("Delete error:", err);
    }
  };

  const handleFilterChange = (key: keyof ReportFilters, value: string) => {
    setFilters((prev) => ({ ...prev, [key]: value || undefined }));
    setPagination((prev) => ({ ...prev, page: 1 }));
  };

  const handleBulkAction = async () => {
    if (!bulkAction || selectedReports.length === 0) return;

    try {
      await Promise.all(
        selectedReports.map((reportId) =>
          apiService.updateReport(reportId, { status: bulkAction })
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
      await apiService.updateReport(reportId, { status });
      fetchReports();
    } catch (err) {
      console.error("Status update error:", err);
    }
  };

  // Helper functions
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const getStatusActions = (report: Report) => {
    const actions = [];

    if (report.status === "pending") {
      actions.push(
        <Button
          key="approve"
          size="sm"
          variant="success"
          onClick={() => handleReportStatusUpdate(report.id, "approved")}
          className="mr-1"
        >
          <CheckCircleIcon className="h-4 w-4 mr-1" />
          Approve
        </Button>
      );
      actions.push(
        <Button
          key="reject"
          size="sm"
          variant="danger"
          onClick={() => handleReportStatusUpdate(report.id, "rejected")}
          className="mr-1"
        >
          <XCircleIcon className="h-4 w-4 mr-1" />
          Reject
        </Button>
      );
    }

    if (report.status === "approved") {
      actions.push(
        <Button
          key="resolve"
          size="sm"
          variant="info"
          onClick={() => handleReportStatusUpdate(report.id, "resolved")}
          className="mr-1"
        >
          <CheckCircleIcon className="h-4 w-4 mr-1" />
          Mark Resolved
        </Button>
      );
    }

    return actions;
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
                  Report Details
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Owner
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
              ) : reports.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center">
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
                      <div className="flex items-start space-x-4">
                        <div className="flex-shrink-0">
                          <div className="h-12 w-12 bg-gray-100 rounded-lg flex items-center justify-center">
                            <DocumentTextIcon className="h-6 w-6 text-gray-400" />
                          </div>
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="text-sm font-medium text-gray-900 truncate">
                            {report.title}
                          </div>
                          <div className="text-sm text-gray-500 flex items-center mt-1">
                            <TagIcon className="h-4 w-4 mr-1" />
                            {report.category}
                          </div>
                          <div className="text-sm text-gray-500 flex items-center mt-1">
                            <MapPinIcon className="h-4 w-4 mr-1" />
                            {report.location_city}
                          </div>
                          <div className="flex items-center space-x-2 mt-2">
                            <StatusBadge status={report.type} />
                            {report.reward_offered && (
                              <div className="flex items-center text-xs text-green-600">
                                <CurrencyDollarIcon className="h-3 w-3 mr-1" />$
                                {report.reward_amount}
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="space-y-2">
                        <StatusBadge status={report.status} />
                        {report.fraud_status && (
                          <div className="flex items-center space-x-1">
                            {report.fraud_status === "flagged" ? (
                              <ShieldExclamationIcon className="h-4 w-4 text-red-500" />
                            ) : (
                              <ShieldCheckIcon className="h-4 w-4 text-green-500" />
                            )}
                            <StatusBadge status={report.fraud_status} />
                          </div>
                        )}
                      </div>
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
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {formatDate(report.created_at)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-1">
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => handleViewReport(report)}
                          title="View Details"
                        >
                          <EyeIcon className="h-4 w-4" />
                        </Button>

                        <Button
                          size="sm"
                          variant="info"
                          onClick={() => handleViewMatching(report)}
                          title="View Matching Process"
                        >
                          <LinkIcon className="h-4 w-4" />
                        </Button>

                        <Button
                          size="sm"
                          variant="warning"
                          onClick={() => handleViewFraudDetection(report)}
                          title="View Fraud Detection"
                        >
                          <ShieldExclamationIcon className="h-4 w-4" />
                        </Button>

                        {getStatusActions(report)}

                        <Button
                          size="sm"
                          variant="danger"
                          onClick={() => handleDeleteClick(report.id)}
                          title="Delete Report"
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

      {/* Report Details Modal */}
      <Modal
        isOpen={showReportModal}
        onClose={() => setShowReportModal(false)}
        title="Report Details"
        size="2xl"
      >
        {selectedReport && (
          <div className="space-y-6">
            {/* Report Header */}
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-xl font-semibold text-gray-900">
                    {selectedReport.title}
                  </h3>
                  <div className="flex items-center space-x-4 mt-2">
                    <StatusBadge status={selectedReport.status} />
                    <StatusBadge status={selectedReport.type} />
                    {selectedReport.fraud_status && (
                      <StatusBadge status={selectedReport.fraud_status} />
                    )}
                  </div>
                </div>
                <div className="text-right text-sm text-gray-500">
                  <div className="flex items-center">
                    <CalendarIcon className="h-4 w-4 mr-1" />
                    {formatDate(selectedReport.created_at)}
                  </div>
                </div>
              </div>
            </div>

            {/* Report Content */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div>
                  <h4 className="text-sm font-medium text-gray-900 mb-2">
                    Description
                  </h4>
                  <p className="text-sm text-gray-700 bg-gray-50 p-3 rounded-lg">
                    {selectedReport.description}
                  </p>
                </div>

                <div>
                  <h4 className="text-sm font-medium text-gray-900 mb-2">
                    Category & Location
                  </h4>
                  <div className="space-y-2">
                    <div className="flex items-center text-sm text-gray-700">
                      <TagIcon className="h-4 w-4 mr-2 text-gray-400" />
                      {selectedReport.category}
                    </div>
                    <div className="flex items-center text-sm text-gray-700">
                      <MapPinIcon className="h-4 w-4 mr-2 text-gray-400" />
                      {selectedReport.location_city}
                      {selectedReport.location_address && (
                        <span className="ml-2 text-gray-500">
                          - {selectedReport.location_address}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {selectedReport.reward_offered && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-2">
                      Reward Information
                    </h4>
                    <div className="flex items-center text-sm text-green-600 bg-green-50 p-3 rounded-lg">
                      <CurrencyDollarIcon className="h-4 w-4 mr-2" />$
                      {selectedReport.reward_amount} reward offered
                    </div>
                  </div>
                )}
              </div>

              <div className="space-y-4">
                <div>
                  <h4 className="text-sm font-medium text-gray-900 mb-2">
                    Owner Information
                  </h4>
                  <div className="bg-gray-50 p-3 rounded-lg">
                    <div className="text-sm text-gray-900">
                      {selectedReport.owner?.display_name ||
                        `${selectedReport.owner?.first_name} ${selectedReport.owner?.last_name}`}
                    </div>
                    <div className="text-sm text-gray-500">
                      {selectedReport.owner?.email ||
                        selectedReport.owner_email}
                    </div>
                  </div>
                </div>

                <div>
                  <h4 className="text-sm font-medium text-gray-900 mb-2">
                    Images
                  </h4>
                  <ImageGallery images={selectedReport.images || []} />
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex items-center justify-end space-x-3 pt-4 border-t border-gray-200">
              {getStatusActions(selectedReport)}
              <Button
                variant="danger"
                onClick={() => {
                  setShowReportModal(false);
                  handleDeleteClick(selectedReport.id);
                }}
              >
                <TrashIcon className="h-4 w-4 mr-2" />
                Delete Report
              </Button>
            </div>
          </div>
        )}
      </Modal>

      {/* Matching Process Modal */}
      <Modal
        isOpen={showMatchingModal}
        onClose={() => setShowMatchingModal(false)}
        title="Matching Process Analysis"
        size="2xl"
      >
        {selectedReport && (
          <div className="space-y-6">
            <div className="bg-blue-50 rounded-lg p-4">
              <h3 className="text-lg font-semibold text-blue-900 mb-2">
                Matching Analysis for: {selectedReport.title}
              </h3>
              <p className="text-sm text-blue-700">
                This report has been analyzed against all other reports to find
                potential matches.
              </p>
            </div>

            {loadingMatches ? (
              <div className="text-center py-8">
                <LoadingSpinner size="lg" />
                <p className="mt-2 text-gray-500">Loading matching data...</p>
              </div>
            ) : reportMatches.length === 0 ? (
              <div className="text-center py-8">
                <LinkIcon className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-2 text-lg font-medium text-gray-900">
                  No Matches Found
                </h3>
                <p className="mt-1 text-gray-500">
                  This report doesn't have any potential matches at this time.
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                <h4 className="text-lg font-medium text-gray-900">
                  Found {reportMatches.length} Potential Match(es)
                </h4>
                {reportMatches.map((match) => (
                  <div
                    key={match.id}
                    className="border border-gray-200 rounded-lg p-4"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <h5 className="text-sm font-medium text-gray-900">
                          Match Score: {match.overall_score?.toFixed(1)}%
                        </h5>
                        <div className="mt-2 grid grid-cols-2 gap-4 text-xs text-gray-600">
                          {match.text_score && (
                            <div>
                              Text Similarity: {match.text_score.toFixed(1)}%
                            </div>
                          )}
                          {match.image_score && (
                            <div>
                              Image Similarity: {match.image_score.toFixed(1)}%
                            </div>
                          )}
                          {match.geo_score && (
                            <div>
                              Location Similarity: {match.geo_score.toFixed(1)}%
                            </div>
                          )}
                          {match.time_score && (
                            <div>
                              Time Similarity: {match.time_score.toFixed(1)}%
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="ml-4">
                        <StatusBadge status={match.status} />
                      </div>
                    </div>
                    <div className="mt-3 pt-3 border-t border-gray-100">
                      <div className="text-sm text-gray-700">
                        <strong>Matched Report:</strong>{" "}
                        {match.candidate_report?.title}
                      </div>
                      <div className="text-xs text-gray-500 mt-1">
                        Category: {match.candidate_report?.category} • Location:{" "}
                        {match.candidate_report?.location_city}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </Modal>

      {/* Fraud Detection Modal */}
      <Modal
        isOpen={showFraudModal}
        onClose={() => setShowFraudModal(false)}
        title="Fraud Detection Analysis"
        size="2xl"
      >
        {selectedReport && (
          <div className="space-y-6">
            <div className="bg-red-50 rounded-lg p-4">
              <h3 className="text-lg font-semibold text-red-900 mb-2">
                Fraud Detection Analysis for: {selectedReport.title}
              </h3>
              <p className="text-sm text-red-700">
                This report has been analyzed for potential fraud indicators.
              </p>
            </div>

            {loadingFraud ? (
              <div className="text-center py-8">
                <LoadingSpinner size="lg" />
                <p className="mt-2 text-gray-500">
                  Loading fraud detection data...
                </p>
              </div>
            ) : fraudData ? (
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="bg-gray-50 rounded-lg p-4 text-center">
                    <div className="text-2xl font-bold text-gray-900">
                      {fraudData.fraud_score?.toFixed(1)}%
                    </div>
                    <div className="text-sm text-gray-600">Fraud Score</div>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4 text-center">
                    <div className="text-lg font-semibold text-gray-900 capitalize">
                      {fraudData.risk_level}
                    </div>
                    <div className="text-sm text-gray-600">Risk Level</div>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4 text-center">
                    <div className="text-lg font-semibold text-gray-900">
                      {fraudData.confidence?.toFixed(1)}%
                    </div>
                    <div className="text-sm text-gray-600">Confidence</div>
                  </div>
                </div>

                {fraudData.flags && fraudData.flags.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-2">
                      Fraud Flags
                    </h4>
                    <div className="space-y-2">
                      {fraudData.flags.map((flag, index) => (
                        <div
                          key={index}
                          className="flex items-center text-sm text-red-600 bg-red-50 p-2 rounded"
                        >
                          <ExclamationTriangleIcon className="h-4 w-4 mr-2" />
                          {flag}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <div>
                  <h4 className="text-sm font-medium text-gray-900 mb-2">
                    Analysis Details
                  </h4>
                  <div className="bg-gray-50 p-3 rounded-lg text-sm text-gray-700">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <strong>Reviewed:</strong>{" "}
                        {fraudData.is_reviewed ? "Yes" : "No"}
                      </div>
                      <div>
                        <strong>Confirmed Fraud:</strong>{" "}
                        {fraudData.is_confirmed_fraud ? "Yes" : "No"}
                      </div>
                      <div>
                        <strong>Detected At:</strong>{" "}
                        {fraudData.detected_at
                          ? formatDate(fraudData.detected_at)
                          : "N/A"}
                      </div>
                      <div>
                        <strong>Reviewed At:</strong>{" "}
                        {fraudData.reviewed_at
                          ? formatDate(fraudData.reviewed_at)
                          : "Not reviewed"}
                      </div>
                    </div>
                  </div>
                </div>

                {fraudData.admin_notes && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-2">
                      Admin Notes
                    </h4>
                    <div className="bg-blue-50 p-3 rounded-lg text-sm text-gray-700">
                      {fraudData.admin_notes}
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-center py-8">
                <ShieldCheckIcon className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-2 text-lg font-medium text-gray-900">
                  No Fraud Analysis Available
                </h3>
                <p className="mt-1 text-gray-500">
                  This report hasn't been analyzed for fraud yet.
                </p>
              </div>
            )}
          </div>
        )}
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        title="Delete Report"
        size="md"
      >
        <div className="space-y-4">
          <div className="flex items-center space-x-3">
            <div className="flex-shrink-0">
              <div className="h-10 w-10 bg-red-100 rounded-full flex items-center justify-center">
                <ExclamationTriangleIcon className="h-6 w-6 text-red-600" />
              </div>
            </div>
            <div>
              <h3 className="text-lg font-medium text-gray-900">
                Are you sure?
              </h3>
              <p className="text-sm text-gray-500">
                This action cannot be undone. The report will be permanently
                deleted.
              </p>
            </div>
          </div>

          <div className="flex items-center justify-end space-x-3 pt-4">
            <Button
              variant="secondary"
              onClick={() => setShowDeleteModal(false)}
            >
              Cancel
            </Button>
            <Button variant="danger" onClick={confirmDelete}>
              <TrashIcon className="h-4 w-4 mr-2" />
              Delete Report
            </Button>
          </div>
        </div>
      </Modal>
    </AdminLayout>
  );
};

export default Reports;
