#!/usr/bin/env bash
set -euo pipefail

PACKAGE="@anthropic-ai/claude-code"
REGISTRY_URL="https://registry.npmjs.org/${PACKAGE}"

echo "Fetching latest version from npm registry..."
LATEST_VERSION=$(curl -s "$REGISTRY_URL" | jq -r '.["dist-tags"].latest')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
  echo "Error: Could not fetch latest version"
  exit 1
fi

echo "Latest version: $LATEST_VERSION"

TARBALL_URL="https://registry.npmjs.org/${PACKAGE}/-/claude-code-${LATEST_VERSION}.tgz"
echo "Fetching SHA256 for $TARBALL_URL..."

SHA256=$(nix-prefetch-url "$TARBALL_URL" 2>/dev/null | tail -1)

echo ""
echo "=========================================="
echo "Claude Code Update Info"
echo "=========================================="
echo "Version: $LATEST_VERSION"
echo "SHA256:  $SHA256"
echo "URL:     $TARBALL_URL"
echo "=========================================="
echo ""
echo "Update default.nix with these values:"
echo "  version = \"$LATEST_VERSION\";"
echo "  sha256 = \"$SHA256\";"
echo ""
