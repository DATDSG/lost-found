"use client";

import { useState } from "react";
import { formatDistanceToNow } from "date-fns";
import {
  EyeIcon,
  CheckIcon,
  XMarkIcon,
  EyeSlashIcon,
  TrashIcon,
  ExclamationTriangleIcon,
  UserIcon,
  MapPinIcon,
  CalendarIcon,
  TagIcon,
  PhotoIcon,
} from "@heroicons/react/24/outline";
import { useMutation, useQueryClient } from "react-query";
import apiClient from "@/lib/api";
import { toast } from "react-toastify";

interface Report {
  id: string;
  title: string;
  description: string;
  type: "lost" | "found";
  status: "pending" | "approved" | "hidden" | "removed" | "rejected";
  category: string;
  colors: string[];
  location_city: string;
  location_address: string;
  location_coordinates: any;
  occurred_at: string;
  created_at: string;
  updated_at: string;
  reward_offered: boolean;
  reward_amount: number;
  is_resolved: boolean;
  resolution_notes: string;
  moderation_notes: string;
  flags: string[];
  owner: {
    id: string;
    email: string;
    display_name: string;
    phone_number: string;
    created_at: string;
    status: string;
  };
  media: Array<{
    id: string;
    url: string;
    filename: string;
    media_type: string;
    file_size: number;
    created_at: string;
  }>;
}

