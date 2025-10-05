import axios, { AxiosError } from "axios";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export const apiClient = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  headers: {
    "Content-Type": "application/json",
  },
  withCredentials: true,
});

// Request interceptor - add auth token
apiClient.interceptors.request.use(
  (config) => {
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("auth_token");
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor - handle errors
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Redirect to login
      if (typeof window !== "undefined") {
        localStorage.removeItem("auth_token");
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  }
);

// API methods
export const api = {
  // Auth
  login: (email: string, password: string) =>
    apiClient.post("/auth/login", { username: email, password }),

  register: (data: any) => apiClient.post("/auth/register", data),

  // Items
  getItems: (params?: any) => apiClient.get("/items", { params }),

  getItem: (id: number) => apiClient.get(`/items/${id}`),

  createItem: (data: any) => apiClient.post("/items", data),

  updateItem: (id: number, data: any) => apiClient.put(`/items/${id}`, data),

  deleteItem: (id: number) => apiClient.delete(`/items/${id}`),

  // Health check
  healthCheck: () => apiClient.get("/healthz"),
};
