"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { LoadingSpinner } from "@/components/ui/loading-spinner";

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Public routes that don't require auth
    const publicRoutes = ["/login", "/"];

    if (publicRoutes.includes(pathname)) {
      setIsLoading(false);
      return;
    }

    // Check if user has auth token
    const token = localStorage.getItem("admin_token");

    if (!token) {
      // No token, redirect to login
      router.push("/login");
      setIsLoading(false);
      return;
    }

    // Validate JWT token format and expiry
    try {
      // JWT format: header.payload.signature
      const parts = token.split(".");
      if (parts.length !== 3) {
        throw new Error("Invalid token format");
      }

      // Decode the payload (second part)
      const payload = JSON.parse(atob(parts[1]));

      // Check expiry (JWT exp is in seconds, not milliseconds)
      if (payload.exp && payload.exp * 1000 < Date.now()) {
        // Token expired
        localStorage.removeItem("admin_token");
        router.push("/login");
        setIsLoading(false);
        return;
      }

      // Token is valid
      setIsAuthenticated(true);
      setIsLoading(false);
    } catch (err) {
      // Invalid token
      console.error("Token validation error:", err);
      localStorage.removeItem("admin_token");
      router.push("/login");
      setIsLoading(false);
    }
  }, [pathname, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return <>{children}</>;
}
