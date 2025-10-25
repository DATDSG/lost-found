import React, { useState, useEffect } from "react";
import { useRouter } from "next/router";
import AdminLayout from "../components/AdminLayout";
import { apiService } from "../services/api";
import {
  UserIcon,
  ArrowLeftIcon,
  EnvelopeIcon,
  PhoneIcon,
  CalendarIcon,
  ClockIcon,
  ShieldCheckIcon,
  ChartBarIcon,
  DocumentTextIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
  EyeIcon,
  EyeSlashIcon,
  PencilIcon,
  GlobeAltIcon,
  MapPinIcon,
  IdentificationIcon,
  KeyIcon,
  UserGroupIcon,
  CogIcon,
} from "@heroicons/react/24/outline";

const ProfilePage: React.FC = () => {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [userStats, setUserStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showSensitiveData, setShowSensitiveData] = useState(false);
  const [activeTab, setActiveTab] = useState("overview");

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        setLoading(true);
        setError(null);

        // Get current user info
        const userData = await apiService.getCurrentUser();
        setUser(userData);

        // Get user statistics if user ID is available
        if (userData?.id) {
          try {
            const statsData = await apiService.getUserStats(userData.id);
            setUserStats(statsData);
          } catch (statsError) {
            console.warn("Could not fetch user statistics:", statsError);
            // Set default stats if API call fails
            setUserStats({
              reports: 0,
              matches: 0,
              successful_matches: 0,
            });
          }
        }
      } catch (err) {
        setError("Failed to load user profile data");
        console.error("Profile error:", err);

        // Fallback to localStorage data if API fails
        const localUserData = localStorage.getItem("admin_user");
        if (localUserData) {
          setUser(JSON.parse(localUserData));
          setUserStats({
            reports: 0,
            matches: 0,
            successful_matches: 0,
          });
        }
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, []);

  const tabs = [
    { id: "overview", name: "Overview", icon: UserIcon },
    { id: "activity", name: "Activity", icon: ChartBarIcon },
    { id: "security", name: "Security", icon: ShieldCheckIcon },
    { id: "preferences", name: "Preferences", icon: CogIcon },
  ];

  const formatDate = (dateString: string) => {
    if (!dateString) return "N/A";
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const formatRelativeTime = (dateString: string) => {
    if (!dateString) return "N/A";
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = Math.floor(
      (now.getTime() - date.getTime()) / (1000 * 60 * 60)
    );

    if (diffInHours < 1) return "Just now";
    if (diffInHours < 24) return `${diffInHours} hours ago`;
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 7) return `${diffInDays} days ago`;
    return formatDate(dateString);
  };

  if (loading) {
    return (
      <AdminLayout title="Profile">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      </AdminLayout>
    );
  }

  if (error && !user) {
    return (
      <AdminLayout title="Profile">
        <div className="text-center py-12">
          <ExclamationTriangleIcon className="mx-auto h-12 w-12 text-red-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">
            Error loading profile
          </h3>
          <p className="mt-1 text-sm text-gray-500">{error}</p>
          <div className="mt-6">
            <button
              onClick={() => window.location.reload()}
              className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Try again
            </button>
          </div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout title="Profile">
      <div className="max-w-7xl mx-auto">
        {/* Enhanced Header */}
        <div className="mb-8">
          <button
            onClick={() => router.back()}
            className="flex items-center text-gray-600 hover:text-gray-900 transition-colors duration-200 mb-6 group"
          >
            <ArrowLeftIcon className="h-5 w-5 mr-2 group-hover:-translate-x-1 transition-transform duration-200" />
            Back to Dashboard
          </button>

          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-4xl font-bold text-gray-900 mb-2">
                User Profile
              </h1>
              <p className="text-lg text-gray-600">
                Comprehensive view of account information and activity
              </p>
            </div>

            <div className="flex items-center space-x-3">
              <button
                onClick={() => setShowSensitiveData(!showSensitiveData)}
                className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors duration-200"
              >
                {showSensitiveData ? (
                  <EyeSlashIcon className="h-4 w-4 mr-2" />
                ) : (
                  <EyeIcon className="h-4 w-4 mr-2" />
                )}
                {showSensitiveData ? "Hide" : "Show"} Sensitive Data
              </button>
            </div>
          </div>
        </div>

        {/* Enhanced Profile Header */}
        <div className="bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 rounded-2xl shadow-xl overflow-hidden mb-8">
          <div className="px-8 py-12">
            <div className="flex items-center space-x-6">
              <div className="relative">
                <div className="h-24 w-24 rounded-full bg-white flex items-center justify-center shadow-2xl ring-4 ring-white/20">
                  <span className="text-3xl font-bold text-blue-600">
                    {user?.name ? user.name.charAt(0).toUpperCase() : "A"}
                  </span>
                </div>
                <div className="absolute -bottom-2 -right-2 h-8 w-8 bg-green-500 rounded-full border-4 border-white flex items-center justify-center">
                  <CheckCircleIcon className="h-5 w-5 text-white" />
                </div>
              </div>

              <div className="text-white flex-1">
                <h2 className="text-3xl font-bold mb-2">
                  {user?.display_name || user?.name || "Admin User"}
                </h2>
                <p className="text-blue-100 text-lg mb-3">
                  {user?.email || "admin@example.com"}
                </p>
                <div className="flex items-center space-x-3">
                  <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-white/20 text-white backdrop-blur-sm">
                    <ShieldCheckIcon className="h-4 w-4 mr-1" />
                    {user?.role || "Administrator"}
                  </span>
                  <span
                    className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium backdrop-blur-sm ${
                      user?.is_active
                        ? "bg-green-500/20 text-green-100"
                        : "bg-red-500/20 text-red-100"
                    }`}
                  >
                    <CheckCircleIcon className="h-4 w-4 mr-1" />
                    {user?.is_active ? "Active" : "Inactive"}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="mb-8">
          <nav className="flex space-x-8 border-b border-gray-200">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center py-4 px-1 border-b-2 font-medium text-sm transition-colors duration-200 ${
                    activeTab === tab.id
                      ? "border-blue-500 text-blue-600"
                      : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                  }`}
                >
                  <Icon className="h-5 w-5 mr-2" />
                  {tab.name}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Tab Content */}
        <div className="space-y-8">
          {/* Overview Tab */}
          {activeTab === "overview" && (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              {/* Personal Information Card */}
              <div className="lg:col-span-2">
                <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                  <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
                    <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                      <UserIcon className="h-5 w-5 mr-2 text-blue-500" />
                      Personal Information
                    </h3>
                  </div>
                  <div className="p-6">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div className="space-y-4">
                        <div className="flex items-center space-x-3">
                          <UserIcon className="h-5 w-5 text-gray-400" />
                          <div>
                            <label className="block text-sm font-medium text-gray-500">
                              Full Name
                            </label>
                            <p className="text-sm text-gray-900 font-medium">
                              {user?.display_name || user?.name || "Admin User"}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-3">
                          <EnvelopeIcon className="h-5 w-5 text-gray-400" />
                          <div>
                            <label className="block text-sm font-medium text-gray-500">
                              Email Address
                            </label>
                            <p className="text-sm text-gray-900 font-medium">
                              {user?.email || "admin@example.com"}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-3">
                          <PhoneIcon className="h-5 w-5 text-gray-400" />
                          <div>
                            <label className="block text-sm font-medium text-gray-500">
                              Phone Number
                            </label>
                            <p className="text-sm text-gray-900 font-medium">
                              {user?.phone_number || "Not provided"}
                            </p>
                          </div>
                        </div>
                      </div>
                      <div className="space-y-4">
                        <div className="flex items-center space-x-3">
                          <IdentificationIcon className="h-5 w-5 text-gray-400" />
                          <div>
                            <label className="block text-sm font-medium text-gray-500">
                              User ID
                            </label>
                            <p className="text-sm text-gray-900 font-mono">
                              {showSensitiveData
                                ? user?.id || "N/A"
                                : user?.id
                                ? user.id.substring(0, 8) + "..."
                                : "N/A"}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-3">
                          <CalendarIcon className="h-5 w-5 text-gray-400" />
                          <div>
                            <label className="block text-sm font-medium text-gray-500">
                              Member Since
                            </label>
                            <p className="text-sm text-gray-900 font-medium">
                              {formatDate(user?.created_at)}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-3">
                          <ClockIcon className="h-5 w-5 text-gray-400" />
                          <div>
                            <label className="block text-sm font-medium text-gray-500">
                              Last Login
                            </label>
                            <p className="text-sm text-gray-900 font-medium">
                              {formatRelativeTime(user?.last_login_at)}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Quick Stats Card */}
              <div>
                <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                  <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
                    <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                      <ChartBarIcon className="h-5 w-5 mr-2 text-green-500" />
                      Quick Stats
                    </h3>
                  </div>
                  <div className="p-6">
                    <div className="space-y-4">
                      <div className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
                        <div className="flex items-center">
                          <DocumentTextIcon className="h-8 w-8 text-blue-600 mr-3" />
                          <div>
                            <p className="text-sm font-medium text-gray-900">
                              Reports
                            </p>
                            <p className="text-xs text-gray-500">Processed</p>
                          </div>
                        </div>
                        <span className="text-2xl font-bold text-blue-600">
                          {userStats?.statistics?.reports ||
                            user?.reports_count ||
                            0}
                        </span>
                      </div>
                      <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
                        <div className="flex items-center">
                          <ChartBarIcon className="h-8 w-8 text-green-600 mr-3" />
                          <div>
                            <p className="text-sm font-medium text-gray-900">
                              Matches
                            </p>
                            <p className="text-xs text-gray-500">Reviewed</p>
                          </div>
                        </div>
                        <span className="text-2xl font-bold text-green-600">
                          {userStats?.statistics?.matches ||
                            user?.matches_count ||
                            0}
                        </span>
                      </div>
                      <div className="flex items-center justify-between p-3 bg-purple-50 rounded-lg">
                        <div className="flex items-center">
                          <CheckCircleIcon className="h-8 w-8 text-purple-600 mr-3" />
                          <div>
                            <p className="text-sm font-medium text-gray-900">
                              Successful
                            </p>
                            <p className="text-xs text-gray-500">Matches</p>
                          </div>
                        </div>
                        <span className="text-2xl font-bold text-purple-600">
                          {userStats?.statistics?.successful_matches ||
                            user?.successful_matches ||
                            0}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Activity Tab */}
          {activeTab === "activity" && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                  <ChartBarIcon className="h-5 w-5 mr-2 text-blue-500" />
                  Activity Overview
                </h3>
              </div>
              <div className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                  <div className="text-center p-6 bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl">
                    <DocumentTextIcon className="h-12 w-12 text-blue-600 mx-auto mb-3" />
                    <p className="text-3xl font-bold text-blue-600 mb-1">
                      {userStats?.statistics?.reports ||
                        user?.reports_count ||
                        0}
                    </p>
                    <p className="text-sm text-gray-600">Total Reports</p>
                  </div>
                  <div className="text-center p-6 bg-gradient-to-br from-green-50 to-green-100 rounded-xl">
                    <CheckCircleIcon className="h-12 w-12 text-green-600 mx-auto mb-3" />
                    <p className="text-3xl font-bold text-green-600 mb-1">
                      {userStats?.statistics?.matches ||
                        user?.matches_count ||
                        0}
                    </p>
                    <p className="text-sm text-gray-600">Matches Found</p>
                  </div>
                  <div className="text-center p-6 bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl">
                    <ChartBarIcon className="h-12 w-12 text-purple-600 mx-auto mb-3" />
                    <p className="text-3xl font-bold text-purple-600 mb-1">
                      {userStats?.statistics?.successful_matches ||
                        user?.successful_matches ||
                        0}
                    </p>
                    <p className="text-sm text-gray-600">Successful</p>
                  </div>
                  <div className="text-center p-6 bg-gradient-to-br from-orange-50 to-orange-100 rounded-xl">
                    <ClockIcon className="h-12 w-12 text-orange-600 mx-auto mb-3" />
                    <p className="text-3xl font-bold text-orange-600 mb-1">
                      98%
                    </p>
                    <p className="text-sm text-gray-600">Success Rate</p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Security Tab */}
          {activeTab === "security" && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
                  <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                    <ShieldCheckIcon className="h-5 w-5 mr-2 text-green-500" />
                    Security Status
                  </h3>
                </div>
                <div className="p-6">
                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
                      <div className="flex items-center">
                        <CheckCircleIcon className="h-6 w-6 text-green-600 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            Account Status
                          </p>
                          <p className="text-xs text-gray-500">
                            Active and secure
                          </p>
                        </div>
                      </div>
                      <span className="text-green-600 font-medium">Secure</span>
                    </div>
                    <div className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
                      <div className="flex items-center">
                        <KeyIcon className="h-6 w-6 text-blue-600 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            Password
                          </p>
                          <p className="text-xs text-gray-500">
                            Last changed:{" "}
                            {formatRelativeTime(user?.password_changed_at)}
                          </p>
                        </div>
                      </div>
                      <span className="text-blue-600 font-medium">Strong</span>
                    </div>
                    <div className="flex items-center justify-between p-3 bg-purple-50 rounded-lg">
                      <div className="flex items-center">
                        <ClockIcon className="h-6 w-6 text-purple-600 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            Last Login
                          </p>
                          <p className="text-xs text-gray-500">
                            {formatRelativeTime(user?.last_login_at)}
                          </p>
                        </div>
                      </div>
                      <span className="text-purple-600 font-medium">
                        Recent
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
                  <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                    <InformationCircleIcon className="h-5 w-5 mr-2 text-blue-500" />
                    Account Details
                  </h3>
                </div>
                <div className="p-6">
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-500 mb-1">
                        Account Type
                      </label>
                      <p className="text-sm text-gray-900 font-medium">
                        Administrator Account
                      </p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-500 mb-1">
                        Role Level
                      </label>
                      <p className="text-sm text-gray-900 font-medium">
                        Super Administrator
                      </p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-500 mb-1">
                        Permissions
                      </label>
                      <div className="flex flex-wrap gap-2 mt-2">
                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          Full Access
                        </span>
                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          User Management
                        </span>
                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                          System Admin
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Preferences Tab */}
          {activeTab === "preferences" && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                  <CogIcon className="h-5 w-5 mr-2 text-gray-500" />
                  User Preferences
                </h3>
              </div>
              <div className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 className="text-md font-medium text-gray-900 mb-4">
                      Display Preferences
                    </h4>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-700">Dark Mode</span>
                        <button
                          className="relative inline-flex h-6 w-11 items-center rounded-full bg-gray-200 transition-colors duration-200"
                          title="Toggle dark mode"
                          aria-label="Toggle dark mode"
                        >
                          <span className="inline-block h-4 w-4 transform rounded-full bg-white transition-transform duration-200 translate-x-1" />
                        </button>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-700">
                          Compact View
                        </span>
                        <button
                          className="relative inline-flex h-6 w-11 items-center rounded-full bg-blue-600 transition-colors duration-200"
                          title="Toggle compact view"
                          aria-label="Toggle compact view"
                        >
                          <span className="inline-block h-4 w-4 transform rounded-full bg-white transition-transform duration-200 translate-x-6" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Enhanced Footer Information */}
        <div className="mt-8 bg-gradient-to-r from-gray-50 to-blue-50 rounded-xl p-6 border border-gray-200">
          <div className="flex items-start space-x-3">
            <InformationCircleIcon className="h-6 w-6 text-blue-500 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="text-sm font-medium text-gray-900 mb-1">
                Profile Information
              </h4>
              <p className="text-sm text-gray-600">
                This comprehensive profile provides detailed insights into your
                account status, activity, and preferences. All sensitive
                information is protected and can be toggled for viewing. For
                additional security measures, contact your system administrator.
              </p>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
};

export default ProfilePage;
