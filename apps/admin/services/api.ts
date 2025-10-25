/**
 * Enhanced API Client for Lost & Found Admin Panel
 * Provides better error handling, retry logic, and service integration
 */

import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import toast from 'react-hot-toast';

// API Configuration
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
const SERVER_API_URL = process.env.NEXT_PUBLIC_SERVER_URL || 'http://172.104.40.189:8000';
const API_VERSION = process.env.NEXT_PUBLIC_API_VERSION || 'v1';

// Determine which API URL to use based on environment
const getApiUrl = (): string => {
    if (typeof window !== 'undefined') {
        // Client-side: check if we're accessing from server IP
        const hostname = window.location.hostname;
        if (hostname === '172.104.40.189' || hostname.includes('172.104.40.189')) {
            return SERVER_API_URL;
        }
    }
    return API_BASE_URL;
};

// Request/Response interceptors for better error handling
const createApiClient = (): AxiosInstance => {
    const client = axios.create({
        baseURL: `${getApiUrl()}/${API_VERSION}`,
        timeout: 30000,
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
    });

    // Request interceptor
    client.interceptors.request.use(
        (config) => {
            // Add authentication token if available
            const token = localStorage.getItem('auth_token');
            if (token) {
                config.headers.Authorization = `Bearer ${token}`;
            }

            // Add request ID for tracking
            config.headers['X-Request-ID'] = generateRequestId();

            // Log request in development
            if (process.env.NODE_ENV === 'development') {
                console.log(`🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`);
            }

            return config;
        },
        (error) => {
            console.error('Request interceptor error:', error);
            return Promise.reject(error);
        }
    );

    // Response interceptor
    client.interceptors.response.use(
        (response: AxiosResponse) => {
            // Log response in development
            if (process.env.NODE_ENV === 'development') {
                console.log(`✅ API Response: ${response.status} ${response.config.url}`);
            }
            return response;
        },
        async (error) => {
            const originalRequest = error.config;

            // Handle authentication errors
            if (error.response?.status === 401 && !originalRequest._retry) {
                originalRequest._retry = true;

                // Clear invalid token
                localStorage.removeItem('auth_token');

                // Redirect to login
                if (typeof window !== 'undefined') {
                    window.location.href = '/login';
                }

                return Promise.reject(error);
            }

            // Handle rate limiting
            if (error.response?.status === 429) {
                const retryAfter = error.response.headers['retry-after'];
                toast.error(`Rate limited. Please wait ${retryAfter || 60} seconds.`);
                return Promise.reject(error);
            }

            // Handle server errors
            if (error.response?.status >= 500) {
                toast.error('Server error. Please try again later.');
                return Promise.reject(error);
            }

            // Handle network errors
            if (!error.response) {
                toast.error('Network error. Please check your connection.');
                return Promise.reject(error);
            }

            // Handle client errors
            if (error.response?.status >= 400 && error.response?.status < 500) {
                const message = error.response.data?.message || 'Request failed';
                toast.error(message);
                return Promise.reject(error);
            }

            return Promise.reject(error);
        }
    );

    return client;
};

