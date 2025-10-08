import { apiClient } from "@/lib/api-client";

export interface User {
  id: string;
  email: string;
  display_name: string | null;
  role: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserFilters {
  role?: string;
  is_active?: boolean;
  search?: string;
  skip?: number;
  limit?: number;
}

export interface PaginatedUsers {
  items: User[];
  total: number;
  skip: number;
  limit: number;
}

export interface UpdateUserRequest {
  display_name?: string;
  role?: string;
  is_active?: boolean;
}

export const usersService = {
  async getUsers(filters: UserFilters = {}): Promise<PaginatedUsers> {
    return await apiClient.get<PaginatedUsers>("/admin/users", {
      params: filters,
    });
  },

  async getUser(id: string): Promise<User> {
    return await apiClient.get<User>(`/admin/users/${id}`);
  },

  async updateUser(id: string, data: UpdateUserRequest): Promise<User> {
    return await apiClient.patch<User>(`/admin/users/${id}`, data);
  },

  async deleteUser(id: string): Promise<void> {
    await apiClient.delete(`/admin/users/${id}`);
  },

  async getUserStats(): Promise<{
    total: number;
    active: number;
    by_role: Record<string, number>;
    new_today: number;
  }> {
    return await apiClient.get("/admin/users/stats");
  },

  // Bulk operations
  async bulkDelete(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/users/bulk/delete", { ids });
  },

  async bulkActivate(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/users/bulk/activate", { ids });
  },

  async bulkDeactivate(
    ids: string[]
  ): Promise<{ success: number; failed: number }> {
    return await apiClient.post("/admin/users/bulk/deactivate", { ids });
  },
};
