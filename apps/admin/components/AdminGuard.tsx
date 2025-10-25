import { useEffect, useState } from "react";
import { useRouter } from "next/router";

interface AdminGuardProps {
  children: React.ReactNode;
}

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
}

export default function AdminGuard({ children }: AdminGuardProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthorized, setIsAuthorized] = useState(false);
  const [isClient, setIsClient] = useState(false);
  const router = useRouter();

  useEffect(() => {
    setIsClient(true);
  }, []);

  useEffect(() => {
    if (!isClient) return;

    const checkAdminAccess = async () => {
      try {
        // Check if user is logged in
        const token = localStorage.getItem("auth_token");
        const userData = localStorage.getItem("admin_user");

        if (!token || !userData) {
          router.push("/login");
          return;
        }

        // Parse user data
        const user: User = JSON.parse(userData);

        // Check if user is admin
        if (user.role !== "admin") {
          // Clear invalid data
          localStorage.removeItem("auth_token");
          localStorage.removeItem("admin_user");

          // Redirect to login with error message
          router.push("/login?error=access_denied");
          return;
        }

        // Verify token is still valid by calling /me endpoint
        try {
          const response = await fetch(
            `${
              process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"
            }/v1/auth/me`,
            {
              headers: {
                Authorization: `Bearer ${token}`,
                "Content-Type": "application/json",
              },
            }
          );

          if (!response.ok) {
            // Token is invalid
            localStorage.removeItem("auth_token");
            localStorage.removeItem("admin_user");
            router.push("/login");
            return;
          }

          const currentUser = await response.json();

          // Double-check role from server
          if (currentUser.role !== "admin") {
            localStorage.removeItem("auth_token");
            localStorage.removeItem("admin_user");
            router.push("/login?error=access_denied");
            return;
          }
        } catch (serverError) {
          console.warn(
            "Server verification failed, but allowing access based on local data:",
            serverError
          );
          // If server verification fails, still allow access based on local data
          // This prevents blocking users due to network issues
        }

        setIsAuthorized(true);
      } catch (error) {
        console.error("Admin access check failed:", error);
        localStorage.removeItem("auth_token");
        localStorage.removeItem("admin_user");
        router.push("/login");
      } finally {
        setIsLoading(false);
      }
    };

    checkAdminAccess();
  }, [router, isClient]);

  if (!isClient || isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Verifying access...</p>
        </div>
      </div>
    );
  }

  if (!isAuthorized) {
    return null; // Will redirect to login
  }

  return <>{children}</>;
}
