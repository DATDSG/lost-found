import "./globals.css";
import { Inter } from "next/font/google";
import { Providers } from "./providers";
import { AuthProvider } from "../lib/auth";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "Lost & Found Admin Panel",
  description: "Administrative interface for Lost & Found application",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          <AuthProvider>{children}</AuthProvider>
        </Providers>
      </body>
    </html>
  );
}
