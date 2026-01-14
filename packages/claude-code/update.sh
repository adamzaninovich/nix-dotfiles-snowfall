#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE="@anthropic-ai/claude-code"
REGISTRY_URL="https://registry.npmjs.org/${PACKAGE}"

# Get current version from default.nix
CURRENT_VERSION=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$SCRIPT_DIR/default.nix" 2>/dev/null || echo "unknown")

echo "Current version: $CURRENT_VERSION"
echo "Fetching latest version from npm registry..."

LATEST_VERSION=$(curl -s "$REGISTRY_URL" | jq -r '.["dist-tags"].latest')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
  echo "Error: Could not fetch latest version"
  exit 1
fi

echo "Latest version:  $LATEST_VERSION"
echo ""

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "✓ Claude Code is up to date!"
  exit 0
fi

echo "⚠ Update available: $CURRENT_VERSION → $LATEST_VERSION"
echo ""

TARBALL_URL="https://registry.npmjs.org/${PACKAGE}/-/claude-code-${LATEST_VERSION}.tgz"
echo "Fetching SHA256 for $TARBALL_URL..."

SHA256=$(nix-prefetch-url "$TARBALL_URL" 2>/dev/null | tail -1)

echo ""
echo "=========================================="
echo "Claude Code Update Info"
echo "=========================================="
echo "Current: $CURRENT_VERSION"
echo "Latest:  $LATEST_VERSION"
echo "SHA256:  $SHA256"
echo "URL:     $TARBALL_URL"
echo "=========================================="
echo ""
echo "Update default.nix with these values:"
echo "  version = \"$LATEST_VERSION\";"
echo "  sha256 = \"$SHA256\";"
echo ""
