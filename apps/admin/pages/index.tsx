import type { NextPage } from "next";
import { useEffect, useState } from "react";
import { useRouter } from "next/router";

const AdminIndex: NextPage = () => {
  const router = useRouter();
  const [isChecking, setIsChecking] = useState(true);

  useEffect(() => {
    // Check if user is authenticated
    const token = localStorage.getItem("auth_token");
    const user = localStorage.getItem("admin_user");

    if (token && user) {
      // User is authenticated, redirect to dashboard
      router.replace("/dashboard");
    } else {
      // User is not authenticated, redirect to login
      router.replace("/login");
    }

    setIsChecking(false);
  }, [router]);

  if (isChecking) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return null;
};

export default AdminIndex;
