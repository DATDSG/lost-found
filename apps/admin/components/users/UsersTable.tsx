"use client";

import { useState } from "react";
import { formatDistanceToNow } from "date-fns";
import {
  EyeIcon,
  UserIcon,
  EnvelopeIcon,
  PhoneIcon,
  CalendarIcon,
  ShieldCheckIcon,
  ShieldExclamationIcon,
  TrashIcon,
  UserPlusIcon,
  UserMinusIcon,
  ExclamationTriangleIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { useMutation, useQueryClient } from "react-query";
import apiClient from "@/lib/api";
import { toast } from "react-toastify";

interface User {
  id: string;
  email: string;
  display_name: string;
  phone_number: string;
  avatar_url: string | null;
  role: "admin" | "user";
  status: "active" | "suspended" | "banned";
  is_active: boolean;
  created_at: string;
  updated_at: string;
  last_login: string;
  email_verified: boolean;
  phone_verified: boolean;
  preferences: any;
  statistics: {
    reports_count: number;
    matches_count: number;
  };
}

interface UsersTableProps {
  users: User[];
  isLoading: boolean;
  selectedUsers: string[];
  onSelectionChange: (selected: string[]) => void;
  onStatusUpdate: (userId: string, status: string) => void;
  onViewUser: (user: User) => void;
  pagination: {
    page: number;
    total: number;
    pages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

interface UserDetailModalProps {
  user: User | null;
  isOpen: boolean;
  onClose: () => void;
  onStatusUpdate: (userId: string, status: string) => void;
}

function UserDetailModal({
  user,
  isOpen,
  onClose,
  onStatusUpdate,
}: UserDetailModalProps) {
  const [isSuspending, setIsSuspending] = useState(false);
  const [suspendReason, setSuspendReason] = useState("");
  const queryClient = useQueryClient();

  const suspendMutation = useMutation(
    ({ userId, reason }: { userId: string; reason: string }) =>
      apiClient.suspendUser(userId, reason),
    {
      onSuccess: () => {
        toast.success("User suspended successfully!");
        queryClient.invalidateQueries("users");
        onStatusUpdate(user!.id, "suspended");
        onClose();
      },
      onError: (error: any) => {
        toast.error(`Failed to suspend user: ${error.message}`);
      },
    }
  );

  const activateMutation = useMutation(apiClient.activateUser, {
    onSuccess: () => {
      toast.success("User activated successfully!");
      queryClient.invalidateQueries("users");
      onStatusUpdate(user!.id, "active");
      onClose();
    },
    onError: (error: any) => {
      toast.error(`Failed to activate user: ${error.message}`);
    },
  });

  const deleteMutation = useMutation(
    (userId: string) => apiClient.deleteUser(userId),
    {
      onSuccess: () => {
        toast.success("User deleted successfully!");
        queryClient.invalidateQueries("users");
        onClose();
      },
      onError: (error: any) => {
        toast.error(`Failed to delete user: ${error.message}`);
      },
    }
  );

  const handleSuspend = () => {
    if (user && suspendReason.trim()) {
      suspendMutation.mutate({ userId: user.id, reason: suspendReason });
    }
  };

  const handleActivate = () => {
    if (user) {
      activateMutation.mutate(user.id);
    }
  };

  const handleDelete = () => {
    if (
      user &&
      window.confirm(
        `Are you sure you want to delete user ${user.email}? This action cannot be undone.`
      )
    ) {
      deleteMutation.mutate(user.id);
    }
  };

  if (!isOpen || !user) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          {/* Header */}
          <div className="flex justify-between items-start mb-6">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">
                {user.display_name || "No Name"}
              </h2>
              <div className="flex items-center space-x-4 mt-2">
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    user.status === "active"
                      ? "bg-green-100 text-green-800"
                      : user.status === "suspended"
                      ? "bg-yellow-100 text-yellow-800"
                      : "bg-red-100 text-red-800"
                  }`}
                >
                  {user.status.toUpperCase()}
                </span>
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    user.role === "admin"
                      ? "bg-purple-100 text-purple-800"
                      : "bg-blue-100 text-blue-800"
                  }`}
                >
                  {user.role.toUpperCase()}
                </span>
                <span className="text-sm text-gray-500">
                  Member since{" "}
                  {formatDistanceToNow(new Date(user.created_at), {
                    addSuffix: true,
                  })}
                </span>
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
              aria-label="Close modal"
              title="Close modal"
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Left Column - User Details */}
            <div className="space-y-6">
              {/* Contact Information */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Contact Information
                </h3>
                <div className="space-y-3">
                  <div className="flex items-center">
                    <EnvelopeIcon className="h-5 w-5 text-gray-400 mr-3" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {user.email}
                      </p>
                      <p className="text-xs text-gray-500">
                        {user.email_verified ? "Verified" : "Not verified"}
                      </p>
                    </div>
                  </div>
                  {user.phone_number && (
                    <div className="flex items-center">
                      <PhoneIcon className="h-5 w-5 text-gray-400 mr-3" />
                      <div>
                        <p className="text-sm font-medium text-gray-900">
                          {user.phone_number}
                        </p>
                        <p className="text-xs text-gray-500">
                          {user.phone_verified ? "Verified" : "Not verified"}
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Account Information */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Account Information
                </h3>
                <div className="space-y-2 text-sm text-gray-700">
                  <div className="flex items-center">
                    <CalendarIcon className="h-4 w-4 mr-2" />
                    <span>
                      <strong>Created:</strong>{" "}
                      {new Date(user.created_at).toLocaleDateString()}
                    </span>
                  </div>
                  <div className="flex items-center">
                    <CalendarIcon className="h-4 w-4 mr-2" />
                    <span>
                      <strong>Last Updated:</strong>{" "}
                      {user.updated_at
                        ? new Date(user.updated_at).toLocaleDateString()
                        : "Never"}
                    </span>
                  </div>
                  <div className="flex items-center">
                    <CalendarIcon className="h-4 w-4 mr-2" />
                    <span>
                      <strong>Last Login:</strong>{" "}
                      {user.last_login
                        ? new Date(user.last_login).toLocaleDateString()
                        : "Never"}
                    </span>
                  </div>
                </div>
              </div>

              {/* Preferences */}
              {user.preferences && Object.keys(user.preferences).length > 0 && (
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-3">
                    Preferences
                  </h3>
                  <div className="bg-gray-50 p-3 rounded-lg">
                    <pre className="text-xs text-gray-700 whitespace-pre-wrap">
                      {JSON.stringify(user.preferences, null, 2)}
                    </pre>
                  </div>
                </div>
              )}
            </div>

            {/* Right Column - Statistics & Actions */}
            <div className="space-y-6">
              {/* Statistics */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Statistics
                </h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-blue-50 p-4 rounded-lg text-center">
                    <div className="text-2xl font-bold text-blue-600">
                      {user.statistics.reports_count}
                    </div>
                    <div className="text-sm text-blue-800">Reports</div>
                  </div>
                  <div className="bg-green-50 p-4 rounded-lg text-center">
                    <div className="text-2xl font-bold text-green-600">
                      {user.statistics.matches_count}
                    </div>
                    <div className="text-sm text-green-800">Matches</div>
                  </div>
                </div>
              </div>

              {/* Account Status */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Account Status
                </h3>
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-700">
                      Email Verified
                    </span>
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        user.email_verified
                          ? "bg-green-100 text-green-800"
                          : "bg-red-100 text-red-800"
                      }`}
                    >
                      {user.email_verified ? "Yes" : "No"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-700">
                      Phone Verified
                    </span>
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        user.phone_verified
                          ? "bg-green-100 text-green-800"
                          : "bg-red-100 text-red-800"
                      }`}
                    >
                      {user.phone_verified ? "Yes" : "No"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-700">
                      Account Active
                    </span>
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        user.is_active
                          ? "bg-green-100 text-green-800"
                          : "bg-red-100 text-red-800"
                      }`}
                    >
                      {user.is_active ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="mt-8 pt-6 border-t border-gray-200">
            <div className="flex justify-between items-center">
              <div className="flex space-x-3">
                {user.status === "active" && user.role !== "admin" && (
                  <button
                    onClick={() => setIsSuspending(true)}
                    className="flex items-center px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700"
                  >
                    <UserMinusIcon className="h-4 w-4 mr-2" />
                    Suspend
                  </button>
                )}
                {user.status === "suspended" && (
                  <button
                    onClick={handleActivate}
                    disabled={activateMutation.isLoading}
                    className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                  >
                    <UserPlusIcon className="h-4 w-4 mr-2" />
                    {activateMutation.isLoading ? "Activating..." : "Activate"}
                  </button>
                )}
                {user.role !== "admin" && (
                  <button
                    onClick={handleDelete}
                    disabled={deleteMutation.isLoading}
                    className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
                  >
                    <TrashIcon className="h-4 w-4 mr-2" />
                    {deleteMutation.isLoading ? "Deleting..." : "Delete"}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Suspend Modal */}
      {isSuspending && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-60">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Suspend User
            </h3>
            <p className="text-sm text-gray-600 mb-4">
              Please provide a reason for suspending this user:
            </p>
            <textarea
              value={suspendReason}
              onChange={(e) => setSuspendReason(e.target.value)}
              placeholder="Enter suspension reason..."
              className="w-full p-3 border border-gray-300 rounded-lg mb-4"
              rows={3}
            />
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setIsSuspending(false);
                  setSuspendReason("");
                }}
                className="px-4 py-2 text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={handleSuspend}
                disabled={!suspendReason.trim() || suspendMutation.isLoading}
                className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 disabled:opacity-50"
              >
                {suspendMutation.isLoading ? "Suspending..." : "Suspend User"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function UsersTable({
  users,
  isLoading,
  selectedUsers,
  onSelectionChange,
  onStatusUpdate,
  onViewUser,
  pagination,
}: UsersTableProps) {
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  const handleViewUser = (user: User) => {
    setSelectedUser(user);
    setShowDetailModal(true);
    onViewUser(user);
  };

  const handleCloseModal = () => {
    setShowDetailModal(false);
    setSelectedUser(null);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "bg-green-100 text-green-800";
      case "suspended":
        return "bg-yellow-100 text-yellow-800";
      case "banned":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const getRoleColor = (role: string) => {
    return role === "admin"
      ? "bg-purple-100 text-purple-800"
      : "bg-blue-100 text-blue-800";
  };

  if (isLoading) {
    return (
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <div className="animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="h-16 bg-gray-200 rounded"></div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="px-4 py-5 sm:p-6">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    <input
                      type="checkbox"
                      checked={
                        selectedUsers.length === users.length &&
                        users.length > 0
                      }
                      onChange={(e) => {
                        if (e.target.checked) {
                          onSelectionChange(users.map((u) => u.id));
                        } else {
                          onSelectionChange([]);
                        }
                      }}
                      className="rounded border-gray-300"
                      aria-label="Select all users"
                      title="Select all users"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    User
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Role
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Statistics
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Last Login
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {users.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <input
                        type="checkbox"
                        checked={selectedUsers.includes(user.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            onSelectionChange([...selectedUsers, user.id]);
                          } else {
                            onSelectionChange(
                              selectedUsers.filter((id) => id !== user.id)
                            );
                          }
                        }}
                        className="rounded border-gray-300"
                        aria-label={`Select user ${user.email}`}
                        title={`Select user ${user.email}`}
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10">
                          <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                            <UserIcon className="h-6 w-6 text-gray-400" />
                          </div>
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {user.display_name || "No Name"}
                          </div>
                          <div className="text-sm text-gray-500">
                            {user.email}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getRoleColor(
                          user.role
                        )}`}
                      >
                        {user.role}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(
                          user.status
                        )}`}
                      >
                        {user.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {user.statistics.reports_count} reports
                      </div>
                      <div className="text-sm text-gray-500">
                        {user.statistics.matches_count} matches
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {user.last_login
                        ? formatDistanceToNow(new Date(user.last_login), {
                            addSuffix: true,
                          })
                        : "Never"}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        <button
                          onClick={() => handleViewUser(user)}
                          className="text-indigo-600 hover:text-indigo-900"
                          title="View Details"
                          aria-label="View user details"
                        >
                          <EyeIcon className="h-4 w-4" />
                        </button>
                        {user.status === "active" && user.role !== "admin" && (
                          <button
                            onClick={() => onStatusUpdate(user.id, "suspended")}
                            className="text-yellow-600 hover:text-yellow-900"
                            title="Suspend"
                          >
                            <UserMinusIcon className="h-4 w-4" />
                          </button>
                        )}
                        {user.status === "suspended" && (
                          <button
                            onClick={() => onStatusUpdate(user.id, "active")}
                            className="text-green-600 hover:text-green-900"
                            title="Activate"
                          >
                            <UserPlusIcon className="h-4 w-4" />
                          </button>
                        )}
                        {user.role !== "admin" && (
                          <button
                            onClick={() => onStatusUpdate(user.id, "deleted")}
                            className="text-red-600 hover:text-red-900"
                            title="Delete"
                          >
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
            <div className="flex-1 flex justify-between sm:hidden">
              <button
                onClick={() => {
                  /* Handle prev page */
                }}
                disabled={!pagination.hasPrev}
                className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
              >
                Previous
              </button>
              <button
                onClick={() => {
                  /* Handle next page */
                }}
                disabled={!pagination.hasNext}
                className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
              >
                Next
              </button>
            </div>
            <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
              <div>
                <p className="text-sm text-gray-700">
                  Showing page{" "}
                  <span className="font-medium">{pagination.page}</span> of{" "}
                  <span className="font-medium">{pagination.pages}</span> (
                  {pagination.total} total)
                </p>
              </div>
              <div>
                <nav
                  className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                  aria-label="Pagination"
                >
                  <button
                    onClick={() => {
                      /* Handle prev page */
                    }}
                    disabled={!pagination.hasPrev}
                    className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => {
                      /* Handle next page */
                    }}
                    disabled={!pagination.hasNext}
                    className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                  >
                    Next
                  </button>
                </nav>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* User Detail Modal */}
      <UserDetailModal
        user={selectedUser}
        isOpen={showDetailModal}
        onClose={handleCloseModal}
        onStatusUpdate={onStatusUpdate}
      />
    </>
  );
}
