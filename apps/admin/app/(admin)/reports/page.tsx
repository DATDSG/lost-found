"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "react-query";
import apiClient from "@/lib/api";
import toast from "react-hot-toast";
import ReportsTable from "@/components/reports/ReportsTable";
import { ReportFilters } from "@/components/reports/ReportFilters";
import { ReportModal } from "@/components/reports/ReportModal";
import { BulkActions } from "@/components/reports/BulkActions";

interface Report {
  id: string;
  title: string;
  description: string;
  type: "lost" | "found";
  status: "pending" | "approved" | "hidden" | "removed" | "rejected";
  category: string;
  location_city: string;
  location_address: string;
  occurred_at: string;
  created_at: string;
  updated_at: string;
  reward_offered: boolean;
  is_resolved: boolean;
  owner: {
    id: string;
    email: string;
    display_name: string;
    phone_number: string;
  };
  media: Array<{
    id: string;
    url: string;
    filename: string;
    media_type: string;
  }>;
}

interface Filters {
  search: string;
  type: string;
  status: string;
  category: string;
  location_city: string;
}

export default function ReportsPage() {
  const [filters, setFilters] = useState<Filters>({
    search: "",
    type: "",
    status: "",
    category: "",
    location_city: "",
  });
  const [selectedReports, setSelectedReports] = useState<string[]>([]);
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  const { data: reportsData, isLoading } = useQuery(
    ["reports", page, filters],
    async () => {
      const params = {
        skip: ((page - 1) * 20).toString(),
        limit: "20",
        ...Object.fromEntries(Object.entries(filters).filter(([_, v]) => v)),
      };
      return await apiClient.getReports(params);
    }
  );

  const updateStatusMutation = useMutation(
    async ({ reportId, status }: { reportId: string; status: string }) => {
      await apiClient.updateReportStatus(reportId, status);
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(["reports"]);
        toast.success("Report status updated");
      },
      onError: () => {
        toast.error("Failed to update report status");
      },
    }
  );

  const bulkUpdateMutation = useMutation(
    async ({ reportIds, status }: { reportIds: string[]; status: string }) => {
      return await apiClient.bulkUpdateReports(reportIds, status);
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(["reports"]);
        setSelectedReports([]);
        toast.success("Reports updated successfully");
      },
      onError: () => {
        toast.error("Failed to update reports");
      },
    }
  );

  const handleStatusUpdate = (reportId: string, status: string) => {
    updateStatusMutation.mutate({ reportId, status });
  };

  const handleBulkUpdate = (status: string) => {
    if (selectedReports.length === 0) {
      toast.error("Please select reports to update");
      return;
    }
    bulkUpdateMutation.mutate({ reportIds: selectedReports, status });
  };

  const handleViewReport = (report: Report) => {
    setSelectedReport(report);
    setIsModalOpen(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reports</h1>
          <p className="mt-1 text-sm text-gray-500">
            Manage lost and found reports
          </p>
        </div>
      </div>

      <ReportFilters filters={filters} onFiltersChange={setFilters} />

      {selectedReports.length > 0 && (
        <BulkActions
          selectedCount={selectedReports.length}
          onBulkUpdate={handleBulkUpdate}
          onClearSelection={() => setSelectedReports([])}
        />
      )}

      <ReportsTable
        reports={reportsData?.items || []}
        isLoading={isLoading}
        selectedReports={selectedReports}
        onSelectionChange={setSelectedReports}
        onStatusUpdate={handleStatusUpdate}
        onViewReport={handleViewReport}
        pagination={{
          page,
          total: reportsData?.total || 0,
          pages: Math.ceil((reportsData?.total || 0) / 20),
          hasNext: page < Math.ceil((reportsData?.total || 0) / 20),
          hasPrev: page > 1,
        }}
      />

      <ReportModal
        report={selectedReport}
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedReport(null);
        }}
        onStatusUpdate={handleStatusUpdate}
      />
    </div>
  );
}
