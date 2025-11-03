# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS dotfiles repository using **Snowfall Lib** - a convention-over-configuration framework for Nix flakes. The namespace is `bravo` (configured in `flake.nix`), which prefixes all custom modules and library functions.

**Current System**: `tachi` - NixOS x86_64-linux with Hyprland desktop environment

## Snowfall Philosophy

Snowfall Lib uses **automatic discovery** based on directory structure. The file system IS the configuration:
- No manual imports or exports needed
- Directory names determine output names
- `default.nix` files are auto-discovered in each component directory
- **CRITICAL**: Always `git add` new files immediately - Snowfall only sees tracked files

## Snowfall Directory Structure & Auto-Discovery

```
├── flake.nix              # Snowfall mkFlake configuration
├── systems/               # System configurations (auto-discovered)
│   └── <arch>-<os>/      # e.g., x86_64-linux/
│       └── <name>/       # e.g., tachi/ → nixosConfigurations.tachi
│           └── default.nix
├── homes/                 # Home configurations (auto-discovered)
│   └── <arch>/           # e.g., x86_64-linux/
│       └── <user@host>/  # e.g., adam@tachi/ → homeConfigurations."adam@tachi"
│           └── default.nix
├── modules/               # Modules (auto-applied to matching systems)
│   ├── nixos/            # Applied to all NixOS systems
│   ├── darwin/           # Applied to all Darwin systems
│   └── home/             # Applied to all Home Manager configs
│       └── <name>/       # e.g., zsh/ → option bravo.zsh.enable
│           └── default.nix
├── packages/              # Packages (auto-exported to flake packages)
│   └── <name>/           # e.g., claude-code/ → packages.<system>.claude-code
│       └── default.nix
├── overlays/              # Overlays (auto-applied everywhere)
│   └── <name>/           # e.g., unstable/
│       └── default.nix   # Function: final: prev: { ... }
├── lib/                   # Custom libraries (merged into lib.<namespace>)
│   └── <name>/           # Functions available as lib.bravo.<name>
│       └── default.nix
├── shells/                # Dev shells (auto-exported to devShells)
│   └── <name>/           # e.g., python/ → devShells.<system>.python
│       └── default.nix
└── secrets/               # SOPS-encrypted secrets (not Snowfall-managed)
```

### How Auto-Discovery Works

1. **Packages** (`packages/<name>/default.nix`) - Exported to `packages.<system>.<name>`
2. **Modules** (`modules/{nixos,darwin,home}/<name>/default.nix`) - Auto-applied, create options `bravo.<name>`
3. **Systems** (`systems/<arch>-<os>/<name>/default.nix`) - Exported to `nixosConfigurations.<name>` or `darwinConfigurations.<name>`
4. **Homes** (`homes/<arch>/<user@host>/default.nix`) - Exported to `homeConfigurations."<user@host>"`
5. **Overlays** (`overlays/<name>/default.nix`) - Applied to all package sets everywhere
6. **Libraries** (`lib/<name>/default.nix`) - Merged into `lib.<namespace>.<name>`
7. **Shells** (`shells/<name>/default.nix`) - Exported to `devShells.<system>.<name>`

### Module System & Namespace

All custom modules use the `bravo` namespace (configured in `flake.nix` as `snowfall.namespace = "bravo"`):
- Modules create options: `options.bravo.<module-name>.enable`
- Modules are composable - meta-modules enable sub-modules
- Example: `bravo.desktop.wayland-desktop.enable = true` enables hyprland, waybar, wofi, swaync, gtk

### Current Module Inventory

**Desktop Environment** (`modules/home/desktop/`):
- `bravo.desktop.wayland-desktop` - Meta-module enabling complete Hyprland environment
- `bravo.desktop.hyprland` - Hyprland window manager + hyprlock
- `bravo.desktop.theme.rosepine` - Rosé Pine Moon color scheme (read-only, always available)
- `bravo.desktop.waybar` - Status bar
- `bravo.desktop.wofi` - Application launcher
- `bravo.desktop.swaync` - Notification daemon
- `bravo.desktop.gtk` - GTK theme

**Development Tools** (`modules/home/`):
- `bravo.zsh` - Shell with aliases
- `bravo.neovim` - Neovim
- `bravo.doom-emacs` - Doom Emacs
- `bravo.ghostty` - Terminal emulator
- `bravo.git` - Git config
- `bravo.gpg` - GPG + agent
- `bravo.bat` - Better cat
- `bravo.claude` - Claude Code CLI
- `bravo.lang.elixir` - Elixir environment

