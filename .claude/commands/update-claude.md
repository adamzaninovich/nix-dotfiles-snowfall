# Update Claude Code Package

Update the Claude Code package to the latest version from npm.

## Instructions

1. Run the update script at `packages/claude-code/update.sh` to check for updates
2. If an update is available, parse the output to extract:
   - The new version number
   - The SHA256 hash
3. Update `packages/claude-code/default.nix` with the new values:
   - Update the `version` field
   - Update the `url` field with the new version in the path
   - Update the `sha256` field
4. Report the update: show the old version, new version, and confirm the file was updated
5. If already up to date, just report that no update is needed

## Example Output Format

When update is available:
```
Updated Claude Code: 2.1.17 → 2.1.32
Run `darwin-rebuild switch --flake ~/.config/snowfall#<hostname>` to apply.
```

When already up to date:
```
Claude Code is already at the latest version (2.1.32)
```
