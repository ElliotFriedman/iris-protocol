import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'intro',
      label: 'Overview',
    },
    {
      type: 'doc',
      id: 'getting-started',
      label: 'Getting Started',
    },
    {
      type: 'doc',
      id: 'architecture',
      label: 'Architecture',
    },
    {
      type: 'doc',
      id: 'trust-tiers',
      label: 'Trust Tiers',
    },
    {
      type: 'category',
      label: 'Contracts',
      collapsed: false,
      items: [
        'contracts/overview',
        'contracts/iris-account',
        'contracts/caveat-enforcers',
        'contracts/reputation-gate',
        'contracts/tier-presets',
      ],
    },
    {
      type: 'doc',
      id: 'identity',
      label: 'Identity & Reputation',
    },
    {
      type: 'doc',
      id: 'demo-guide',
      label: 'Demo Guide',
    },
    {
      type: 'doc',
      id: 'api-reference',
      label: 'API Reference',
    },
  ],
};

export default sidebars;
