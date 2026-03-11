import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Iris Protocol',
  tagline: 'Privy, but trustless. Embedded agent wallets where every permission lives onchain.',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://iris-protocol.xyz',
  baseUrl: '/',

  organizationName: 'iris-protocol',
  projectName: 'iris-protocol',

  onBrokenLinks: 'throw',

  markdown: {
    mermaid: true,
  },

  themes: ['@docusaurus/theme-mermaid'],

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: 'docs',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: false,
    },
    navbar: {
      title: 'Iris Protocol',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Overview',
        },
        {
          to: '/docs/architecture',
          label: 'Architecture',
          position: 'left',
        },
        {
          to: '/docs/trust-tiers',
          label: 'Trust Tiers',
          position: 'left',
        },
        {
          to: '/docs/contracts/overview',
          label: 'Contracts',
          position: 'left',
        },
        {
          to: '/docs/api-reference',
          label: 'API Reference',
          position: 'left',
        },
        {
          to: '/docs/demo-guide',
          label: 'Demo Guide',
          position: 'left',
        },
        {
          href: 'https://github.com/iris-protocol',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Overview',
              to: '/docs/intro',
            },
            {
              label: 'Architecture',
              to: '/docs/architecture',
            },
            {
              label: 'Trust Tiers',
              to: '/docs/trust-tiers',
            },
          ],
        },
        {
          title: 'Contracts',
          items: [
            {
              label: 'Contract Overview',
              to: '/docs/contracts/overview',
            },
            {
              label: 'Caveat Enforcers',
              to: '/docs/contracts/caveat-enforcers',
            },
            {
              label: 'Reputation Gate',
              to: '/docs/contracts/reputation-gate',
            },
          ],
        },
        {
          title: 'Resources',
          items: [
            {
              label: 'Demo Guide',
              to: '/docs/demo-guide',
            },
            {
              label: 'API Reference',
              to: '/docs/api-reference',
            },
            {
              label: 'GitHub',
              href: 'https://github.com/iris-protocol',
            },
          ],
        },
      ],
      copyright: `Built at The Synthesis 2026 | Iris Protocol`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['solidity'],
    },
    mermaid: {
      theme: {
        dark: 'dark',
      },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
