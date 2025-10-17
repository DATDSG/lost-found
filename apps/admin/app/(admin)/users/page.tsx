"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "react-query";
import apiClient from "@/lib/api";
import toast from "react-hot-toast";
import UsersTable from "@/components/users/UsersTable";
import { UserFilters } from "@/components/users/UserFilters";
import { UserModal } from "@/components/users/UserModal";

interface User {
  id: string;
  email: string;
  display_name: string | null;
  phone_number: string | null;
  avatar_url: string | null;
  role: string;
  status: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  statistics: {
    reports_count: number;
    matches_count: number;
  };
}

interface Filters {
  search: string;
  role: string;
  status: string;
  is_active: string;
}

export default function UsersPage() {
  const [filters, setFilters] = useState<Filters>({
    search: "",
    role: "",
    status: "",
    is_active: "",
  });
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  const { data: usersData, isLoading } = useQuery(
    ["users", page, filters],
    async () => {
      const params = {
        skip: ((page - 1) * 20).toString(),
        limit: "20",
        ...Object.fromEntries(Object.entries(filters).filter(([_, v]) => v)),
      };
      return await apiClient.getUsers(params);
    }
  );

  const updateUserMutation = useMutation(
    async ({ userId, updates }: { userId: string; updates: Partial<User> }) => {
      return await apiClient.updateUser(userId, updates);
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(["users"]);
        toast.success("User updated successfully");
      },
      onError: () => {
        toast.error("Failed to update user");
      },
    }
  );

  const handleUserUpdate = (userId: string, status: string) => {
    updateUserMutation.mutate({ userId, updates: { status } });
  };

  const handleUserUpdateFromModal = (userId: string, updates: Partial<User>) => {
    updateUserMutation.mutate({ userId, updates });
  };

  const handleViewUser = (user: User) => {
    setSelectedUser(user);
    setIsModalOpen(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="mt-1 text-sm text-gray-500">
            Manage user accounts and permissions
          </p>
        </div>
      </div>

      <UserFilters filters={filters} onFiltersChange={setFilters} />

      <UsersTable
        users={usersData?.items || []}
        isLoading={isLoading}
        selectedUsers={[]}
        onSelectionChange={() => {}}
        onStatusUpdate={handleUserUpdate}
        onViewUser={handleViewUser}
        pagination={{
          page,
          total: usersData?.total || 0,
          pages: Math.ceil((usersData?.total || 0) / 20),
          hasNext: page < Math.ceil((usersData?.total || 0) / 20),
          hasPrev: page > 1,
        }}
      />

      <UserModal
        user={selectedUser}
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedUser(null);
        }}
        onUserUpdate={handleUserUpdateFromModal}
      />
    </div>
  );
}
