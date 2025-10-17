"use client";

import { createContext, useContext, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import toast from "react-hot-toast";

interface User {
  id: string;
  email: string;
  display_name: string | null;
  phone_number: string | null;
  avatar_url: string | null;
  role: string;
  is_active: boolean;
  created_at: string;
}

interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const token = localStorage.getItem("admin_token");
      if (!token) {
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${
          process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"
        }/api/v1/auth/me`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        const userData = await response.json();
        if (userData.role === "admin" || userData.role === "moderator") {
          setUser(userData);
        } else {
          localStorage.removeItem("admin_token");
          router.push("/login");
        }
      } else {
        localStorage.removeItem("admin_token");
        router.push("/login");
      }
    } catch (error) {
      console.error("Auth check failed:", error);
      localStorage.removeItem("admin_token");
      router.push("/login");
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (email: string, password: string) => {
    try {
      const response = await fetch(
        `${
          process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"
        }/api/v1/auth/login`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ email, password }),
        }
      );

      if (response.ok) {
        const data = await response.json();
        localStorage.setItem("admin_token", data.access_token);

        // Get user info
        const userResponse = await fetch(
          `${
            process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"
          }/api/v1/auth/me`,
          {
            headers: {
              Authorization: `Bearer ${data.access_token}`,
            },
          }
        );

        if (userResponse.ok) {
          const userData = await userResponse.json();
          if (userData.role === "admin" || userData.role === "moderator") {
            setUser(userData);
            router.push("/dashboard");
            toast.success("Login successful!");
          } else {
            throw new Error("Insufficient permissions");
          }
        }
      } else {
        const error = await response.json();
        throw new Error(error.detail || "Login failed");
      }
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Login failed");
      throw error;
    }
  };

  const logout = () => {
    localStorage.removeItem("admin_token");
    setUser(null);
    router.push("/login");
    toast.success("Logged out successfully");
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