interface ReportsTableProps {
  reports: Report[];
  isLoading: boolean;
  selectedReports: string[];
  onSelectionChange: (selected: string[]) => void;
  onStatusUpdate: (reportId: string, status: string) => void;
  onViewReport: (report: Report) => void;
  pagination: {
    page: number;
    total: number;
    pages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

interface ReportDetailModalProps {
  report: Report | null;
  isOpen: boolean;
  onClose: () => void;
  onStatusUpdate: (reportId: string, status: string) => void;
}

function ReportDetailModal({
  report,
  isOpen,
  onClose,
  onStatusUpdate,
}: ReportDetailModalProps) {
  const [isRejecting, setIsRejecting] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const queryClient = useQueryClient();

  const approveMutation = useMutation(apiClient.approveReport, {
    onSuccess: () => {
      toast.success("Report approved successfully!");
      queryClient.invalidateQueries("reports");
      onStatusUpdate(report!.id, "approved");
      onClose();
    },
    onError: (error: any) => {
      toast.error(`Failed to approve report: ${error.message}`);
    },
  });

  const rejectMutation = useMutation(
    ({ reportId, reason }: { reportId: string; reason: string }) =>
      apiClient.rejectReport(reportId, reason),
    {
      onSuccess: () => {
        toast.success("Report rejected successfully!");
        queryClient.invalidateQueries("reports");
        onStatusUpdate(report!.id, "rejected");
        onClose();
      },
      onError: (error: any) => {
        toast.error(`Failed to reject report: ${error.message}`);
      },
    }
  );

  const handleApprove = () => {
    if (report) {
      approveMutation.mutate(report.id);
    }
  };

  const handleReject = () => {
    if (report && rejectReason.trim()) {
      rejectMutation.mutate({ reportId: report.id, reason: rejectReason });
    }
  };

  if (!isOpen || !report) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          {/* Header */}
          <div className="flex justify-between items-start mb-6">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">
                {report.title}
              </h2>
              <div className="flex items-center space-x-4 mt-2">
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    report.status === "approved"
                      ? "bg-green-100 text-green-800"
                      : report.status === "pending"
                      ? "bg-yellow-100 text-yellow-800"
                      : report.status === "rejected"
                      ? "bg-red-100 text-red-800"
                      : "bg-gray-100 text-gray-800"
                  }`}
                >
                  {report.status.toUpperCase()}
                </span>
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    report.type === "lost"
                      ? "bg-blue-100 text-blue-800"
                      : "bg-purple-100 text-purple-800"
                  }`}
                >
                  {report.type.toUpperCase()}
                </span>
                <span className="text-sm text-gray-500">
                  {formatDistanceToNow(new Date(report.created_at), {
                    addSuffix: true,
                  })}
                </span>
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
              aria-label="Close modal"
              title="Close modal"
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Left Column - Report Details */}
            <div className="space-y-6">
              {/* Description */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Description
                </h3>
                <p className="text-gray-700">{report.description}</p>
              </div>

              {/* Location */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2 flex items-center">
                  <MapPinIcon className="h-5 w-5 mr-2" />
                  Location
                </h3>
                <div className="text-gray-700">
                  <p className="font-medium">{report.location_city}</p>
                  <p className="text-sm">{report.location_address}</p>
                </div>
              </div>

              {/* Category & Colors */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2 flex items-center">
                  <TagIcon className="h-5 w-5 mr-2" />
                  Category & Colors
                </h3>
                <div className="space-y-2">
                  <p className="text-gray-700 capitalize">{report.category}</p>
                  {report.colors && report.colors.length > 0 && (
                    <div className="flex flex-wrap gap-2">
                      {report.colors.map((color, index) => (
                        <span
                          key={index}
                          className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-sm"
                        >
                          {color}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* Dates */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2 flex items-center">
                  <CalendarIcon className="h-5 w-5 mr-2" />
                  Timeline
                </h3>
                <div className="space-y-1 text-sm text-gray-700">
                  <p>
                    <strong>Occurred:</strong>{" "}
                    {report.occurred_at
                      ? new Date(report.occurred_at).toLocaleDateString()
                      : "Not specified"}
                  </p>
                  <p>
                    <strong>Reported:</strong>{" "}
                    {new Date(report.created_at).toLocaleDateString()}
                  </p>
                  <p>
                    <strong>Updated:</strong>{" "}
                    {report.updated_at
                      ? new Date(report.updated_at).toLocaleDateString()
                      : "Never"}
                  </p>
                </div>
              </div>

              {/* Reward */}
              {report.reward_offered && (
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    Reward
                  </h3>
                  <p className="text-green-600 font-medium">
                    ${report.reward_amount}
                  </p>
                </div>
              )}

              {/* Moderation Notes */}
              {report.moderation_notes && (
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    Moderation Notes
                  </h3>
                  <p className="text-gray-700 bg-yellow-50 p-3 rounded">
                    {report.moderation_notes}
                  </p>
                </div>
              )}

              {/* Flags */}
              {report.flags && report.flags.length > 0 && (
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-2 flex items-center">
                    <ExclamationTriangleIcon className="h-5 w-5 mr-2 text-red-500" />
                    Flags
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {report.flags.map((flag, index) => (
                      <span
                        key={index}
                        className="px-2 py-1 bg-red-100 text-red-800 rounded text-sm"
                      >
                        {flag}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Right Column - Owner & Media */}
            <div className="space-y-6">
              {/* Owner Information */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2 flex items-center">
                  <UserIcon className="h-5 w-5 mr-2" />
                  Owner Information
                </h3>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="font-medium">
                    {report.owner.display_name || "No name"}
                  </p>
                  <p className="text-sm text-gray-600">{report.owner.email}</p>
                  {report.owner.phone_number && (
                    <p className="text-sm text-gray-600">
                      {report.owner.phone_number}
                    </p>
                  )}
                  <p className="text-xs text-gray-500 mt-2">
                    Member since{" "}
                    {new Date(report.owner.created_at).toLocaleDateString()}
                  </p>
                  <span
                    className={`inline-block px-2 py-1 rounded-full text-xs font-medium mt-2 ${
                      report.owner.status === "active"
                        ? "bg-green-100 text-green-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {report.owner.status}
                  </span>
                </div>
              </div>

              {/* Media */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2 flex items-center">
                  <PhotoIcon className="h-5 w-5 mr-2" />
                  Media ({report.media.length})
                </h3>
                {report.media.length > 0 ? (
                  <div className="grid grid-cols-2 gap-4">
                    {report.media.map((media) => (
                      <div key={media.id} className="bg-gray-50 p-3 rounded-lg">
                        <img
                          src={media.url}
                          alt={media.filename}
                          className="w-full h-32 object-cover rounded mb-2"
                        />
                        <p className="text-sm text-gray-600 truncate">
                          {media.filename}
                        </p>
                        <p className="text-xs text-gray-500">
                          {media.media_type}
                        </p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-gray-500 text-sm">No media attached</p>
                )}
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="mt-8 pt-6 border-t border-gray-200">
            <div className="flex justify-between items-center">
              <div className="flex space-x-3">
                {report.status === "pending" && (
                  <>
                    <button
                      onClick={handleApprove}
                      disabled={approveMutation.isLoading}
                      className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                    >
                      <CheckIcon className="h-4 w-4 mr-2" />
                      {approveMutation.isLoading ? "Approving..." : "Approve"}
                    </button>
                    <button
                      onClick={() => setIsRejecting(true)}
                      className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
                    >
                      <XMarkIcon className="h-4 w-4 mr-2" />
                      Reject
                    </button>
                  </>
                )}
                {report.status === "approved" && (
                  <button
                    onClick={() => onStatusUpdate(report.id, "hidden")}
                    className="flex items-center px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700"
                  >
                    <EyeSlashIcon className="h-4 w-4 mr-2" />
                    Hide
                  </button>
                )}
                {report.status === "hidden" && (
                  <button
                    onClick={() => onStatusUpdate(report.id, "approved")}
                    className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                  >
                    <EyeIcon className="h-4 w-4 mr-2" />
                    Show
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Reject Modal */}
      {isRejecting && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-60">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Reject Report
            </h3>
            <p className="text-sm text-gray-600 mb-4">
              Please provide a reason for rejecting this report:
            </p>
            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="Enter rejection reason..."
              className="w-full p-3 border border-gray-300 rounded-lg mb-4"
              rows={3}
            />
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setIsRejecting(false);
                  setRejectReason("");
                }}
                className="px-4 py-2 text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={!rejectReason.trim() || rejectMutation.isLoading}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                {rejectMutation.isLoading ? "Rejecting..." : "Reject Report"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function ReportsTable({
  reports,
  isLoading,
  selectedReports,
  onSelectionChange,
  onStatusUpdate,
  onViewReport,
  pagination,
}: ReportsTableProps) {
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);

  const handleViewReport = (report: Report) => {
    setSelectedReport(report);
    setShowDetailModal(true);
    onViewReport(report);
  };

  const handleCloseModal = () => {
    setShowDetailModal(false);
    setSelectedReport(null);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "approved":
        return "bg-green-100 text-green-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      case "hidden":
        return "bg-gray-100 text-gray-800";
      case "removed":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const getTypeColor = (type: string) => {
    return type === "lost"
      ? "bg-blue-100 text-blue-800"
      : "bg-purple-100 text-purple-800";
  };

  if (isLoading) {
    return (
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <div className="animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="h-16 bg-gray-200 rounded"></div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="px-4 py-5 sm:p-6">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    <input
                      type="checkbox"
                      checked={
                        selectedReports.length === reports.length &&
                        reports.length > 0
                      }
                      onChange={(e) => {
                        if (e.target.checked) {
                          onSelectionChange(reports.map((r) => r.id));
                        } else {
                          onSelectionChange([]);
                        }
                      }}
                      className="rounded border-gray-300"
                      aria-label="Select all reports"
                      title="Select all reports"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Report
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Owner
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Location
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
                {reports.map((report) => (
                  <tr key={report.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <input
                        type="checkbox"
                        checked={selectedReports.includes(report.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            onSelectionChange([...selectedReports, report.id]);
                          } else {
                            onSelectionChange(
                              selectedReports.filter((id) => id !== report.id)
                            );
                          }
                        }}
                        className="rounded border-gray-300"
                        aria-label={`Select report ${report.id}`}
                        title={`Select report ${report.id}`}
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10">
                          {report.media && report.media.length > 0 ? (
                            <img
                              className="h-10 w-10 rounded-lg object-cover"
                              src={report.media[0].url}
                              alt={report.title}
                            />
                          ) : (
                            <div className="h-10 w-10 rounded-lg bg-gray-200 flex items-center justify-center">
                              <TagIcon className="h-5 w-5 text-gray-400" />
                            </div>
                          )}
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900 truncate max-w-xs">
                            {report.title}
                          </div>
                          <div className="text-sm text-gray-500 truncate max-w-xs">
                            {report.category}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getTypeColor(
                          report.type
                        )}`}
                      >
                        {report.type}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(
                          report.status
                        )}`}
                      >
                        {report.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {report.owner.display_name || "No name"}
                      </div>
                      <div className="text-sm text-gray-500">
                        {report.owner.email}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {report.location_city}
                      </div>
                      <div className="text-sm text-gray-500">
                        {report.location_address}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {report.created_at
                        ? formatDistanceToNow(new Date(report.created_at), {
                            addSuffix: true,
                          })
                        : "Unknown"}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        <button
                          onClick={() => handleViewReport(report)}
                          className="text-indigo-600 hover:text-indigo-900"
                          title="View Details"
                          aria-label="View report details"
                        >
                          <EyeIcon className="h-4 w-4" />
                        </button>
                        {report.status === "pending" && (
                          <>
                            <button
                              onClick={() =>
                                onStatusUpdate(report.id, "approved")
                              }
                              className="text-green-600 hover:text-green-900"
                              title="Approve"
                            >
                              <CheckIcon className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() =>
                                onStatusUpdate(report.id, "rejected")
                              }
                              className="text-red-600 hover:text-red-900"
                              title="Reject"
                            >
                              <XMarkIcon className="h-4 w-4" />
                            </button>
                          </>
                        )}
                        {report.status === "approved" && (
                          <button
                            onClick={() => onStatusUpdate(report.id, "hidden")}
                            className="text-yellow-600 hover:text-yellow-900"
                            title="Hide"
                          >
                            <EyeSlashIcon className="h-4 w-4" />
                          </button>
                        )}
                        {report.status === "hidden" && (
                          <button
                            onClick={() =>
                              onStatusUpdate(report.id, "approved")
                            }
                            className="text-blue-600 hover:text-blue-900"
                            title="Show"
                          >
                            <EyeIcon className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
            <div className="flex-1 flex justify-between sm:hidden">
              <button
                onClick={() => {
                  /* Handle prev page */
                }}
                disabled={!pagination.hasPrev}
                className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
              >
                Previous
              </button>
              <button
                onClick={() => {
                  /* Handle next page */
                }}
                disabled={!pagination.hasNext}
                className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
              >
                Next
              </button>
            </div>
            <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
              <div>
                <p className="text-sm text-gray-700">
                  Showing page{" "}
                  <span className="font-medium">{pagination.page}</span> of{" "}
                  <span className="font-medium">{pagination.pages}</span> (
                  {pagination.total} total)
                </p>
              </div>
              <div>
                <nav
                  className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                  aria-label="Pagination"
                >
                  <button
                    onClick={() => {
                      /* Handle prev page */
                    }}
                    disabled={!pagination.hasPrev}
                    className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => {
                      /* Handle next page */
                    }}
                    disabled={!pagination.hasNext}
                    className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                  >
                    Next
                  </button>
                </nav>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Report Detail Modal */}
      <ReportDetailModal
        report={selectedReport}
        isOpen={showDetailModal}
        onClose={handleCloseModal}
        onStatusUpdate={onStatusUpdate}
      />
    </>
  );
}
