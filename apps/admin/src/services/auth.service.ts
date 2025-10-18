import { apiClient } from "@/lib/api-client";

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  token_type?: string;
}

export interface User {
  id: string;
  email: string;
  display_name: string | null;
  role: string;
  created_at: string;
}

export const authService = {
  async login(credentials: LoginRequest): Promise<LoginResponse> {
    const response = await apiClient.post<LoginResponse>(
      "/auth/login",
      credentials
    );
    // Store token in API client
    if (response.access_token) {
      apiClient.setToken(response.access_token);
    }
    return response;
  },

  async getCurrentUser(): Promise<User> {
    return await apiClient.get<User>("/auth/me");
  },

  async logout(): Promise<void> {
    await apiClient.post("/auth/logout");
    apiClient.clearToken();
  },

  async refreshToken(refreshToken: string): Promise<LoginResponse> {
    const response = await apiClient.post<LoginResponse>("/auth/refresh", {
      refresh_token: refreshToken,
    });
    if (response.access_token) {
      apiClient.setToken(response.access_token);
    }
    return response;
  },
};
