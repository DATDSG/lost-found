import { apiClient } from "@/lib/api-client";

export interface Match {
  id: string;
  lost_report_id: string;
  found_report_id: string;
  overall_score: number;
  location_score: number;
  temporal_score: number;
  text_similarity: number;
  visual_similarity: number | null;
  status: string;
  created_at: string;
  updated_at: string;
  lost_report?: {
    id: string;
    title: string;
    description: string;
    category: string;
  };
  found_report?: {
    id: string;
    title: string;
    description: string;
    category: string;
  };
}

export interface MatchFilters {
  status?: string;
  min_score?: number;
  max_score?: number;
  skip?: number;
  limit?: number;
}

export interface PaginatedMatches {
  items: Match[];
  total: number;
  skip: number;
  limit: number;
}

export const matchesService = {
  async getMatches(filters: MatchFilters = {}): Promise<PaginatedMatches> {
    return await apiClient.get<PaginatedMatches>("/admin/matches", {
      params: filters,
    });
  },

  async getMatch(id: string): Promise<Match> {
    return await apiClient.get<Match>(`/admin/matches/${id}`);
  },

  async getMatchStats(): Promise<{
    total: number;
    confirmed: number;
    pending: number;
    rejected: number;
    avg_score: number;
  }> {
    return await apiClient.get("/admin/matches/stats");
  },

  async triggerMatching(reportId: string): Promise<Match[]> {
    return await apiClient.post<Match[]>(`/admin/matches/trigger/${reportId}`);
  },

  // Bulk operations
  async bulkApprove(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/matches/bulk/approve", { ids });
  },

  async bulkReject(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/matches/bulk/reject", { ids });
  },

  async bulkNotify(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/matches/bulk/notify", { ids });
  },
};
