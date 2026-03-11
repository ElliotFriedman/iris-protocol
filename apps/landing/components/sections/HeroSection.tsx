import IrisAperture from "@/components/ui/IrisAperture";

export default function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      {/* Background grid */}
      <div className="absolute inset-0 opacity-5">
        <div
          className="w-full h-full"
          style={{
            backgroundImage:
              "linear-gradient(rgba(123,47,190,0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(123,47,190,0.3) 1px, transparent 1px)",
            backgroundSize: "60px 60px",
          }}
        />
      </div>

      <div className="relative z-10 text-center px-6 max-w-5xl mx-auto">
        <div className="flex justify-center mb-10 float-animation">
          <IrisAperture tier={2} size={240} animated />
        </div>

        <h1 className="font-mono text-5xl md:text-7xl font-bold text-bone mb-6">
          Iris Protocol
        </h1>

        <p className="text-2xl md:text-3xl font-mono text-electric-cyan mb-4">
          Privy, but trustless.
        </p>

        <p className="text-lg md:text-xl text-bone/80 max-w-2xl mx-auto mb-4">
          Trustless payment infrastructure for AI agents.
        </p>

        <p className="text-lg md:text-xl text-ash max-w-2xl mx-auto mb-12">
          Every permission lives onchain. Every agent earns its trust.
        </p>

        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <a
            href="../app"
            className="px-8 py-4 bg-iris-purple hover:bg-iris-purple/80 text-bone font-semibold rounded-lg transition-all hover:shadow-lg hover:shadow-iris-purple/20 text-lg"
          >
            View Demo
          </a>
          <a
            href="../docs"
            className="px-8 py-4 border border-electric-cyan/30 hover:border-electric-cyan text-electric-cyan font-semibold rounded-lg transition-all hover:bg-electric-cyan/5 text-lg"
          >
            Read Docs
          </a>
        </div>
      </div>

      {/* Bottom fade — solid overlay, not gradient on large surface */}
      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-void to-transparent" />
    </section>
  );
}
