import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Iris Protocol — Trustless Embedded Agent Wallets",
  description: "Privy, but trustless. Embedded agent wallets where every permission lives onchain.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
