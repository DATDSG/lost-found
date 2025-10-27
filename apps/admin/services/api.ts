/**
 * Enhanced API Client for Lost & Found Admin Panel
 * Provides better error handling, retry logic, and service integration
 */

import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios';
import toast from 'react-hot-toast';

// API Configuration - Multi-network support
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
const SERVER_API_URL = process.env.NEXT_PUBLIC_SERVER_URL || 'http://172.104.40.189:8000';
const EMULATOR_API_URL = process.env.NEXT_PUBLIC_EMULATOR_URL || 'http://10.0.2.2:8000';
const API_VERSION = process.env.NEXT_PUBLIC_API_VERSION || 'v1';

// Determine which API URL to use based on environment
const getApiUrl = (): string => {
    if (typeof window !== 'undefined') {
        // Client-side: check which network we're accessing from
        const hostname = window.location.hostname;

        // Server network
        if (hostname === '172.104.40.189' || hostname.includes('172.104.40.189')) {
            return SERVER_API_URL;
        }

        // Android emulator network
        if (hostname === '10.0.2.2' || hostname.includes('10.0.2.2')) {
            return EMULATOR_API_URL;
        }

        // Localhost network
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            return API_BASE_URL;
        }
    }
    return API_BASE_URL;
};

// Helper functions for token management
const isTokenExpired = (): boolean => {
    try {
        const tokenData = localStorage.getItem('auth_token');
        if (!tokenData) {
            console.log('🔍 No token found in localStorage');
            return true;
        }

        // Check if it's the new format with timestamp
        const parsed = JSON.parse(tokenData);
        if (parsed.timestamp && parsed.expiresIn) {
            const isExpired = Date.now() - parsed.timestamp > parsed.expiresIn;
            console.log('🔍 Token expiration check:', {
                timestamp: parsed.timestamp,
                expiresIn: parsed.expiresIn,
                currentTime: Date.now(),
                timeElapsed: Date.now() - parsed.timestamp,
                isExpired
            });
            return isExpired;
        }

        // If it's the old format (just a string token), don't consider it expired
        // Let the server validate it instead
        console.log('🔍 Old token format detected, letting server validate');
        return false;
    } catch {
        // If parsing fails, it might be the old string format
        // Don't consider it expired, let the server handle it
        console.log('🔍 Token parsing failed, assuming old format');
        return false;
    }
};

