import React, { useState, useEffect } from "react";
import type { NextPage } from "next";
import {
  ClipboardDocumentListIcon,
  MagnifyingGlassIcon,
  EyeIcon,
  CalendarIcon,
  UserIcon,
  CogIcon,
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
} from "../components/ui";
import { AuditLog, AuditFilters, PaginatedResponse } from "../types";
import apiService from "../services/api";

const AuditLogs: NextPage = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<AuditFilters>({});
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [logsResponse, statsResponse] = await Promise.all([
        apiService.getAuditLogs(filters),
        // Mock stats for now - would come from API
        Promise.resolve({
          total_logs: 15420,
          logs_today: 45,
          logs_this_week: 320,
          logs_this_month: 1280,
          top_actions: [
            { action: "create_report", count: 1250 },
            { action: "update_report", count: 890 },
            { action: "approve_report", count: 650 },
          ],
          top_actors: [
            { actor_email: "admin@example.com", count: 2100 },
            { actor_email: "moderator@example.com", count: 1800 },
          ],
        }),
      ]);

      setLogs(logsResponse.items);
      setStats(statsResponse);
    } catch (err) {
      setError("Failed to fetch audit logs data");
      console.error("Audit logs error:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetails = (log: AuditLog) => {
    setSelectedLog(log);
    setShowDetailsModal(true);
  };

  const getActionColor = (action: string) => {
    if (action.includes("create")) return "success";
    if (action.includes("update") || action.includes("modify")) return "info";
    if (action.includes("delete") || action.includes("remove")) return "danger";
    if (action.includes("approve") || action.includes("promote"))
      return "warning";
    if (action.includes("reject") || action.includes("deny")) return "danger";
    return "default";
  };

  const getResourceIcon = (resource: string) => {
    switch (resource) {
      case "report":
        return "📄";
      case "user":
        return "👤";
      case "match":
        return "🔗";
      case "fraud_detection_result":
        return "⚠️";
      default:
        return "📋";
    }
  };

  const actionOptions = [
    { value: "", label: "All Actions" },
    { value: "create", label: "Create" },
    { value: "update", label: "Update" },
    { value: "delete", label: "Delete" },
    { value: "approve", label: "Approve" },
    { value: "reject", label: "Reject" },
    { value: "login", label: "Login" },
    { value: "logout", label: "Logout" },
  ];

  return (
    <AdminLayout
      title="Audit Logs"
      description="View system activity and audit trails"
    >
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Audit Logs</h1>
        <p className="mt-2 text-gray-600">
          View system activity and audit trails
        </p>
      </div>

      {error && (
        <Card className="mb-6 bg-red-50 border-red-200">
          <div className="flex items-center">
            <CogIcon className="h-5 w-5 text-red-400 mr-2" />
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
                <ClipboardDocumentListIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Total Logs</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.total_logs}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-green-500">
                <CalendarIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Today</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.logs_today}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-yellow-500">
                <UserIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">This Week</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.logs_this_week}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-purple-500">
                <CogIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">This Month</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.logs_this_month}
                </p>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Filters */}
      <Card title="Filters" className="mb-6">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <Input
            label="Search"
            placeholder="Search logs..."
            value={filters.search || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                search: e.target.value || undefined,
              }))
            }
          />

          <Select
            label="Action"
            options={actionOptions}
            value={filters.action || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                action: e.target.value || undefined,
              }))
            }
          />

          <Input
            label="Actor Email"
            placeholder="Actor email..."
            value={filters.actor_email || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                actor_email: e.target.value || undefined,
              }))
            }
          />

          <Input
            label="Date From"
            type="date"
            value={filters.date_from || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                date_from: e.target.value || undefined,
              }))
            }
          />

          <Input
            label="Date To"
            type="date"
            value={filters.date_to || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                date_to: e.target.value || undefined,
              }))
            }
          />
        </div>
      </Card>

      {/* Logs Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Resource
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actor
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Reason
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Timestamp
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
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center">
                    <EmptyState
                      title="No audit logs found"
                      description="Try adjusting your filters or check back later"
                      icon={
                        <ClipboardDocumentListIcon className="mx-auto h-12 w-12 text-gray-400" />
                      }
                    />
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <span className="text-lg mr-2">
                          {getResourceIcon(
                            log.resource_type || log.resource || "unknown"
                          )}
                        </span>
                        <Badge variant={getActionColor(log.action) as any}>
                          {log.action}
                        </Badge>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {log.resource_type || log.resource || "Unknown"}
                      </div>
                      {log.resource_id && (
                        <div className="text-xs text-gray-500">
                          {log.resource_id.substring(0, 8)}...
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {log.actor_email}
                      </div>
                      {(log.user_id || log.actor_id) && (
                        <div className="text-xs text-gray-500">
                          {(log.user_id || log.actor_id)!.substring(0, 8)}...
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900 max-w-xs truncate">
                        {log.details || log.reason || "No details provided"}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                    <td className="px-6 py-4">
                      <Button
                        size="sm"
                        variant="secondary"
                        title="View Details"
                        onClick={() => handleViewDetails(log)}
                      >
                        <EyeIcon className="h-4 w-4" />
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Audit Log Details Modal */}
      {selectedLog && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="Audit Log Details"
        >
          <div className="space-y-6">
            {/* Log Overview */}
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                Log Information
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-gray-500">Log ID</p>
                  <p className="text-sm text-gray-900 font-mono">
                    {selectedLog.id}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Action</p>
                  <Badge variant={getActionColor(selectedLog.action) as any}>
                    {selectedLog.action}
                  </Badge>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Resource Type
                  </p>
                  <p className="text-sm text-gray-900">
                    {selectedLog.resource_type ||
                      selectedLog.resource ||
                      "Unknown"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Resource ID
                  </p>
                  <p className="text-sm text-gray-900 font-mono">
                    {selectedLog.resource_id || "N/A"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    Actor Email
                  </p>
                  <p className="text-sm text-gray-900">
                    {selectedLog.actor_email}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Actor ID</p>
                  <p className="text-sm text-gray-900 font-mono">
                    {selectedLog.user_id || selectedLog.actor_id || "N/A"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Timestamp</p>
                  <p className="text-sm text-gray-900">
                    {new Date(selectedLog.created_at).toLocaleString()}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">
                    IP Address
                  </p>
                  <p className="text-sm text-gray-900">
                    {selectedLog.ip_address || "N/A"}
                  </p>
                </div>
              </div>
            </div>

            {/* Details */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                Action Details
              </h3>
              <div className="bg-blue-50 p-4 rounded-lg">
                <div className="space-y-3">
                  <div>
                    <p className="text-sm font-medium text-gray-500">
                      Reason/Details
                    </p>
                    <p className="text-sm text-gray-900">
                      {selectedLog.details ||
                        selectedLog.reason ||
                        "No details provided"}
                    </p>
                  </div>
                  {selectedLog.metadata && (
                    <div>
                      <p className="text-sm font-medium text-gray-500">
                        Metadata
                      </p>
                      <pre className="text-xs text-gray-900 bg-white p-2 rounded border overflow-auto max-h-32">
                        {JSON.stringify(selectedLog.metadata, null, 2)}
                      </pre>
                    </div>
                  )}
                  {selectedLog.changes && (
                    <div>
                      <p className="text-sm font-medium text-gray-500">
                        Changes
                      </p>
                      <pre className="text-xs text-gray-900 bg-white p-2 rounded border overflow-auto max-h-32">
                        {JSON.stringify(selectedLog.changes, null, 2)}
                      </pre>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Additional Information */}
            {(selectedLog.session_id || selectedLog.user_agent) && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                  Session Information
                </h3>
                <div className="bg-green-50 p-4 rounded-lg">
                  <div className="space-y-3">
                    {selectedLog.session_id && (
                      <div>
                        <p className="text-sm font-medium text-gray-500">
                          Session ID
                        </p>
                        <p className="text-sm text-gray-900 font-mono">
                          {selectedLog.session_id}
                        </p>
                      </div>
                    )}
                    {selectedLog.user_agent && (
                      <div>
                        <p className="text-sm font-medium text-gray-500">
                          User Agent
                        </p>
                        <p className="text-sm text-gray-900 break-all">
                          {selectedLog.user_agent}
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            <div className="flex justify-end">
              <Button
                variant="secondary"
                onClick={() => setShowDetailsModal(false)}
              >
                Close
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </AdminLayout>
  );
};

export default AuditLogs;
