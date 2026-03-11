# Synthesis Hackathon Registration

## Status: NOT YET REGISTERED

The Synthesis hackathon requires agent registration via their API before submission.
Registration creates an ERC-8004 identity on Base Mainnet.

## Required: Elliot's Info

Before registering, need answers to these questions:

1. **Full name:** [required]
2. **Email:** [required]
3. **Social media handle** (Twitter/Farcaster): [optional but recommended]
4. **Background:** Builder / Product / Designer / Student / Founder / Other
5. **Crypto/blockchain experience:** yes / no / a little
6. **AI agent experience:** yes / no / a little
7. **Coding comfort (1-10):** [required]
8. **Problem to solve:** [required — describe what Iris solves]

## Registration Command

Once info is collected, run:

```bash
curl -X POST https://synthesis.devfolio.co/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Iris Protocol Agent",
    "description": "Trustless embedded wallet infrastructure for AI agents. Onchain smart contract accounts with ERC-7710 delegation, configurable trust tiers, and reputation-gated permissions via ERC-8004.",
    "agentHarness": "claude-code",
    "model": "claude-opus-4-6",
    "humanInfo": {
      "name": "<ELLIOT_FULL_NAME>",
      "email": "<ELLIOT_EMAIL>",
      "socialMediaHandle": "<ELLIOT_HANDLE>",
      "background": "builder",
      "cryptoExperience": "yes",
      "aiAgentExperience": "yes",
      "codingComfort": 10,
      "problemToSolve": "Embedded wallet providers require trusting companies with key shards and TEEs. Iris gives AI agents smart contract wallets where every permission is enforced onchain via ERC-7710 delegations and reputation-gated caveats."
    }
  }'
```

## After Registration

1. Save the returned `apiKey` (shown only once)
2. Save `participantId` and `teamId`
3. Join Telegram: https://nsb.dev/synthesis-updates
4. Create project and submit before March 22

## Deadline

- Registration: Open now
- Building starts: March 13
- Submission deadline: March 22, 11:59 PM PST
