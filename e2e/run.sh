#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTRACTS_DIR="$ROOT_DIR/contracts"
ANVIL_PID=""

cleanup() {
  if [ -n "$ANVIL_PID" ] && kill -0 "$ANVIL_PID" 2>/dev/null; then
    echo "[e2e] Stopping Anvil (PID $ANVIL_PID)..."
    kill "$ANVIL_PID" 2>/dev/null || true
    wait "$ANVIL_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "============================================"
echo "  Iris Protocol — E2E Test Runner"
echo "============================================"
echo ""

# 1. Build contracts
echo "[e2e] Building contracts..."
(cd "$CONTRACTS_DIR" && forge build --silent)
echo "[e2e] Contracts built."
echo ""

# 2. Start Anvil
echo "[e2e] Starting Anvil on port 8545..."
anvil --silent &
ANVIL_PID=$!

# Wait for Anvil to be ready
for i in $(seq 1 30); do
  if cast chain-id --rpc-url http://127.0.0.1:8545 &>/dev/null; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "[e2e] ERROR: Anvil failed to start within 30 seconds"
    exit 1
  fi
  sleep 0.2
done
echo "[e2e] Anvil running (PID $ANVIL_PID)."
echo ""

# 3. Deploy contracts
echo "[e2e] Deploying contracts to local Anvil..."
(cd "$CONTRACTS_DIR" && forge script script/DeployLocal.s.sol:DeployLocal \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --silent)
echo "[e2e] Deployment complete."
echo ""

# 4. Run E2E tests
echo "[e2e] Running E2E tests..."
echo ""
(cd "$SCRIPT_DIR" && npx vitest run)

echo ""
echo "============================================"
echo "  E2E tests complete"
echo "============================================"
