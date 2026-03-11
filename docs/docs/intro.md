---
sidebar_position: 1
slug: /intro
title: Iris Protocol
---

# Iris Protocol

> Privy, but trustless. Embedded agent wallets where every permission lives onchain.

## What is Iris?

Iris gives AI agents their own smart contract wallets with configurable trust levels. Set the aperture: let your agent spend $100/day autonomously, queue anything above for your approval, and revoke access instantly.

All permissions enforced onchain via ERC-7710 delegations. Agent identity verified via ERC-8004. No TEEs. No key custodians. No offchain policy engines.

## The Problem

Embedded wallet providers (Privy, Turnkey, Dynamic) require trusting a company with key shards, TEEs, and offchain policy engines. For AI agents operating with real economic value, these trust assumptions are unacceptable. The alternative -- giving agents raw private keys -- is worse.

## The Solution

Iris makes the wallet itself the policy engine. Your agent's wallet IS a smart contract. The permissions ARE caveat enforcers. The identity IS an ERC-8004 NFT. There is no company holding shards of your key.

```
User creates wallet → Sets trust tier → Agent gets scoped delegation
                                         ↓
                              Caveat enforcers gate every tx
                                         ↓
                              Reputation checked in real-time
                                         ↓
                              Execution succeeds or reverts onchain
```

## Quick Start

See the [Getting Started](./getting-started.md) guide to deploy Iris in under five minutes.

## ERC Stack

| Standard | Role |
|----------|------|
| ERC-4337 | Smart contract accounts (account abstraction) |
| ERC-7710 | Delegation with caveat enforcers |
| ERC-7715 | Permission request standard |
| ERC-8004 | Agent identity + reputation registry |
| ERC-8128 | Signed HTTP authentication |
| EIP-7702 | EOA upgrade path |

## Why This Matters

AI agents will manage billions in economic value. The infrastructure securing their permissions cannot rely on a company's promise -- it must be enforced by math. Iris is the first protocol to enforce agent wallet permissions entirely onchain, with reputation-gated access that degrades dynamically when agents misbehave.