**System Modules** (`modules/nixos/`):
- `sops` - Auto-applied to all NixOS systems (not namespaced - uses upstream `sops.*`)

**Packages** (`packages/`):
- `claude-code` - Claude Code package

**Overlays** (`overlays/`):
- `unstable` - Provides `channels.unstable` access

## Common Commands

### Building and Switching

```bash
# Rebuild system (automatically includes home-manager config)
sudo nixos-rebuild switch --flake .#tachi

# Test system without switching
sudo nixos-rebuild test --flake .#tachi

# Build home configuration standalone (if needed)
home-manager switch --flake .#adam@tachi
```

**How Snowfall Integrates Homes**:
- Snowfall **automatically integrates** home configurations into systems when the hostname matches
- `homes/x86_64-linux/adam@tachi/` → integrated into system `tachi` because `@tachi` matches
- Running `sudo nixos-rebuild switch --flake .#tachi` builds BOTH the system AND home config
- Home configurations are also available as standalone `homeConfigurations` output if needed
- No need to manually add `home-manager.nixosModules.home-manager` - Snowfall does this automatically

**Suggested aliases** (update in `homes/x86_64-linux/adam@tachi/default.nix`):
```nix
programs.zsh.shellAliases = {
  rebuild = "sudo nixos-rebuild switch --flake ~/.config/snowfall#tachi";
  rebuild-test = "sudo nixos-rebuild test --flake ~/.config/snowfall#tachi";
};
```

### Secrets Management

```bash
# Edit encrypted secrets
nix-shell -p sops --run 'sops secrets/system-secrets.yaml'

# Get age public key from SSH host key
sudo nix-shell -p ssh-to-age --run 'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'

# Create password hash
nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'

# Verify secrets
ls -la /run/secrets/adam-password
ls -la /var/lib/sops-nix/key.txt
```

See `secrets/README.md` for complete SOPS setup guide.

### Flake Commands

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Check flake
nix flake check

# Show flake outputs
nix flake show
```

## Snowfall Development Patterns

### Rich Context Arguments

All Snowfall components receive rich arguments automatically:

**Modules** (`modules/{nixos,darwin,home}/<name>/default.nix`):
```nix
{ lib, pkgs, config, inputs, namespace, ... }:
# lib = customized with all input libraries + lib.<namespace>
# pkgs = with overlays applied
# inputs = all flake inputs
# namespace = "bravo"
```

**Systems** (`systems/<arch>-<os>/<name>/default.nix`):
```nix
{ lib, pkgs, config, inputs, system, target, format, ... }:
# system = "x86_64-linux"
# target = "x86_64-linux"
# format = "nixos"
```

**Homes** (`homes/<arch>/<user@host>/default.nix`):
```nix
{ lib, pkgs, config, inputs, namespace, home, target, host, ... }:
# namespace = "bravo"
# home = "adam@tachi"
# target = "x86_64-linux"
# host = "tachi"
```

**Overlays** (`overlays/<name>/default.nix`):
```nix
{ channels, inputs, ... }:
final: prev: {
  # channels.unstable provides access to unstable nixpkgs
  # Use to pull packages from different channels
  inherit (channels.unstable) my-package;
}
```

**Packages** (`packages/<name>/default.nix`):
```nix
{ lib, pkgs, stdenv, inputs, namespace, ... }:
# Standard derivation context plus Snowfall extras
```

**Libraries** (`lib/<name>/default.nix`):
```nix
{ lib, inputs, namespace, ... }:
{
  # Functions available as lib.bravo.<name>.my-function
  my-function = x: x;
}
```

### Adding a New Home Module (Snowfall Way)

```bash
# 1. Create module directory
mkdir -p modules/home/my-module

