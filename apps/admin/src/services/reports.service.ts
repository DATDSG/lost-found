import { apiClient } from "@/lib/api-client";

export type ReportType = "lost" | "found";
export type ReportStatus = "pending" | "approved" | "hidden" | "removed";

export interface Report {
  id: string;
  user_id: string;
  type: ReportType;
  status: ReportStatus;
  title: string;
  description: string;
  category: string;
  location: string;
  date_occurred: string;
  contact_info: string;
  media_urls: string[];
  tags: string[];
  created_at: string;
  updated_at: string;
  user?: {
    email: string;
    display_name: string | null;
  };
}

export interface ReportFilters {
  type?: ReportType;
  status?: ReportStatus;
  category?: string;
  search?: string;
  start_date?: string;
  end_date?: string;
  skip?: number;
  limit?: number;
}

export interface PaginatedReports {
  items: Report[];
  total: number;
  skip: number;
  limit: number;
}

export interface UpdateReportStatusRequest {
  status: ReportStatus;
  admin_notes?: string;
}

export const reportsService = {
  async getReports(filters: ReportFilters = {}): Promise<PaginatedReports> {
    return await apiClient.get<PaginatedReports>("/admin/reports", {
      params: filters,
    });
  },

  async getReport(id: string): Promise<Report> {
    return await apiClient.get<Report>(`/admin/reports/${id}`);
  },

  async updateReportStatus(
    id: string,
    data: UpdateReportStatusRequest
  ): Promise<Report> {
    return await apiClient.patch<Report>(`/admin/reports/${id}/status`, data);
  },

  async deleteReport(id: string): Promise<void> {
    await apiClient.delete(`/admin/reports/${id}`);
  },

  async bulkDeleteReports(ids: string[]): Promise<void> {
    await apiClient.post("/admin/reports/bulk-delete", { report_ids: ids });
  },

  async bulkApproveReports(ids: string[]): Promise<void> {
    await apiClient.post("/admin/reports/bulk-approve", { report_ids: ids });
  },

  async bulkRejectReports(ids: string[]): Promise<void> {
    await apiClient.post("/admin/reports/bulk-reject", { report_ids: ids });
  },

  async getReportStats(): Promise<{
    total: number;
    by_type: Record<ReportType, number>;
    by_status: Record<ReportStatus, number>;
    recent_24h: number;
  }> {
    return await apiClient.get("/admin/reports/stats");
  },

  // Legacy bulk operations (deprecated - use new methods above)
  async bulkDelete(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/reports/bulk/delete", { ids });
  },

  async bulkApprove(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/reports/bulk/approve", { ids });
  },

  async bulkReject(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/reports/bulk/reject", { ids });
  },
};
