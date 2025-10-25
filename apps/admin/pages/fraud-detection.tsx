import React, { useState, useEffect } from "react";
import type { NextPage } from "next";
import {
  ExclamationTriangleIcon,
  MagnifyingGlassIcon,
  PlayIcon,
  ChartBarIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon,
  EyeIcon,
} from "@heroicons/react/24/outline";
import AdminLayout from "../components/AdminLayout";
import {
  Card,
  Button,
  Select,
  Badge,
  LoadingSpinner,
  EmptyState,
  Modal,
} from "../components/ui";
import {
  FraudDetectionResult,
  FraudFilters,
  PaginatedResponse,
} from "../types";
import { apiService } from "../services/api";

const FraudDetection: NextPage = () => {
  const [results, setResults] = useState<FraudDetectionResult[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [analyzing, setAnalyzing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<FraudFilters>({});
  const [selectedResult, setSelectedResult] =
    useState<FraudDetectionResult | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [resultsResponse, statsResponse] = await Promise.all([
        apiService.getFraudReports(filters),
        apiService.getStatistics(),
      ]);

      setResults(resultsResponse.items);
      setStats(statsResponse);
    } catch (err) {
      setError("Failed to fetch fraud detection data");
      console.error("Fraud detection error:", err);
    } finally {
      setLoading(false);
    }
  };

  const runAnalysis = async () => {
    try {
      setAnalyzing(true);
      setError(null);
      // This would trigger a full system analysis
      await fetchData(); // Refresh data after analysis
    } catch (err) {
      setError("Failed to run fraud analysis");
      console.error("Analysis error:", err);
    } finally {
      setAnalyzing(false);
    }
  };

  const reviewResult = async (resultId: string, isConfirmed: boolean) => {
    try {
      await apiService.flagReport(
        resultId,
        isConfirmed ? "confirmed" : "rejected"
      );
      fetchData(); // Refresh data
    } catch (err) {
      console.error("Review error:", err);
    }
  };

  const handleViewDetails = (result: FraudDetectionResult) => {
    setSelectedResult(result);
    setShowDetailsModal(true);
  };

  const getRiskLevelColor = (level: string) => {
    switch (level) {
      case "critical":
        return "danger";
      case "high":
        return "danger";
      case "medium":
        return "warning";
      case "low":
        return "success";
      default:
        return "default";
    }
  };

  const getScoreColor = (score: number) => {
    if (score >= 80) return "text-red-600";
    if (score >= 60) return "text-orange-600";
    if (score >= 30) return "text-yellow-600";
    return "text-green-600";
  };

  const riskLevelOptions = [
    { value: "", label: "All Risk Levels" },
    { value: "critical", label: "Critical" },
    { value: "high", label: "High" },
    { value: "medium", label: "Medium" },
    { value: "low", label: "Low" },
  ];

  const reviewStatusOptions = [
    { value: "", label: "All Status" },
    { value: "false", label: "Pending Review" },
    { value: "true", label: "Reviewed" },
  ];

  return (
    <AdminLayout
      title="Fraud Detection"
      description="Monitor and manage fraud detection results"
    >
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              Fraud Detection
            </h1>
            <p className="mt-2 text-gray-600">
              Monitor and manage fraud detection results
            </p>
          </div>
          <Button
            onClick={runAnalysis}
            disabled={analyzing}
            loading={analyzing}
          >
            <PlayIcon className="h-5 w-5 mr-2" />
            {analyzing ? "Analyzing..." : "Run Analysis"}
          </Button>
        </div>
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
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-blue-500">
                <ChartBarIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">
                  Total Detections
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.total_detections || 0}
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
                <p className="text-sm font-medium text-gray-500">
                  Pending Review
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.pending_review || 0}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-red-500">
                <ExclamationTriangleIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">
                  Confirmed Fraud
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.confirmed_fraud || 0}
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
                <p className="text-sm font-medium text-gray-500">
                  Accuracy Rate
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.accuracy_rate || 0}%
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
            label="Risk Level"
            options={riskLevelOptions}
            value={filters.risk_level || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                risk_level: e.target.value || undefined,
              }))
            }
          />

          <Select
            label="Review Status"
            options={reviewStatusOptions}
            value={filters.is_reviewed ? filters.is_reviewed.toString() : ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                is_reviewed: e.target.value
                  ? e.target.value === "true"
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

      {/* Results Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Report ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Risk Level
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fraud Score
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Confidence
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Flags
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Detected
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
              ) : results.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center">
                    <EmptyState
                      title="No fraud detection results found"
                      description="Try adjusting your filters or run a new analysis"
                      icon={
                        <ExclamationTriangleIcon className="mx-auto h-12 w-12 text-gray-400" />
                      }
                    />
                  </td>
                </tr>
              ) : (
                results.map((result) => (
                  <tr key={result.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">
                        {result.report_id.substring(0, 8)}...
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <Badge
                        variant={getRiskLevelColor(result.risk_level) as any}
                      >
                        {result.risk_level}
                      </Badge>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`text-sm font-medium ${getScoreColor(
                          result.fraud_score ?? 0
                        )}`}
                      >
                        {typeof result.fraud_score === "number" &&
                        !isNaN(result.fraud_score)
                          ? result.fraud_score.toFixed(1)
                          : "0.0"}
                        %
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-900">
                        {typeof result.confidence === "number" &&
                        !isNaN(result.confidence)
                          ? (result.confidence * 100).toFixed(1)
                          : "0.0"}
                        %
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {(result.flags || []).length} flags
                        {(result.flags || []).length > 0 && (
                          <div className="text-xs text-gray-500 mt-1">
                            {(result.flags || []).slice(0, 2).join(", ")}
                            {(result.flags || []).length > 2 && "..."}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {result.is_reviewed ? (
                        <Badge
                          variant={
                            result.is_confirmed_fraud ? "danger" : "success"
                          }
                        >
                          {result.is_confirmed_fraud
                            ? "Confirmed"
                            : "False Positive"}
                        </Badge>
                      ) : (
                        <Badge variant="warning">Pending Review</Badge>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {result.detected_at
                        ? new Date(result.detected_at).toLocaleDateString()
                        : "N/A"}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex space-x-2">
                        {!result.is_reviewed && (
                          <>
                            <Button
                              size="sm"
                              variant="success"
                              onClick={() => reviewResult(result.id, true)}
                              title="Confirm Fraud"
                            >
                              <CheckCircleIcon className="h-4 w-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="warning"
                              onClick={() => reviewResult(result.id, false)}
                              title="Mark as False Positive"
                            >
                              <XCircleIcon className="h-4 w-4" />
                            </Button>
                          </>
                        )}
                        <Button
                          size="sm"
                          variant="secondary"
                          title="View Details"
                          onClick={() => handleViewDetails(result)}
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

      {/* Fraud Detection Details Modal */}
      {selectedResult && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="Fraud Detection Details"
        >
          <div className="space-y-6">
            {/* Detection Overview */}
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                Detection Information
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Detection ID
                  </p>
                  <p className="text-sm text-gray-900 font-mono">
                    {selectedResult.id}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Report ID</p>
                  <p className="text-sm text-gray-900 font-mono">
                    {selectedResult.report_id}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Risk Level
                  </p>
                  <Badge
                    variant={
                      getRiskLevelColor(selectedResult.risk_level) as any
                    }
                  >
                    {selectedResult.risk_level}
                  </Badge>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Fraud Score
                  </p>
                  <p
                    className={`text-sm font-semibold ${getScoreColor(
                      selectedResult.fraud_score
                    )}`}
                  >
                    {selectedResult.fraud_score}%
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Confidence
                  </p>
                  <p className="text-sm text-gray-900">
                    {selectedResult.confidence
                      ? `${selectedResult.confidence}%`
                      : "N/A"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Status</p>
                  <Badge
                    variant={
                      selectedResult.is_reviewed
                        ? selectedResult.is_confirmed_fraud
                          ? "danger"
                          : "success"
                        : "warning"
                    }
                  >
                    {selectedResult.is_reviewed
                      ? selectedResult.is_confirmed_fraud
                        ? "Confirmed Fraud"
                        : "False Positive"
                      : "Pending Review"}
                  </Badge>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Detected At
                  </p>
                  <p className="text-sm text-gray-900">
                    {selectedResult.detected_at
                      ? new Date(selectedResult.detected_at).toLocaleString()
                      : "N/A"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Created At
                  </p>
                  <p className="text-sm text-gray-900">
                    {new Date(selectedResult.created_at).toLocaleString()}
                  </p>
                </div>
              </div>
            </div>

            {/* Flags */}
            {selectedResult.flags && selectedResult.flags.length > 0 && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                  Detection Flags
                </h3>
                <div className="bg-red-50 p-4 rounded-lg">
                  <div className="flex flex-wrap gap-2">
                    {selectedResult.flags.map((flag, index) => (
                      <Badge key={index} variant="danger">
                        {flag}
                      </Badge>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Report Information */}
            {selectedResult.report && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                  Report Information
                </h3>
                <div className="bg-blue-50 p-4 rounded-lg">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm font-medium text-gray-500">Title</p>
                      <p className="text-sm text-gray-900">
                        {selectedResult.report.title}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-500">Type</p>
                      <p className="text-sm text-gray-900">
                        {selectedResult.report.type}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-500">
                        Category
                      </p>
                      <p className="text-sm text-gray-900">
                        {selectedResult.report.category}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-500">
                        Location
                      </p>
                      <p className="text-sm text-gray-900">
                        {selectedResult.report.location_city}
                      </p>
                    </div>
                  </div>
                  {selectedResult.report.description && (
                    <div className="mt-3">
                      <p className="text-sm font-medium text-gray-500">
                        Description
                      </p>
                      <p className="text-sm text-gray-900">
                        {selectedResult.report.description}
                      </p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Admin Notes */}
            {selectedResult.admin_notes && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                  Admin Notes
                </h3>
                <div className="bg-yellow-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-900">
                    {selectedResult.admin_notes}
                  </p>
                </div>
              </div>
            )}

            {/* Review Information */}
            {selectedResult.is_reviewed && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                  Review Information
                </h3>
                <div className="bg-green-50 p-4 rounded-lg">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm font-medium text-gray-500">
                        Reviewed By
                      </p>
                      <p className="text-sm text-gray-900">
                        {selectedResult.reviewed_by || "N/A"}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-500">
                        Reviewed At
                      </p>
                      <p className="text-sm text-gray-900">
                        {selectedResult.reviewed_at
                          ? new Date(
                              selectedResult.reviewed_at
                            ).toLocaleString()
                          : "N/A"}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Actions */}
            <div className="flex justify-end space-x-3 pt-4 border-t">
              <Button
                variant="secondary"
                onClick={() => setShowDetailsModal(false)}
              >
                Close
              </Button>
              {!selectedResult.is_reviewed && (
                <>
                  <Button
                    variant="success"
                    onClick={() => {
                      reviewResult(selectedResult.id, true);
                      setShowDetailsModal(false);
                    }}
                  >
                    <CheckCircleIcon className="h-4 w-4 mr-2" />
                    Confirm Fraud
                  </Button>
                  <Button
                    variant="warning"
                    onClick={() => {
                      reviewResult(selectedResult.id, false);
                      setShowDetailsModal(false);
                    }}
                  >
                    <XCircleIcon className="h-4 w-4 mr-2" />
                    Mark as False Positive
                  </Button>
                </>
              )}
            </div>
          </div>
        </Modal>
      )}
    </AdminLayout>
  );
};

export default FraudDetection;