# 2. Create default.nix
cat > modules/home/my-module/default.nix << 'EOF'
{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.my-module;
in
{
  options.bravo.my-module = {
    enable = mkEnableOption "my module description";
  };

  config = mkIf cfg.enable {
    # Your configuration here
  };
}
EOF

# 3. CRITICAL: Add to git immediately
git add modules/home/my-module/

# 4. Enable in home config (homes/x86_64-linux/adam@tachi/default.nix)
# bravo.my-module.enable = true;
```

**Key Points**:
- Module is auto-discovered and auto-applied
- No imports needed anywhere
- Directory name determines the option path: `modules/home/foo/` → `bravo.foo.enable`
- For nested paths: `modules/home/desktop/bar/` → `bravo.desktop.bar.enable`
- Must `git add` before Snowfall sees it

### Adding a Package

```bash
# 1. Create package directory
mkdir -p packages/my-package

# 2. Create derivation
cat > packages/my-package/default.nix << 'EOF'
{ pkgs, stdenv, ... }:
stdenv.mkDerivation {
  pname = "my-package";
  version = "1.0.0";
  # ...
}
EOF

# 3. CRITICAL: Add to git
git add packages/my-package/

# 4. Package automatically available as:
#    - packages.x86_64-linux.my-package (flake output)
#    - pkgs.my-package (in modules, via overlay)
```

### Adding an Overlay

```bash
# 1. Create overlay directory
mkdir -p overlays/my-overlay

# 2. Create overlay function
cat > overlays/my-overlay/default.nix << 'EOF'
{ channels, inputs, ... }:
final: prev: {
  # Pull from unstable channel
  my-unstable-pkg = channels.unstable.some-package;

  # Override existing package
  existing-pkg = prev.existing-pkg.overrideAttrs (old: {
    # modifications
  });
}
EOF

# 3. CRITICAL: Add to git
git add overlays/my-overlay/

# 4. Overlay automatically applied everywhere
```

**Current Overlays**:
- `overlays/unstable/` - Provides access to nixpkgs unstable channel via `channels.unstable`

### Theme System

The Rosé Pine Moon theme (`modules/home/desktop/theme/default.nix`) provides colors in multiple formats:
- `colors.palette.*` - Raw hex values (RRGGBB)
- `colors.hyprland.*` - Hyprland format (0xffRRGGBB)
- `colors.hex.*` - CSS hex (#RRGGBB)
- `colors.rgb.*` - CSS rgb() format
- `colors.rgba(alpha).*` - CSS rgba() with custom alpha

Access in any module: `config.bravo.desktop.theme.rosepine.colors`

### SOPS Integration

The sops module (`modules/nixos/sops/default.nix`) is auto-applied to all NixOS systems:
- Uses SSH host key at `/etc/ssh/ssh_host_ed25519_key`
- Auto-generates age key at `/var/lib/sops-nix/key.txt`
- Default secrets file: `secrets/system-secrets.yaml`
- Binary secrets supported (e.g., `comic-code-fonts.tar.gz`)

Add new secrets:
1. Add to `.sops.yaml` creation rules
2. Define in sops module: `sops.secrets.<name> = { };`
3. Edit encrypted file: `nix-shell -p sops --run 'sops <file>'`

See `secrets/README.md` for complete guide.

### Hyprland Configuration

Hyprland is configured in `modules/home/desktop/hyprland/default.nix`:
- Main mod: SUPER
- Layout: master (can switch to dwindle)
- Terminal: ghostty (`$mainMod + Return`)
- Launcher: wofi (`ALT + Space`)
- Lock: hyprlock (`$mainMod + Shift + L`)
- Movement: vim keys (HJKL) or arrows

## Important Snowfall Conventions

### Critical: Git Add New Files
**Snowfall ONLY sees files tracked by git**. Always `git add` immediately after creating:
- New module directories
- New package directories
- New overlay files
- New library files
- Any new `default.nix` files

Without `git add`, Snowfall's auto-discovery won't find the file.

### No Manual Imports/Exports
- Never import modules manually - Snowfall auto-applies them
- Never export packages manually - Snowfall auto-exports them
- Never list overlays manually - Snowfall auto-applies them
- The directory structure IS the configuration

### Namespace Everything
- All custom options use `bravo.*` prefix
- Module options: `options.bravo.<module-name>`
- Library functions: `lib.bravo.<function-name>`
- Package names don't need namespace (already scoped by flake)

### Channel Access
- Main channel: `nixpkgs` (nixos-25.05 stable)
- Unstable channel: `channels.unstable` (in overlays) or `inputs.unstable.legacyPackages.${system}` (elsewhere)
- Channel config in `flake.nix`: `channels-config = { allowUnfree = true; ... }`

### System-Specific Notes
- **tachi**: NixOS x86_64-linux, Hyprland, ZFS (auto-scrub + trim)
- **Users**: mutableUsers = false - all user management is declarative
- **SSH**: enabled, password auth disabled, key-based only
- **Git commits**: Single-line, no extra attributions (per global CLAUDE.md)

### Flake Structure
- Entry point: `flake.nix` uses `snowfall-lib.mkFlake`
- Namespace: `bravo` (set in `snowfall.namespace`)
- Inputs: nixpkgs (stable), unstable, home-manager, sops-nix, doom-fonts, zen-browser
- Systems target: x86_64-linux (extendable to darwin)