const getToken = (): string | null => {
    try {
        const tokenData = localStorage.getItem('auth_token');
        if (!tokenData) return null;

        // Try to parse as JSON (new format)
        const parsed = JSON.parse(tokenData);
        if (parsed.token) {
            return parsed.token;
        }

        // If parsing succeeded but no token property, return the original data
        return tokenData;
    } catch {
        // If parsing fails, it's the old string format
        const tokenData = localStorage.getItem('auth_token');
        return tokenData;
    }
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
        (config: InternalAxiosRequestConfig) => {
            // Add authentication token if available and not expired
            const token = getToken();
            console.log('🔍 Request interceptor:', {
                url: config.url,
                method: config.method,
                hasToken: !!token,
                tokenLength: token?.length,
                isTokenExpired: isTokenExpired()
            });

            if (token && !isTokenExpired()) {
                config.headers = config.headers || {};
                config.headers.Authorization = `Bearer ${token}`;
            } else if (isTokenExpired()) {
                // Token is expired, clear it
                console.warn('⚠️ Token is expired, clearing...');
                localStorage.removeItem('auth_token');
                localStorage.removeItem('admin_user');
            }

            // Add request ID for tracking
            config.headers = config.headers || {};
            config.headers['X-Request-ID'] = generateRequestId();

            // Log request in development
            if (process.env.NODE_ENV === 'development') {
                console.log(`🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`);
            }

            return config;
        },
        (error: any) => {
            console.error('Request interceptor error:', error);
            return Promise.reject(error);
        }
    );

    // Response interceptor
    client.interceptors.response.use(
        (response: AxiosResponse) => {
            // Log response in development
            if (process.env.NODE_ENV === 'development') {
                console.log(`✅ API Response: ${response.status} ${response.config.url}`, {
                    status: response.status,
                    data: response.data
                });
            }
            return response;
        },
        async (error: any) => {
            const originalRequest = error.config;

            // Handle authentication errors
            if (error.response?.status === 401 && !originalRequest._retry) {
                console.error('🔴 401 Authentication Error:', {
                    url: originalRequest.url,
                    method: originalRequest.method,
                    error: error.response?.data,
                    status: error.response?.status,
                    headers: error.response?.headers
                });
                originalRequest._retry = true;

                // Clear invalid token and user data
                localStorage.removeItem('auth_token');
                localStorage.removeItem('admin_user');

                // Show error message
                toast.error('Session expired. Please log in again.');

                // Redirect to login with error message
                if (typeof window !== 'undefined') {
                    window.location.href = '/login?error=session_expired';
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
        config: Partial<InternalAxiosRequestConfig>,
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
        try {
            const response = await this.request({
                method: 'POST',
                url: '/auth/login',
                data: credentials,
            });

            // Store token with timestamp for expiration tracking
            if (response && typeof response === 'object' && 'access_token' in response) {
                const tokenData = {
                    token: (response as any).access_token,
                    timestamp: Date.now(),
                    expiresIn: 30 * 60 * 1000 // 30 minutes in milliseconds
                };
                localStorage.setItem('auth_token', JSON.stringify(tokenData));
            }

            return response;
        } catch (error: any) {
            console.error('Login failed:', error);
            throw error;
        }
    }

    async logout(): Promise<void> {
        try {
            await this.request({
                method: 'POST',
                url: '/auth/logout',
            });
        } catch (error) {
            console.warn('Logout request failed:', error);
        } finally {
            localStorage.removeItem('auth_token');
            localStorage.removeItem('admin_user');
        }
    }

    async getCurrentUser(): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/auth/me',
        });
    }

    // Token management - using helper functions
    private isTokenExpired(): boolean {
        return isTokenExpired();
    }

    private getToken(): string | null {
        return getToken();
    }

    async getUserStats(userId: string): Promise<any> {
        return this.request({
            method: 'GET',
            url: `/admin/users/${userId}`,
        });
    }

    async getUsersStats(): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/users/stats',
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
            method: 'PATCH',
            url: `/admin/reports/${id}/status`,
            data,
        });
    }

    async deleteReport(id: string, reason?: string): Promise<void> {
        return this.request({
            method: 'DELETE',
            url: `/admin/reports/${id}`,
            data: { reason: reason || 'Deleted by admin' },
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
            url: `/admin/matches/${id}`,
        });
    }

    async confirmMatch(id: string): Promise<any> {
        return this.request({
            method: 'POST',
            url: `/admin/matches/${id}/confirm`,
        });
    }

    async rejectMatch(id: string): Promise<any> {
        return this.request({
            method: 'POST',
            url: `/admin/matches/${id}/reject`,
        });
    }

    async updateMatch(id: string, data: any): Promise<any> {
        return this.request({
            method: 'PATCH',
            url: `/admin/matches/${id}/status`,
            data,
        });
    }

    // Users
    async getUsers(params?: any): Promise<any> {
        try {
            return await this.request({
                method: 'GET',
                url: '/admin/users/list',
                params,
            });
        } catch (error: any) {
            console.error('Failed to fetch users:', error);
            if (error.response?.status === 401) {
                throw new Error('Authentication failed. Please log in again.');
            }
            throw error;
        }
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
            } as any,
            onUploadProgress: (progressEvent: any) => {
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

    async getRecentActivity(limit: number = 50): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/dashboard/activity',
            params: { limit },
        });
    }

    async getReportsChart(days: number = 30): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/dashboard/reports-chart',
            params: { days },
        });
    }

    async getSystemHealth(): Promise<any> {
        return this.request({
            method: 'GET',
            url: '/admin/dashboard/system/health',
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
        try {
            return await this.request({
                method: 'GET',
                url: '/admin/fraud-detection',
                params,
            });
        } catch (error: any) {
            console.error('Failed to fetch fraud reports:', error);
            if (error.response?.status === 401) {
                throw new Error('Authentication failed. Please log in again.');
            }
            throw error;
        }
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