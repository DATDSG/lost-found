import { apiClient } from "@/lib/api-client";

export interface ServiceHealth {
  service: string;
  status: "healthy" | "degraded" | "down";
  latency_ms?: number;
  error?: string;
}

export interface SystemHealth {
  status: "healthy" | "degraded" | "down";
  timestamp: string;
  services: {
    database: ServiceHealth;
    redis: ServiceHealth;
    nlp: ServiceHealth;
    vision: ServiceHealth;
  };
}

export interface SystemMetrics {
  requests_total: number;
  requests_per_minute: number;
  avg_response_time_ms: number;
  error_rate: number;
  active_users: number;
}

export interface AuditLogEntry {
  id: string;
  user_id: string;
  action: string;
  resource_type: string;
  resource_id: string;
  details: Record<string, unknown>;
  ip_address: string;
  created_at: string;
  user?: {
    email: string;
    display_name: string | null;
  };
}

export interface AuditLogFilters {
  user_id?: string;
  action?: string;
  resource_type?: string;
  start_date?: string;
  end_date?: string;
  skip?: number;
  limit?: number;
}

export interface PaginatedAuditLogs {
  items: AuditLogEntry[];
  total: number;
  skip: number;
  limit: number;
}

export const systemService = {
  async getHealth(): Promise<SystemHealth> {
    return await apiClient.get<SystemHealth>("/health");
  },

  async getMetrics(): Promise<SystemMetrics> {
    return await apiClient.get<SystemMetrics>("/admin/system/metrics");
  },

  async getAuditLogs(
    filters: AuditLogFilters = {}
  ): Promise<PaginatedAuditLogs> {
    return await apiClient.get<PaginatedAuditLogs>("/admin/audit-logs", {
      params: filters,
    });
  },

  async clearCache(cacheType?: string): Promise<{ cleared: number }> {
    return await apiClient.post("/admin/system/cache/clear", {
      cache_type: cacheType,
    });
  },
};
