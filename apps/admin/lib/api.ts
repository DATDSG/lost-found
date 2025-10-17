import axios, { AxiosInstance, AxiosError } from "axios";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: `${API_BASE_URL}/api/v1`,
      timeout: 30000,
      headers: {
        "Content-Type": "application/json",
      },
    });

    // Request interceptor - add auth token
    this.client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem("admin_token");
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor - handle errors
    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError) => {
        if (error.response?.status === 401) {
          // Unauthorized - clear token and redirect
          localStorage.removeItem("admin_token");
          localStorage.removeItem("refresh_token");
          window.location.href = "/login";
        }
        return Promise.reject(error);
      }
    );
  }

  // Authentication
  async login(email: string, password: string) {
    const response = await this.client.post("/auth/login", { email, password });
    return response.data;
  }

  async getMe() {
    const response = await this.client.get("/auth/me");
    return response.data;
  }

  // Dashboard
  async getDashboardStats() {
    const response = await this.client.get("/admin/dashboard/stats");
    return response.data;
  }

  // Users
  async getUsers(params?: any) {
    const response = await this.client.get("/admin/users", { params });
    return response.data;
  }

  async banUser(userId: string, reason: string) {
    const response = await this.client.post(`/admin/users/${userId}/ban`, {
      reason,
    });
    return response.data;
  }

  async unbanUser(userId: string) {
    const response = await this.client.post(`/admin/users/${userId}/unban`);
    return response.data;
  }

  async updateUserRole(userId: string, role: string) {
    const response = await this.client.patch(`/admin/users/${userId}/role`, {
      role,
    });
    return response.data;
  }

  async updateUser(userId: string, updates: any) {
    const response = await this.client.patch(`/admin/users/${userId}`, updates);
    return response.data;
  }

  // Reports
  async getReports(params?: any) {
    const response = await this.client.get("/admin/reports", { params });
    return response.data;
  }

  async updateReportStatus(reportId: string, status: string, reason?: string) {
    const response = await this.client.patch(
      `/admin/reports/${reportId}/status`,
      {
        status,
        reason,
      }
    );
    return response.data;
  }

  async deleteReport(reportId: string, reason: string) {
    const response = await this.client.delete(`/admin/reports/${reportId}`, {
      data: { reason },
    });
    return response.data;
  }

  async bulkUpdateReports(
    reportIds: string[],
    status: string,
    reason?: string
  ) {
    const response = await this.client.post("/admin/reports/bulk/status", {
      ids: reportIds,
      status,
      reason,
    });
    return response.data;
  }

  // Matches
  async getMatches(params?: any) {
    const response = await this.client.get("/admin/matches", { params });
    return response.data;
  }

  async updateMatchStatus(matchId: string, status: string, reason?: string) {
    const response = await this.client.patch(
      `/admin/matches/${matchId}/status`,
      {
        status,
        reason,
      }
    );
    return response.data;
  }

  async deleteMatch(matchId: string, reason: string) {
    const response = await this.client.delete(`/admin/matches/${matchId}`, {
      data: { reason },
    });
    return response.data;
  }

  // Dashboard Charts
  async getReportsChart(days: number = 30) {
    const response = await this.client.get("/admin/dashboard/reports-chart", {
      params: { days },
    });
    return response.data;
  }

  // Profile
  async updateProfile(updates: any) {
    const response = await this.client.patch("/auth/me", updates);
    return response.data;
  }

  // Audit Logs
  async getAuditLogs(params?: any) {
    const response = await this.client.get("/admin/audit-logs", { params });
    return response.data;
  }

  // System
  async getSystemHealth() {
    const response = await this.client.get("/admin/dashboard/system/health");
    return response.data;
  }

  async clearCache() {
    const response = await this.client.post("/admin/system/cache/clear");
    return response.data;
  }

  // Enhanced Reports
  async getReportDetails(reportId: string) {
    const response = await this.client.get(`/admin/reports/${reportId}`);
    return response.data;
  }

  async approveReport(reportId: string) {
    const response = await this.client.post(
      `/admin/reports/${reportId}/approve`
    );
    return response.data;
  }

  async rejectReport(reportId: string, reason: string) {
    const response = await this.client.post(
      `/admin/reports/${reportId}/reject`,
      { reason }
    );
    return response.data;
  }

  // Enhanced Matches
  async getMatchDetails(matchId: string) {
    const response = await this.client.get(`/admin/matches/${matchId}`);
    return response.data;
  }

  async promoteMatch(matchId: string) {
    const response = await this.client.post(
      `/admin/matches/${matchId}/promote`
    );
    return response.data;
  }

  async suppressMatch(matchId: string, reason: string) {
    const response = await this.client.post(
      `/admin/matches/${matchId}/suppress`,
      { reason }
    );
    return response.data;
  }

  // Enhanced Users
  async getUserDetails(userId: string) {
    const response = await this.client.get(`/admin/users/${userId}`);
    return response.data;
  }

  async suspendUser(userId: string, reason: string) {
    const response = await this.client.post(`/admin/users/${userId}/suspend`, {
      reason,
    });
    return response.data;
  }

  async activateUser(userId: string) {
    const response = await this.client.post(`/admin/users/${userId}/activate`);
    return response.data;
  }

  async deleteUser(userId: string) {
    const response = await this.client.delete(`/admin/users/${userId}`);
    return response.data;
  }

  // Enhanced Profile
  async changePassword(currentPassword: string, newPassword: string) {
    const response = await this.client.post("/auth/change-password", {
      current_password: currentPassword,
      new_password: newPassword,
    });
    return response.data;
  }
}

export const apiClient = new ApiClient();
export default apiClient;
