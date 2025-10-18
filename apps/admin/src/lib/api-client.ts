/**
 * Centralized API Client for Lost & Found Admin Panel
 * Provides a consistent interface for all API interactions
 */

import axios, { AxiosInstance, AxiosRequestConfig } from "axios";

// API Configuration
const API_BASE_URL =
  import.meta.env.VITE_API_URL || "http://localhost:8000/api";
const API_TIMEOUT = 30000; // 30 seconds

/**
 * API Response wrapper
 */
export interface ApiResponse<T = unknown> {
  data: T;
  message?: string;
  error?: string;
}

/**
 * API Error structure
 */
export interface ApiError {
  message: string;
  status?: number;
  detail?: string;
}

/**
 * Centralized API Client class
 */
class APIClient {
  private readonly client: AxiosInstance;
  private authToken: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: API_TIMEOUT,
      headers: {
        "Content-Type": "application/json",
      },
    });

    // Request interceptor to add auth token
    this.client.interceptors.request.use(
      (config) => {
        if (this.authToken) {
          config.headers.Authorization = `Bearer ${this.authToken}`;
        }
        return config;
      },
      (error: Error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error: Error) => {
        if (axios.isAxiosError(error) && error.response?.status === 401) {
          // Handle unauthorized - clear token and redirect to login
          this.clearToken();
          window.location.href = "/login";
        }
        const apiError = this.normalizeError(error);
        return Promise.reject(new Error(apiError.message));
      }
    );

    // Load token from localStorage on init
    this.loadToken();
  }

  /**
   * Set authentication token
   */
  public setToken(token: string): void {
    this.authToken = token;
    localStorage.setItem("auth_token", token);
  }

  /**
   * Clear authentication token
   */
  public clearToken(): void {
    this.authToken = null;
    localStorage.removeItem("auth_token");
  }

  /**
   * Load token from localStorage
   */
  private loadToken(): void {
    const token = localStorage.getItem("auth_token");
    if (token) {
      this.authToken = token;
    }
  }

  /**
   * Normalize error response
   */
  private normalizeError(error: unknown): ApiError {
    if (axios.isAxiosError(error)) {
      if (error.response) {
        return {
          message:
            error.response.data?.detail ||
            error.response.data?.message ||
            "An error occurred",
          status: error.response.status,
          detail: error.response.data?.detail,
        };
      } else if (error.request) {
        return {
          message: "No response from server. Please check your connection.",
        };
      }
    }

    if (error instanceof Error) {
      return {
        message: error.message || "An unexpected error occurred",
      };
    }

    return {
      message: "An unexpected error occurred",
    };
  }

  /**
   * Generic GET request
   */
  public async get<T = unknown>(
    url: string,
    config?: AxiosRequestConfig
  ): Promise<T> {
    const response = await this.client.get<T>(url, config);
    return response.data;
  }

  /**
   * Generic POST request
   */
  public async post<T = unknown>(
    url: string,
    data?: unknown,
    config?: AxiosRequestConfig
  ): Promise<T> {
    const response = await this.client.post<T>(url, data, config);
    return response.data;
  }

  /**
   * Generic PUT request
   */
  public async put<T = unknown>(
    url: string,
    data?: unknown,
    config?: AxiosRequestConfig
  ): Promise<T> {
    const response = await this.client.put<T>(url, data, config);
    return response.data;
  }

  /**
   * Generic PATCH request
   */
  public async patch<T = unknown>(
    url: string,
    data?: unknown,
    config?: AxiosRequestConfig
  ): Promise<T> {
    const response = await this.client.patch<T>(url, data, config);
    return response.data;
  }

  /**
   * Generic DELETE request
   */
  public async delete<T = unknown>(
    url: string,
    config?: AxiosRequestConfig
  ): Promise<T> {
    const response = await this.client.delete<T>(url, config);
    return response.data;
  }

  /**
   * Upload file with multipart/form-data
   */
  public async uploadFile<T = unknown>(
    url: string,
    file: File,
    additionalData?: Record<string, unknown>
  ): Promise<T> {
    const formData = new FormData();
    formData.append("file", file);

    if (additionalData) {
      Object.entries(additionalData).forEach(([key, value]) => {
        formData.append(key, String(value));
      });
    }

    const response = await this.client.post<T>(url, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });

    return response.data;
  }

  /**
   * Get Axios instance for advanced usage
   */
  public getAxiosInstance(): AxiosInstance {
    return this.client;
  }
}

// Export singleton instance
export const apiClient = new APIClient();

// Export class for testing
export default APIClient;
