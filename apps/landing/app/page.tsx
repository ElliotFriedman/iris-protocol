"use client";

import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";
import HeroSection from "@/components/sections/HeroSection";
import TrustProblemSection from "@/components/sections/TrustProblemSection";
import ConfigureIrisSection from "@/components/sections/ConfigureIrisSection";
import StandardsSection from "@/components/sections/StandardsSection";
import ReputationSection from "@/components/sections/ReputationSection";
import BuiltBySection from "@/components/sections/BuiltBySection";

export default function LandingPage() {
  return (
    <main className="min-h-screen">
      <Navbar />
      <HeroSection />
      <TrustProblemSection />
      <ConfigureIrisSection />
      <StandardsSection />
      <ReputationSection />
      <BuiltBySection />
      <Footer />
    </main>
  );
}
