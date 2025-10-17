"use client";

import { Fragment, useState, useEffect } from "react";
import { Dialog, Transition } from "@headlessui/react";
import { XMarkIcon, UserCircleIcon } from "@heroicons/react/24/outline";
import { format } from "date-fns";

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

interface UserModalProps {
  user: User | null;
  isOpen: boolean;
  onClose: () => void;
  onUserUpdate: (userId: string, updates: Partial<User>) => void;
}

export function UserModal({
  user,
  isOpen,
  onClose,
  onUserUpdate,
}: UserModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    display_name: "",
    phone_number: "",
    role: "",
    status: "",
    is_active: true,
  });

  if (!user) return null;

  // Initialize form data when user changes
  useEffect(() => {
    if (user) {
      setFormData({
        display_name: user.display_name || "",
        phone_number: user.phone_number || "",
        role: user.role,
        status: user.status,
        is_active: user.is_active,
      });
    }
  }, [user]);

  const handleSave = () => {
    onUserUpdate(user.id, formData);
    setIsEditing(false);
  };

  const getRoleBadge = (role: string) => {
    const styles = {
      admin: "bg-red-100 text-red-800",
      moderator: "bg-blue-100 text-blue-800",
      user: "bg-gray-100 text-gray-800",
    };
    return styles[role as keyof typeof styles] || "bg-gray-100 text-gray-800";
  };

  const getStatusBadge = (status: string, isActive: boolean) => {
    if (!isActive) return "bg-red-100 text-red-800";

    const styles = {
      active: "bg-green-100 text-green-800",
      inactive: "bg-yellow-100 text-yellow-800",
      suspended: "bg-red-100 text-red-800",
    };
    return styles[status as keyof typeof styles] || "bg-gray-100 text-gray-800";
  };

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={onClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black bg-opacity-25" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4 text-center">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-2xl transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <div className="flex items-center justify-between mb-6">
                  <Dialog.Title
                    as="h3"
                    className="text-lg font-medium leading-6 text-gray-900"
                  >
                    User Details
                  </Dialog.Title>
                  <button
                    type="button"
                    className="text-gray-400 hover:text-gray-600"
                    onClick={onClose}
                    title="Close modal"
                  >
                    <XMarkIcon className="h-6 w-6" />
                  </button>
                </div>

                <div className="space-y-6">
                  {/* User Header */}
                  <div className="flex items-center space-x-4">
                    {user.avatar_url ? (
                      <img
                        src={user.avatar_url}
                        alt={user.display_name || user.email}
                        className="h-16 w-16 rounded-full object-cover"
                      />
                    ) : (
                      <UserCircleIcon className="h-16 w-16 text-gray-400" />
                    )}
                    <div className="flex-1">
                      <h2 className="text-xl font-semibold text-gray-900">
                        {user.display_name || "No name"}
                      </h2>
                      <p className="text-gray-600">{user.email}</p>
                      <div className="flex items-center space-x-3 mt-2">
                        <span
                          className={`px-2 py-1 rounded-full text-xs font-medium ${getRoleBadge(
                            user.role
                          )}`}
                        >
                          {user.role}
                        </span>
                        <span
                          className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusBadge(
                            user.status,
                            user.is_active
                          )}`}
                        >
                          {user.is_active ? user.status : "Disabled"}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* User Information */}
                  <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <div>
                      <h4 className="text-sm font-medium text-gray-900 mb-3">
                        Account Information
                      </h4>
                      <dl className="space-y-2">
                        <div>
                          <dt className="text-sm text-gray-500">
                            Display Name
                          </dt>
                          <dd className="text-sm text-gray-900">
                            {isEditing ? (
                              <input
                                type="text"
                                value={formData.display_name}
                                onChange={(e) =>
                                  setFormData({
                                    ...formData,
                                    display_name: e.target.value,
                                  })
                                }
                                className="input"
                                placeholder="Enter display name"
                                aria-label="Display name"
                              />
                            ) : (
                              user.display_name || "Not provided"
                            )}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">
                            Phone Number
                          </dt>
                          <dd className="text-sm text-gray-900">
                            {isEditing ? (
                              <input
                                type="tel"
                                value={formData.phone_number}
                                onChange={(e) =>
                                  setFormData({
                                    ...formData,
                                    phone_number: e.target.value,
                                  })
                                }
                                className="input"
                                placeholder="Enter phone number"
                                aria-label="Phone number"
                              />
                            ) : (
                              user.phone_number || "Not provided"
                            )}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">Role</dt>
                          <dd className="text-sm text-gray-900">
                            {isEditing ? (
                              <select
                                value={formData.role}
                                onChange={(e) =>
                                  setFormData({
                                    ...formData,
                                    role: e.target.value,
                                  })
                                }
                                className="input"
                                aria-label="User role"
                              >
                                <option value="user">User</option>
                                <option value="moderator">Moderator</option>
                                <option value="admin">Admin</option>
                              </select>
                            ) : (
                              user.role
                            )}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">Status</dt>
                          <dd className="text-sm text-gray-900">
                            {isEditing ? (
                              <select
                                value={formData.status}
                                onChange={(e) =>
                                  setFormData({
                                    ...formData,
                                    status: e.target.value,
                                  })
                                }
                                className="input"
                                aria-label="User status"
                              >
                                <option value="active">Active</option>
                                <option value="inactive">Inactive</option>
                                <option value="suspended">Suspended</option>
                              </select>
                            ) : (
                              user.status
                            )}
                          </dd>
                        </div>
                      </dl>
                    </div>

                    <div>
                      <h4 className="text-sm font-medium text-gray-900 mb-3">
                        Activity
                      </h4>
                      <dl className="space-y-2">
                        <div>
                          <dt className="text-sm text-gray-500">
                            Reports Created
                          </dt>
                          <dd className="text-sm text-gray-900">
                            {user.statistics.reports_count}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">
                            Matches Found
                          </dt>
                          <dd className="text-sm text-gray-900">
                            {user.statistics.matches_count}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">
                            Account Created
                          </dt>
                          <dd className="text-sm text-gray-900">
                            {user.created_at
                              ? format(new Date(user.created_at), "PPP p")
                              : "Unknown"}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-sm text-gray-500">
                            Last Updated
                          </dt>
                          <dd className="text-sm text-gray-900">
                            {user.updated_at
                              ? format(new Date(user.updated_at), "PPP p")
                              : "Never"}
                          </dd>
                        </div>
                      </dl>
                    </div>
                  </div>

                  {/* Account Status */}
                  <div>
                    <h4 className="text-sm font-medium text-gray-900 mb-3">
                      Account Status
                    </h4>
                    <div className="flex items-center space-x-4">
                      <label className="flex items-center">
                        <input
                          type="checkbox"
                          checked={
                            isEditing ? formData.is_active : user.is_active
                          }
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              is_active: e.target.checked,
                            })
                          }
                          disabled={!isEditing}
                          className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                        />
                        <span className="ml-2 text-sm text-gray-700">
                          Account Active
                        </span>
                      </label>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center justify-between pt-6 border-t border-gray-200">
                    <div className="flex space-x-3">
                      {isEditing ? (
                        <>
                          <button
                            onClick={handleSave}
                            className="btn btn-primary"
                          >
                            Save Changes
                          </button>
                          <button
                            onClick={() => setIsEditing(false)}
                            className="btn btn-secondary"
                          >
                            Cancel
                          </button>
                        </>
                      ) : (
                        <button
                          onClick={() => setIsEditing(true)}
                          className="btn btn-primary"
                        >
                          Edit User
                        </button>
                      )}
                    </div>
                    <button onClick={onClose} className="btn btn-secondary">
                      Close
                    </button>
                  </div>
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
}