// Generate unique request ID
const generateRequestId = (): string => {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

// API Client instance
export const apiClient = createApiClient();

// Enhanced API methods with retry logic
export class ApiService {
    private client: AxiosInstance;

    constructor() {
        this.client = apiClient;
    }

    // Generic request method with retry logic
    private async request<T>(
        config: AxiosRequestConfig,
        retries: number = 3
    ): Promise<T> {
        try {
            const response = await this.client.request<T>(config);
            return response.data;
        } catch (error: any) {
            if (retries > 0 && this.shouldRetry(error)) {
                await this.delay(1000 * (4 - retries)); // Exponential backoff
                return this.request<T>(config, retries - 1);
            }
            throw error;
        }
    }

    // Check if request should be retried
    private shouldRetry(error: any): boolean {
        if (!error.response) return true; // Network error
        const status = error.response.status;
        return status >= 500 || status === 429; // Server error or rate limit
    }

    // Delay utility
    private delay(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Health check
    async healthCheck(): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/health',
        });
    }

    // Authentication
    async login(credentials: { email: string; password: string }): Promise<any> {
        return this.request({
            method: 'POST',
            url: '/auth/login',
            data: credentials,
        });
    }

    async logout(): Promise<void> {
        localStorage.removeItem('auth_token');
        return this.request({
            method: 'POST',
            url: '/auth/logout',
        });
    }

    // Reports
    async getReports(params?: any): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/reports',
            params,
        });
    }

    async getReport(id: string): Promise<any> {
        return this.request({
            method: 'GET',
            url: `/reports/${id}`,
        });
    }

    async createReport(data: any): Promise<any> {
        return this.request({
            method: 'POST',
            url: '/reports',
            data,
        });
    }

    async updateReport(id: string, data: any): Promise<any> {
        return this.request({
            method: 'PUT',
            url: `/reports/${id}`,
            data,
        });
    }

    async deleteReport(id: string): Promise<void> {
        return this.request({
            method: 'DELETE',
            url: `/reports/${id}`,
        });
    }

    // Matches
    async getMatches(params?: any): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/matches',
            params,
        });
    }

    async getMatch(id: string): Promise<any> {
        return this.request({
            method: 'GET',
            url: `/matches/${id}`,
        });
    }

    async confirmMatch(id: string): Promise<any> {
        return this.request({
            method: 'POST',
            url: `/matches/${id}/confirm`,
        });
    }

    async rejectMatch(id: string): Promise<any> {
        return this.request({
            method: 'POST',
            url: `/matches/${id}/reject`,
        });
    }

    // Users
    async getUsers(params?: any): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/users',
            params,
        });
    }

    async getUser(id: string): Promise<any> {
        return this.request({
            method: 'GET',
            url: `/admin/users/${id}`,
        });
    }

    async createUser(data: any): Promise<any> {
        return this.request({
            method: 'POST',
            url: '/admin/users',
            data,
        });
    }

    async updateUser(id: string, data: any): Promise<any> {
        return this.request({
            method: 'PATCH',
            url: `/admin/users/${id}`,
            data,
        });
    }

    async deleteUser(id: string): Promise<void> {
        return this.request({
            method: 'DELETE',
            url: `/admin/users/${id}`,
        });
    }

    // Media upload
    async uploadFile(file: File, onProgress?: (progress: number) => void): Promise<any> {
        const formData = new FormData();
        formData.append('file', file);

        return this.request({
            method: 'POST',
            url: '/media/upload',
            data: formData,
            headers: {
                'Content-Type': 'multipart/form-data',
            },
            onUploadProgress: (progressEvent) => {
                if (onProgress && progressEvent.total) {
                    const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
                    onProgress(progress);
                }
            },
        });
    }

    // Analytics and Statistics
    async getStatistics(): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/dashboard/stats',
        });
    }

    async getDashboardData(): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/dashboard/stats',
        });
    }

    // Audit logs
    async getAuditLogs(params?: any): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/audit-logs',
            params,
        });
    }

    async getAuditLogsStats(): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/audit-logs/stats',
        });
    }

    // Fraud detection
    async getFraudReports(params?: any): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/fraud-detection/results',
            params,
        });
    }

    async flagReport(id: string, reason: string): Promise<any> {
        return this.request({
            method: 'POST',
            url: `/fraud-detection/reports/${id}/flag`,
            data: { reason },
        });
    }
}

// Export singleton instance
export const apiService = new ApiService();

// Export types
export interface ApiResponse<T = any> {
    data: T;
    message?: string;
    status: number;
}

export interface PaginatedResponse<T = any> {
    data: T[];
    total: number;
    page: number;
    per_page: number;
    total_pages: number;
}

export interface ErrorResponse {
    message: string;
    code?: string;
    details?: any;
}