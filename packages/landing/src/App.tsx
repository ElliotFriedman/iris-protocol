import './App.css';
import IrisAperture from './components/IrisAperture';
import { useScrollReveal } from './components/useScrollReveal';

function App() {
  useScrollReveal();

  return (
    <>
      {/* ===== HERO ===== */}
      <section className="hero">
        <div className="hero-aperture">
          <IrisAperture size={300} tier={2} animate animationDuration={4000} />
        </div>
        <h1 className="hero-title">iris protocol</h1>
        <p className="hero-tagline">
          Privy, but trustless. Embedded agent wallets where every permission
          lives onchain.
        </p>
        <div className="hero-ctas">
          <a href="#demo" className="btn btn-primary">
            Try the Demo <span aria-hidden="true">&rarr;</span>
          </a>
          <a href="#docs" className="btn btn-outline">
            Read the Docs <span aria-hidden="true">&rarr;</span>
          </a>
        </div>
        <div className="scroll-indicator" aria-hidden="true">
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <polyline points="6 9 12 15 18 9" />
          </svg>
        </div>
      </section>

      {/* ===== THE PROBLEM ===== */}
      <section className="problem">
        <div className="section-inner">
          <h2 className="section-heading fade-in">
            Your agent needs a wallet.
            <br />
            Who holds the keys?
          </h2>
          <div className="comparison-grid stagger">
            <div className="comparison-card legacy fade-in">
              <h3>Embedded wallets today</h3>
              <ul className="comparison-list">
                <li>
                  <span className="dot dot-red" />
                  TEE-managed key custody
                </li>
                <li>
                  <span className="dot dot-red" />
                  Key shards across providers
                </li>
                <li>
                  <span className="dot dot-red" />
                  Offchain policy engine
                </li>
                <li>
                  <span className="dot dot-red" />
                  Company dependency
                </li>
              </ul>
            </div>
            <div className="comparison-card iris-card fade-in">
              <h3>Iris Protocol</h3>
              <ul className="comparison-list">
                <li>
                  <span className="dot dot-mint" />
                  Smart contract account
                </li>
                <li>
                  <span className="dot dot-mint" />
                  Onchain caveats
                </li>
                <li>
                  <span className="dot dot-mint" />
                  ERC-8004 identity
                </li>
                <li>
                  <span className="dot dot-mint" />
                  No company dependency
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* ===== TRUST TIERS ===== */}
      <section className="tiers">
        <div className="section-inner">
          <h2 className="section-heading fade-in">Configure the aperture.</h2>
          <div className="tiers-grid stagger">
            <div className="tier-card fade-in">
              <div className="tier-aperture">
                <IrisAperture size={100} tier={0} color="#8A8A9A" />
              </div>
              <div className="tier-label">Tier 0</div>
              <div className="tier-name">View Only</div>
              <ul className="tier-features">
                <li>Read public state</li>
                <li>No signing allowed</li>
                <li>Zero trust surface</li>
              </ul>
            </div>
            <div className="tier-card fade-in">
              <div className="tier-aperture">
                <IrisAperture size={100} tier={1} color="#00F0FF" />
              </div>
              <div className="tier-label">Tier 1</div>
              <div className="tier-name">Scoped Signer</div>
              <ul className="tier-features">
                <li>Sign caveated txns</li>
                <li>Spend limits enforced</li>
                <li>Whitelist-only targets</li>
              </ul>
            </div>
            <div className="tier-card fade-in">
              <div className="tier-aperture">
                <IrisAperture size={100} tier={2} color="#7B2FBE" />
              </div>
              <div className="tier-label">Tier 2</div>
              <div className="tier-name">Delegated Agent</div>
              <ul className="tier-features">
                <li>Broader signing scope</li>
                <li>Dynamic spend limits</li>
                <li>Cross-protocol calls</li>
              </ul>
            </div>
            <div className="tier-card fade-in">
              <div className="tier-aperture">
                <IrisAperture size={100} tier={3} color="#FFB800" />
              </div>
              <div className="tier-label">Tier 3</div>
              <div className="tier-name">Autonomous</div>
              <ul className="tier-features">
                <li>Full signing authority</li>
                <li>Self-managed caveats</li>
                <li>Reputation-gated only</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* ===== REPUTATION GATE ===== */}
      <section className="reputation">
        <div className="section-inner">
          <h2 className="section-heading fade-in">
            A network-level immune system.
          </h2>
          <div className="reputation-flow fade-in">
            <div className="flow-node agent">Agent</div>
            <span className="flow-arrow animated">&rarr;</span>
            <div className="flow-node enforcer">
              ReputationGate
              <br />
              Enforcer
              <br />
              <span style={{ fontSize: '0.7rem', opacity: 0.7 }}>
                queries ERC-8004
              </span>
            </div>
            <span className="flow-arrow animated">&rarr;</span>
            <div className="flow-result-row">
              <div className="flow-node pass">Pass</div>
              <div className="flow-node block">Block</div>
            </div>
          </div>
          <div className="reputation-description fade-in">
            <p>
              The <strong>ReputationGateEnforcer</strong> is a caveat enforcer
              that queries an agent's onchain ERC-8004 reputation score before
              allowing any delegation to execute.
            </p>
            <p>
              Reputation degrades dynamically: failed transactions, revoked
              delegations, and community flags all reduce an agent's trust
              score. Fall below threshold and the aperture closes automatically.
            </p>
            <p>
              No governance votes. No multisig approvals. Just math.
            </p>
          </div>
        </div>
      </section>

      {/* ===== ERC STACK ===== */}
      <section className="erc-stack">
        <div className="section-inner">
          <h2 className="section-heading fade-in">Built on the standards.</h2>
          <div className="erc-badges stagger">
            {[
              'ERC-4337',
              'ERC-7710',
              'ERC-7715',
              'ERC-8004',
              'ERC-8128',
              'EIP-7702',
            ].map((erc) => (
              <div key={erc} className="erc-badge fade-in">
                {erc}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== TEAM ===== */}
      <section className="team">
        <div className="section-inner">
          <p className="team-intro fade-in">Built at The Synthesis by</p>
          <div className="team-card fade-in">
            <h3 className="team-name">Elliot</h3>
            <div className="team-stats">
              <div className="stat">
                <span className="stat-value">67+</span>
                <span className="stat-label">Contracts deployed</span>
              </div>
              <div className="stat">
                <span className="stat-value">$2B+</span>
                <span className="stat-label">TVL secured</span>
              </div>
              <div className="stat">
                <span className="stat-value">0</span>
                <span className="stat-label">Losses</span>
              </div>
            </div>
            <p className="team-detail">Stanford Blockchain Review</p>
          </div>
        </div>
      </section>

      {/* ===== FOOTER ===== */}
      <footer className="footer">
        <div className="footer-inner">
          <span className="footer-wordmark">iris protocol</span>
          <div className="footer-links">
            <a
              href="https://github.com"
              target="_blank"
              rel="noopener noreferrer"
            >
              GitHub
            </a>
            <a href="#demo">Demo App</a>
          </div>
        </div>
      </footer>
    </>
  );
}

export default App;
