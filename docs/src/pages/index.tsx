import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

type FeatureItem = {
  title: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Trustless by Default',
    description: (
      <>
        No TEEs. No key custodians. No offchain policy engines. Every permission
        is enforced onchain via ERC-7710 caveat enforcers.
      </>
    ),
  },
  {
    title: 'Configurable Trust Tiers',
    description: (
      <>
        Set the aperture: View Only, Supervised, Autonomous, or Full Delegation.
        Each tier bundles the right caveat enforcers for your risk tolerance.
      </>
    ),
  },
  {
    title: 'Reputation-Gated Access',
    description: (
      <>
        The novel ReputationGateEnforcer checks ERC-8004 reputation scores in
        real-time. Misbehaving agents lose access automatically.
      </>
    ),
  },
];

function Feature({title, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md" style={{paddingTop: '2rem'}}>
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <p style={{fontSize: '1.1rem', opacity: 0.9, maxWidth: '640px', margin: '0 auto 1.5rem'}}>
          Smart contract wallets for AI agents with ERC-7710 delegation,
          configurable trust tiers, and reputation-gated permissions via ERC-8004.
          No TEEs. No key custodians. No offchain policy engines.
        </p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro">
            Read the Docs
          </Link>
          <Link
            className="button button--secondary button--lg"
            to="/docs/demo-guide"
            style={{marginLeft: '1rem'}}>
            Demo Guide
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Trustless Embedded Agent Wallets"
      description="Privy, but trustless. Embedded agent wallets where every permission lives onchain.">
      <HomepageHeader />
      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              {FeatureList.map((props, idx) => (
                <Feature key={idx} {...props} />
              ))}
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
