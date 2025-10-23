import axios, { AxiosInstance, AxiosResponse } from 'axios';
import {
    User,
    UserFilters,
    Report,
    ReportFilters,
    Match,
    MatchFilters,
    FraudDetectionResult,
    FraudFilters,
    AuditLog,
    AuditFilters,
    DashboardStats,
    PaginatedResponse,
    ApiResponse,
} from '../types';

class ApiService {
    private api: AxiosInstance;

    constructor() {
        this.api = axios.create({
            baseURL: `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'}/v1`,
            timeout: 10000,
            headers: {
                'Content-Type': 'application/json',
            },
        });

        // Add request interceptor for auth token
        this.api.interceptors.request.use(
            (config) => {
                const token = localStorage.getItem('auth_token');
                if (token) {
                    config.headers.Authorization = `Bearer ${token}`;
                }
                return config;
            },
            (error) => Promise.reject(error)
        );

        // Add response interceptor for error handling
        this.api.interceptors.response.use(
            (response) => response,
            (error) => {
                if (error.response?.status === 401) {
                    // Handle unauthorized access
                    localStorage.removeItem('auth_token');
                    window.location.href = '/login';
                }
                return Promise.reject(error);
            }
        );
    }

    // Dashboard API
    async getDashboardStats(): Promise<DashboardStats> {
        const response: AxiosResponse<DashboardStats> = await this.api.get('/admin/dashboard/stats');
        return response.data;
    }

    // Users API
    async getUsers(filters: UserFilters = {}): Promise<PaginatedResponse<User>> {
        const response: AxiosResponse<PaginatedResponse<User>> = await this.api.get('/admin/users', {
            params: filters,
        });
        return response.data;
    }

    async getUser(userId: string): Promise<User> {
        const response: AxiosResponse<ApiResponse<User>> = await this.api.get(`/admin/users/${userId}`);
        return response.data.data;
    }

    async updateUserStatus(userId: string, status: string): Promise<void> {
        await this.api.patch(`/admin/users/${userId}/status`, { status });
    }

    async updateUserRole(userId: string, role: string): Promise<void> {
        await this.api.patch(`/admin/users/${userId}/role`, { role });
    }

    // Reports API
    async getReports(filters: ReportFilters = {}): Promise<PaginatedResponse<Report>> {
        const response: AxiosResponse<PaginatedResponse<Report>> = await this.api.get('/admin/reports', {
            params: filters,
        });
        return response.data;
    }

    async getReport(reportId: string): Promise<Report> {
        const response: AxiosResponse<ApiResponse<Report>> = await this.api.get(`/admin/reports/${reportId}`);
        return response.data.data;
    }

    async updateReportStatus(reportId: string, status: string): Promise<void> {
        await this.api.patch(`/admin/reports/${reportId}/status`, { status });
    }

    async deleteReport(reportId: string): Promise<void> {
        await this.api.delete(`/admin/reports/${reportId}`);
    }

    // Matches API
    async getMatches(filters: MatchFilters = {}): Promise<PaginatedResponse<Match>> {
        try {
            const response: AxiosResponse<PaginatedResponse<Match>> = await this.api.get('/admin/matches', {
                params: filters,
            });
            // Ensure items is always an array and add safety checks
            const data = response.data;
            return {
                ...data,
                items: (data.items || []).map(item => ({
                    ...item,
                    overall_score: item.overall_score ?? 0,
                    source_report: item.source_report || { title: 'Unknown', category: 'Unknown', location_city: 'Unknown', type: 'Unknown' },
                    candidate_report: item.candidate_report || { title: 'Unknown', category: 'Unknown', location_city: 'Unknown', type: 'Unknown' }
                }))
            };
        } catch (error) {
            console.error('Error fetching matches:', error);
            // Return empty data structure on error
            return {
                items: [],
                total: 0,
                page: 1,
                per_page: 10,
                pages: 0,
                total_pages: 0
            };
        }
    }

    async getMatch(matchId: string): Promise<Match> {
        const response: AxiosResponse<ApiResponse<Match>> = await this.api.get(`/admin/matches/${matchId}`);
        return response.data.data;
    }

    async updateMatchStatus(matchId: string, status: string): Promise<void> {
        await this.api.patch(`/admin/matches/${matchId}/status`, { status });
    }

    async createMatch(sourceReportId: string, candidateReportId: string): Promise<Match> {
        const response: AxiosResponse<ApiResponse<Match>> = await this.api.post('/admin/matches', {
            source_report_id: sourceReportId,
            candidate_report_id: candidateReportId,
        });
        return response.data.data;
    }

    // Fraud Detection API
    async getFraudDetectionResults(filters: FraudFilters = {}): Promise<PaginatedResponse<FraudDetectionResult>> {
        const response: AxiosResponse<PaginatedResponse<FraudDetectionResult>> = await this.api.get('/admin/fraud-detection/flagged-reports', {
            params: filters,
        });
        return response.data;
    }

    async getFraudStats(): Promise<any> {
        const response: AxiosResponse<any> = await this.api.get('/admin/fraud-detection/stats');
        return response.data;
    }

    async runFraudCheck(reportId: string): Promise<FraudDetectionResult> {
        const response: AxiosResponse<ApiResponse<FraudDetectionResult>> = await this.api.post('/admin/fraud-detection/run-check', {
            report_id: reportId,
        });
        return response.data.data;
    }

    async reviewFraudResult(resultId: string, isConfirmed: boolean): Promise<void> {
        await this.api.patch(`/admin/fraud-detection/results/${resultId}/status`, {
            status: isConfirmed ? 'confirmed' : 'false_positive',
        });
    }

    // Audit Logs API
    async getAuditLogs(filters: AuditFilters = {}): Promise<PaginatedResponse<AuditLog>> {
        const response: AxiosResponse<PaginatedResponse<AuditLog>> = await this.api.get('/admin/audit-logs', {
            params: filters,
        });
        return response.data;
    }

    async getAuditLog(logId: string): Promise<AuditLog> {
        const response: AxiosResponse<ApiResponse<AuditLog>> = await this.api.get(`/admin/audit-logs/${logId}`);
        return response.data.data;
    }
}

export default new ApiService();