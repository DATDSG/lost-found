import React, { useState, useEffect } from "react";
import type { NextPage } from "next";
import Head from "next/head";
import Link from "next/link";
import { useRouter } from "next/router";
import Image from "next/image";
import AdminGuard from "./AdminGuard";
import {
  HomeIcon,
  DocumentTextIcon,
  UserGroupIcon,
  ChartBarIcon,
  ClipboardDocumentListIcon,
  ExclamationTriangleIcon,
  Bars3Icon,
  XMarkIcon,
  ArrowRightOnRectangleIcon,
  UserIcon,
} from "@heroicons/react/24/outline";

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
  description?: string;
}

const AdminLayout: React.FC<LayoutProps> = ({
  children,
  title,
  description,
}) => {
  return (
    <AdminGuard>
      <AdminLayoutContent title={title} description={description}>
        {children}
      </AdminLayoutContent>
    </AdminGuard>
  );
};

const AdminLayoutContent: React.FC<LayoutProps> = ({
  children,
  title,
  description,
}) => {
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    // Get user info from localStorage
    const userData = localStorage.getItem("admin_user");
    if (userData) {
      setUser(JSON.parse(userData));
    }
  }, []);

  // Close profile popup when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (profileOpen) {
        const target = event.target as HTMLElement;
        if (!target.closest("[data-profile-dropdown]")) {
          setProfileOpen(false);
        }
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [profileOpen]);

  const handleLogout = () => {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin_user");
    router.push("/login");
  };

  const handleViewFullProfile = () => {
    // Navigate to user profile page or open profile modal
    router.push("/profile");
    setProfileOpen(false);
  };

  const navigation = [
    {
      name: "Dashboard",
      href: "/dashboard",
      icon: HomeIcon,
      current: router.pathname === "/dashboard",
    },
    {
      name: "Reports",
      href: "/reports",
      icon: DocumentTextIcon,
      current: router.pathname === "/reports",
    },
    {
      name: "Matching",
      href: "/matching",
      icon: ChartBarIcon,
      current: router.pathname === "/matching",
    },
    {
      name: "Users",
      href: "/users",
      icon: UserGroupIcon,
      current: router.pathname === "/users",
    },
    {
      name: "Audit Logs",
      href: "/audit-logs",
      icon: ClipboardDocumentListIcon,
      current: router.pathname === "/audit-logs",
    },
    {
      name: "Fraud Detection",
      href: "/fraud-detection",
      icon: ExclamationTriangleIcon,
      current: router.pathname === "/fraud-detection",
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <Head>
        <title>
          {title ? `${title} - Admin Panel` : "Admin Panel - Lost & Found"}
        </title>
        <meta
          name="description"
          content={description || "Lost & Found Admin Panel"}
        />
      </Head>

      {/* Mobile sidebar */}
      <div
        className={`fixed inset-0 z-50 lg:hidden ${
          sidebarOpen ? "block" : "hidden"
        }`}
      >
        <div
          className="fixed inset-0 bg-gray-600 bg-opacity-75"
          onClick={() => setSidebarOpen(false)}
        />
        <div className="relative flex w-64 flex-col bg-gradient-to-br from-blue-50 to-indigo-100 border-r border-blue-200">
          <div className="flex h-16 items-center justify-between px-4">
            <div className="flex items-center space-x-3">
              <div className="h-10 w-10 rounded-xl bg-white flex items-center justify-center shadow-lg border-2 border-blue-200 overflow-hidden">
                <Image
                  src="/App Logo.png"
                  alt="Lost & Found Logo"
                  width={32}
                  height={32}
                  className="rounded-lg object-contain"
                  priority
                  onError={(e) => {
                    const target = e.target as HTMLImageElement;
                    target.src = "/logo-fallback.svg";
                    target.onerror = null; // Prevent infinite loop
                  }}
                />
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-gray-800">
                  Lost & Found
                </span>
                <span className="text-xs text-gray-500">Admin Portal</span>
              </div>
            </div>
            <button
              type="button"
              className="text-gray-400 hover:text-gray-600 transition-colors duration-200"
              onClick={() => setSidebarOpen(false)}
              aria-label="Close sidebar"
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>
          <nav className="flex-1 px-4 pb-4">
            <ul className="space-y-2">
              {navigation.map((item) => (
                <li key={item.name}>
                  <Link
                    href={item.href}
                    className={`group flex items-center px-3 py-3 text-sm font-medium rounded-lg transition-all duration-200 ${
                      item.current
                        ? "bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg shadow-blue-500/25"
                        : "text-gray-700 hover:bg-white/50 hover:text-blue-700 hover:shadow-md"
                    }`}
                  >
                    <item.icon
                      className={`mr-3 h-5 w-5 flex-shrink-0 transition-colors duration-200 ${
                        item.current
                          ? "text-white"
                          : "text-gray-500 group-hover:text-blue-600"
                      }`}
                    />
                    {item.name}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
          <div className="border-t border-blue-200 p-4">
            <button
              onClick={handleLogout}
              className="flex w-full items-center px-3 py-3 text-sm font-medium text-gray-700 hover:bg-white/50 hover:text-red-600 rounded-lg transition-all duration-200"
            >
              <ArrowRightOnRectangleIcon className="mr-3 h-5 w-5 text-gray-500" />
              Sign Out
            </button>
          </div>
        </div>
      </div>

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
        <div className="flex flex-col flex-grow bg-gradient-to-br from-blue-50 to-indigo-100 border-r border-blue-200">
          <div className="flex h-16 items-center px-4">
            <div className="flex items-center space-x-3">
              <div className="h-10 w-10 rounded-xl bg-white flex items-center justify-center shadow-lg border-2 border-blue-200 overflow-hidden">
                <Image
                  src="/App Logo.png"
                  alt="Lost & Found Logo"
                  width={32}
                  height={32}
                  className="rounded-lg object-contain"
                  priority
                  onError={(e) => {
                    const target = e.target as HTMLImageElement;
                    target.src = "/logo-fallback.svg";
                    target.onerror = null; // Prevent infinite loop
                  }}
                />
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-gray-800">
                  Lost & Found
                </span>
                <span className="text-xs text-gray-500">Admin Portal</span>
              </div>
            </div>
          </div>
          <nav className="flex-1 px-4 pb-4">
            <ul className="space-y-2">
              {navigation.map((item) => (
                <li key={item.name}>
                  <Link
                    href={item.href}
                    className={`group flex items-center px-3 py-3 text-sm font-medium rounded-lg transition-all duration-200 ${
                      item.current
                        ? "bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg shadow-blue-500/25"
                        : "text-gray-700 hover:bg-white/50 hover:text-blue-700 hover:shadow-md"
                    }`}
                  >
                    <item.icon
                      className={`mr-3 h-5 w-5 flex-shrink-0 transition-colors duration-200 ${
                        item.current
                          ? "text-white"
                          : "text-gray-500 group-hover:text-blue-600"
                      }`}
                    />
                    {item.name}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
          <div className="border-t border-blue-200 p-4">
            <button
              onClick={handleLogout}
              className="flex w-full items-center px-3 py-3 text-sm font-medium text-gray-700 hover:bg-white/50 hover:text-red-600 rounded-lg transition-all duration-200"
            >
              <ArrowRightOnRectangleIcon className="mr-3 h-5 w-5 text-gray-500" />
              Sign Out
            </button>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Top bar */}
        <div className="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
          <button
            type="button"
            className="-m-2.5 p-2.5 text-gray-700 lg:hidden"
            onClick={() => setSidebarOpen(true)}
            aria-label="Open sidebar"
          >
            <Bars3Icon className="h-6 w-6" />
          </button>

          <div className="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
            <div className="flex flex-1 items-center">
              <h1 className="text-xl font-semibold text-gray-900">
                Admin Panel
              </h1>
            </div>
            <div className="flex items-center gap-x-4 lg:gap-x-6">
              {/* Profile dropdown */}
              <div className="relative" data-profile-dropdown>
                <button
                  onClick={() => setProfileOpen(!profileOpen)}
                  className="flex items-center gap-x-3 p-2 rounded-lg hover:bg-gray-50 transition-colors duration-200"
                >
                  <div className="h-8 w-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-md">
                    <span className="text-sm font-medium text-white">
                      {user?.name ? user.name.charAt(0).toUpperCase() : "A"}
                    </span>
                  </div>
                  <div className="text-left">
                    <p className="text-sm font-medium text-gray-900">
                      {user?.name || "Admin User"}
                    </p>
                    <p className="text-xs text-gray-500">
                      {user?.role || "Administrator"}
                    </p>
                  </div>
                </button>

                {/* Profile popup */}
                {profileOpen && (
                  <div className="absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-lg border border-gray-200 py-2 z-50">
                    <div className="px-4 py-3 border-b border-gray-100">
                      <div className="flex items-center space-x-3">
                        <div className="h-12 w-12 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-md">
                          <span className="text-lg font-medium text-white">
                            {user?.name
                              ? user.name.charAt(0).toUpperCase()
                              : "A"}
                          </span>
                        </div>
                        <div className="flex-1">
                          <p className="text-sm font-semibold text-gray-900">
                            {user?.name || "Admin User"}
                          </p>
                          <p className="text-xs text-gray-500">
                            {user?.email || "admin@example.com"}
                          </p>
                          <p className="text-xs text-blue-600 font-medium">
                            {user?.role || "Administrator"}
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* User Details Section */}
                    <div className="px-4 py-3 border-b border-gray-100">
                      <h4 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                        Account Information
                      </h4>
                      <div className="space-y-2">
                        <div className="flex justify-between text-xs">
                          <span className="text-gray-500">User ID:</span>
                          <span className="text-gray-900 font-mono">
                            {user?.id ? user.id.substring(0, 8) + "..." : "N/A"}
                          </span>
                        </div>
                        <div className="flex justify-between text-xs">
                          <span className="text-gray-500">Status:</span>
                          <span className="text-green-600 font-medium">
                            Active
                          </span>
                        </div>
                        <div className="flex justify-between text-xs">
                          <span className="text-gray-500">Last Login:</span>
                          <span className="text-gray-900">
                            {user?.last_login_at
                              ? new Date(
                                  user.last_login_at
                                ).toLocaleDateString()
                              : "N/A"}
                          </span>
                        </div>
                        <div className="flex justify-between text-xs">
                          <span className="text-gray-500">Member Since:</span>
                          <span className="text-gray-900">
                            {user?.created_at
                              ? new Date(user.created_at).toLocaleDateString()
                              : "N/A"}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Activity Summary */}
                    <div className="px-4 py-3 border-b border-gray-100">
                      <h4 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                        Activity Summary
                      </h4>
                      <div className="grid grid-cols-3 gap-2">
                        <div className="text-center">
                          <p className="text-lg font-bold text-blue-600">
                            {user?.reports_count || 0}
                          </p>
                          <p className="text-xs text-gray-500">Reports</p>
                        </div>
                        <div className="text-center">
                          <p className="text-lg font-bold text-green-600">
                            {user?.matches_count || 0}
                          </p>
                          <p className="text-xs text-gray-500">Matches</p>
                        </div>
                        <div className="text-center">
                          <p className="text-lg font-bold text-purple-600">
                            {user?.successful_matches || 0}
                          </p>
                          <p className="text-xs text-gray-500">Successful</p>
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="py-2">
                      <button
                        onClick={handleViewFullProfile}
                        className="flex w-full items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors duration-200"
                      >
                        <UserIcon className="mr-3 h-4 w-4 text-gray-400" />
                        View Full Profile
                      </button>
                      <hr className="my-2" />
                      <button
                        onClick={handleLogout}
                        className="flex w-full items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors duration-200"
                      >
                        <ArrowRightOnRectangleIcon className="mr-3 h-4 w-4 text-red-500" />
                        Sign Out
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Page content */}
        <main className="py-8">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;
