import React, { useState, useEffect } from "react";
import type { NextPage } from "next";
import {
  UserGroupIcon,
  MagnifyingGlassIcon,
  EyeIcon,
  ShieldCheckIcon,
  XCircleIcon,
  CheckCircleIcon,
  ClockIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";
import AdminLayout from "../components/AdminLayout";
import {
  Card,
  Button,
  Input,
  Select,
  Badge,
  LoadingSpinner,
  EmptyState,
  Modal,
} from "../components/ui";
import { User, UserFilters, PaginatedResponse } from "../types";
import { apiService } from "../services/api";

const Users: NextPage = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<UserFilters>({});
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    first_name: "",
    last_name: "",
    display_name: "",
    role: "user",
    phone_number: "",
  });

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [usersResponse, statsResponse] = await Promise.all([
        apiService.getUsers(filters),
        apiService.getStatistics(),
      ]);

      setUsers(usersResponse.items);
      setStats(statsResponse);
    } catch (err) {
      setError("Failed to fetch users data");
      console.error("Users error:", err);
    } finally {
      setLoading(false);
    }
  };

  const updateUserStatus = async (userId: string, isActive: boolean) => {
    try {
      await apiService.updateUser(userId, {
        is_active: isActive,
      });
      fetchData(); // Refresh data
    } catch (err) {
      console.error("Status update error:", err);
    }
  };

  const handleViewDetails = (user: User) => {
    setSelectedUser(user);
    setShowDetailsModal(true);
  };

  const handleEditUser = (user: User) => {
    setSelectedUser(user);
    setFormData({
      email: user.email,
      password: "",
      first_name: user.first_name || "",
      last_name: user.last_name || "",
      display_name: user.display_name || "",
      role: user.role,
      phone_number: user.phone_number || "",
    });
    setShowEditModal(true);
  };

  const handleDeleteUser = (user: User) => {
    setUserToDelete(user);
    setShowDeleteModal(true);
  };

  const confirmDelete = async () => {
    if (!userToDelete) return;
    try {
      await apiService.deleteUser(userToDelete.id);
      await fetchData();
      setShowDeleteModal(false);
      setUserToDelete(null);
    } catch (err) {
      console.error("Delete error:", err);
    }
  };

  const handleCreateUser = () => {
    setFormData({
      email: "",
      password: "",
      first_name: "",
      last_name: "",
      display_name: "",
      role: "user",
      phone_number: "",
    });
    setShowCreateModal(true);
  };

  const handleSubmitCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiService.createUser(formData);
      await fetchData();
      setShowCreateModal(false);
      setFormData({
        email: "",
        password: "",
        first_name: "",
        last_name: "",
        display_name: "",
        role: "user",
        phone_number: "",
      });
    } catch (err) {
      console.error("Create user error:", err);
    }
  };

  const handleSubmitEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;
    try {
      await apiService.updateUser(selectedUser.id, formData);
      await fetchData();
      setShowEditModal(false);
      setSelectedUser(null);
    } catch (err) {
      console.error("Update user error:", err);
    }
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case "admin":
        return "danger";
      case "moderator":
        return "info";
      case "user":
        return "success";
      default:
        return "default";
    }
  };

  const getStatusColor = (isActive: boolean) => {
    return isActive ? "success" : "danger";
  };

  const roleOptions = [
    { value: "", label: "All Roles" },
    { value: "admin", label: "Admin" },
    { value: "moderator", label: "Moderator" },
    { value: "user", label: "User" },
  ];

  const statusOptions = [
    { value: "", label: "All Status" },
    { value: "active", label: "Active" },
    { value: "inactive", label: "Inactive" },
    { value: "verified", label: "Verified" },
    { value: "unverified", label: "Unverified" },
  ];

  return (
    <AdminLayout
      title="Users Management"
      description="Manage system users and their permissions"
    >
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Users Management</h1>
        <p className="mt-2 text-gray-600">
          Manage system users and their permissions
        </p>
      </div>

      {error && (
        <Card className="mb-6 bg-red-50 border-red-200">
          <div className="flex items-center">
            <ExclamationTriangleIcon className="h-5 w-5 text-red-400 mr-2" />
            <p className="text-red-800">{error}</p>
          </div>
        </Card>
      )}

      {/* Stats Cards */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-blue-500">
                <UserGroupIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Total Users</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.total}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-green-500">
                <CheckCircleIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">
                  Active Users
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.active}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-purple-500">
                <ShieldCheckIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">
                  Verified Users
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.roles?.admin || 0}
                </p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-md bg-yellow-500">
                <ClockIcon className="h-6 w-6 text-white" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Moderators</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats.roles?.moderator || 0}
                </p>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Filters */}
      <Card title="Filters" className="mb-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Input
            label="Search"
            placeholder="Search users..."
            value={filters.search || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                search: e.target.value || undefined,
              }))
            }
          />

          <Select
            label="Role"
            options={roleOptions}
            value={filters.role || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                role: e.target.value || undefined,
              }))
            }
          />

          <Select
            label="Status"
            options={statusOptions}
            value={filters.status || ""}
            onChange={(e) =>
              setFilters((prev) => ({
                ...prev,
                status: e.target.value || undefined,
              }))
            }
          />

          <div className="flex items-end space-x-3">
            <Button onClick={fetchData} className="flex-1">
              <MagnifyingGlassIcon className="h-5 w-5 inline mr-2" />
              Filter
            </Button>
            <Button onClick={handleCreateUser} variant="success">
              <UserGroupIcon className="h-5 w-5 inline mr-2" />
              Add User
            </Button>
          </div>
        </div>
      </Card>

      {/* Users Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
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
                  Activity
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Reports
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Matches
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Joined
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center">
                    <LoadingSpinner size="lg" />
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center">
                    <EmptyState
                      title="No users found"
                      description="Try adjusting your filters or check back later"
                      icon={
                        <UserGroupIcon className="mx-auto h-12 w-12 text-gray-400" />
                      }
                    />
                  </td>
                </tr>
              ) : (
                users.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                          <span className="text-sm font-medium text-gray-700">
                            {(
                              user.display_name ||
                              `${user.first_name} ${user.last_name}`
                            )
                              .charAt(0)
                              .toUpperCase()}
                          </span>
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {user.display_name ||
                              `${user.first_name} ${user.last_name}`}
                          </div>
                          <div className="text-sm text-gray-500">
                            {user.email}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={getRoleColor(user.role) as any}>
                        {user.role}
                      </Badge>
                    </td>
                    <td className="px-6 py-4">
                      <div className="space-y-1">
                        <Badge
                          variant={getStatusColor(!!user.is_active) as any}
                        >
                          {user.is_active ? "Active" : "Inactive"}
                        </Badge>
                        {user.is_verified && (
                          <Badge variant="info">Verified</Badge>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">
                        {user.last_login_at
                          ? new Date(user.last_login_at).toLocaleDateString()
                          : "Never"}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-900">
                        {user.reports_count}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-900">
                        {user.matches_count}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(user.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex space-x-2">
                        {user.is_active ? (
                          <Button
                            size="sm"
                            variant="danger"
                            onClick={() => updateUserStatus(user.id, false)}
                            title="Deactivate User"
                          >
                            <XCircleIcon className="h-4 w-4" />
                          </Button>
                        ) : (
                          <Button
                            size="sm"
                            variant="success"
                            onClick={() => updateUserStatus(user.id, true)}
                            title="Activate User"
                          >
                            <CheckCircleIcon className="h-4 w-4" />
                          </Button>
                        )}
                        <Button
                          size="sm"
                          variant="secondary"
                          title="View Details"
                          onClick={() => handleViewDetails(user)}
                        >
                          <EyeIcon className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="info"
                          title="Edit User"
                          onClick={() => handleEditUser(user)}
                        >
                          <ShieldCheckIcon className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="danger"
                          title="Delete User"
                          onClick={() => handleDeleteUser(user)}
                        >
                          <ExclamationTriangleIcon className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>

      {/* User Details Modal */}
      {selectedUser && (
        <Modal
          isOpen={showDetailsModal}
          onClose={() => setShowDetailsModal(false)}
          title="User Details"
        >
          <div className="space-y-6">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                User Information
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-gray-500">Name</p>
                  <p className="text-sm text-gray-900">
                    {selectedUser.display_name ||
                      `${selectedUser.first_name} ${selectedUser.last_name}`}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Email</p>
                  <p className="text-sm text-gray-900">{selectedUser.email}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Role</p>
                  <Badge variant={getRoleColor(selectedUser.role) as any}>
                    {selectedUser.role}
                  </Badge>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Status</p>
                  <Badge
                    variant={selectedUser.is_active ? "success" : "danger"}
                  >
                    {selectedUser.is_active ? "Active" : "Inactive"}
                  </Badge>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Phone</p>
                  <p className="text-sm text-gray-900">
                    {selectedUser.phone_number || "N/A"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Joined</p>
                  <p className="text-sm text-gray-900">
                    {new Date(selectedUser.created_at).toLocaleDateString()}
                  </p>
                </div>
              </div>
            </div>

            <div className="bg-blue-50 p-4 rounded-lg">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                Activity Summary
              </h3>
              <div className="grid grid-cols-3 gap-4">
                <div className="text-center">
                  <p className="text-2xl font-bold text-blue-600">
                    {selectedUser.reports_count || 0}
                  </p>
                  <p className="text-sm text-gray-600">Reports</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-green-600">
                    {selectedUser.matches_count || 0}
                  </p>
                  <p className="text-sm text-gray-600">Matches</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-purple-600">
                    {selectedUser.successful_matches || 0}
                  </p>
                  <p className="text-sm text-gray-600">Successful</p>
                </div>
              </div>
            </div>

            <div className="flex justify-end">
              <Button
                variant="secondary"
                onClick={() => setShowDetailsModal(false)}
              >
                Close
              </Button>
            </div>
          </div>
        </Modal>
      )}

      {/* Create User Modal */}
      <Modal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        title="Create New User"
      >
        <form onSubmit={handleSubmitCreate} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="First Name"
              value={formData.first_name}
              onChange={(e) =>
                setFormData({ ...formData, first_name: e.target.value })
              }
              required
            />
            <Input
              label="Last Name"
              value={formData.last_name}
              onChange={(e) =>
                setFormData({ ...formData, last_name: e.target.value })
              }
              required
            />
          </div>
          <Input
            label="Display Name"
            value={formData.display_name}
            onChange={(e) =>
              setFormData({ ...formData, display_name: e.target.value })
            }
          />
          <Input
            label="Email"
            type="email"
            value={formData.email}
            onChange={(e) =>
              setFormData({ ...formData, email: e.target.value })
            }
            required
          />
          <Input
            label="Password"
            type="password"
            value={formData.password}
            onChange={(e) =>
              setFormData({ ...formData, password: e.target.value })
            }
            required
          />
          <Input
            label="Phone Number"
            value={formData.phone_number}
            onChange={(e) =>
              setFormData({ ...formData, phone_number: e.target.value })
            }
          />
          <Select
            label="Role"
            options={[
              { value: "user", label: "User" },
              { value: "moderator", label: "Moderator" },
              { value: "admin", label: "Admin" },
            ]}
            value={formData.role}
            onChange={(e) => setFormData({ ...formData, role: e.target.value })}
          />
          <div className="flex justify-end space-x-3 pt-4">
            <Button
              type="button"
              variant="secondary"
              onClick={() => setShowCreateModal(false)}
            >
              Cancel
            </Button>
            <Button type="submit" variant="success">
              Create User
            </Button>
          </div>
        </form>
      </Modal>

      {/* Edit User Modal */}
      {selectedUser && (
        <Modal
          isOpen={showEditModal}
          onClose={() => setShowEditModal(false)}
          title="Edit User"
        >
          <form onSubmit={handleSubmitEdit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <Input
                label="First Name"
                value={formData.first_name}
                onChange={(e) =>
                  setFormData({ ...formData, first_name: e.target.value })
                }
                required
              />
              <Input
                label="Last Name"
                value={formData.last_name}
                onChange={(e) =>
                  setFormData({ ...formData, last_name: e.target.value })
                }
                required
              />
            </div>
            <Input
              label="Display Name"
              value={formData.display_name}
              onChange={(e) =>
                setFormData({ ...formData, display_name: e.target.value })
              }
            />
            <Input
              label="Email"
              type="email"
              value={formData.email}
              onChange={(e) =>
                setFormData({ ...formData, email: e.target.value })
              }
              required
            />
            <Input
              label="New Password (leave blank to keep current)"
              type="password"
              value={formData.password}
              onChange={(e) =>
                setFormData({ ...formData, password: e.target.value })
              }
            />
            <Input
              label="Phone Number"
              value={formData.phone_number}
              onChange={(e) =>
                setFormData({ ...formData, phone_number: e.target.value })
              }
            />
            <Select
              label="Role"
              options={[
                { value: "user", label: "User" },
                { value: "moderator", label: "Moderator" },
                { value: "admin", label: "Admin" },
              ]}
              value={formData.role}
              onChange={(e) =>
                setFormData({ ...formData, role: e.target.value })
              }
            />
            <div className="flex justify-end space-x-3 pt-4">
              <Button
                type="button"
                variant="secondary"
                onClick={() => setShowEditModal(false)}
              >
                Cancel
              </Button>
              <Button type="submit" variant="info">
                Update User
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {/* Delete Confirmation Modal */}
      {userToDelete && (
        <Modal
          isOpen={showDeleteModal}
          onClose={() => setShowDeleteModal(false)}
          title="Delete User"
        >
          <div className="space-y-4">
            <div className="bg-red-50 p-4 rounded-lg">
              <div className="flex">
                <ExclamationTriangleIcon className="h-5 w-5 text-red-400" />
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-red-800">
                    Are you sure you want to delete this user?
                  </h3>
                  <div className="mt-2 text-sm text-red-700">
                    <p>
                      This action cannot be undone. This will permanently delete
                      the user
                      <strong>
                        {" "}
                        {userToDelete.display_name || userToDelete.email}
                      </strong>{" "}
                      and all associated data.
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div className="flex justify-end space-x-3">
              <Button
                variant="secondary"
                onClick={() => setShowDeleteModal(false)}
              >
                Cancel
              </Button>
              <Button variant="danger" onClick={confirmDelete}>
                Delete User
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </AdminLayout>
  );
};

export default Users;
