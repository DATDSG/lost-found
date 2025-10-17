"use client";

import { useState } from "react";
import { Sidebar, TopBar } from "@/components/layout/Header";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  const handleSidebarToggle = () => {
    setSidebarCollapsed(!sidebarCollapsed);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Sidebar isCollapsed={sidebarCollapsed} onToggle={handleSidebarToggle} />
      <div className={`transition-all duration-300 ${
        sidebarCollapsed ? "lg:pl-16" : "lg:pl-64"
      }`}>
        <TopBar 
          onSidebarToggle={handleSidebarToggle} 
          sidebarCollapsed={sidebarCollapsed}
        />
        <main className="py-6">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
