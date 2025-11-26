# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS dotfiles repository using **Snowfall Lib** - a convention-over-configuration framework for Nix flakes. The namespace is `bravo` (configured in `flake.nix`), which prefixes all custom modules and library functions.

**Current Systems**:
- `tachi` - NixOS x86_64-linux with Hyprland desktop environment
- `wsl` - NixOS x86_64-linux running in Windows 11 WSL2
- `rocinante` - macOS aarch64-darwin with nix-darwin
- `pallas` - macOS aarch64-darwin work laptop (nix-darwin)

## Quick Reference

**Home Manager API Notes**:
- Use `programs.zsh.initContent` instead of deprecated `programs.zsh.initExtra`
- Both accept the same values (strings, mkMerge, mkOrder), but initContent is the current API

**Build Commands**:
```bash
# NixOS (tachi)
sudo nixos-rebuild switch --flake .#tachi

# NixOS WSL (wsl)
sudo nixos-rebuild switch --flake .#wsl

# macOS (rocinante)
darwin-rebuild switch --flake .#rocinante
```

**Architecture**:
- Namespace: `bravo.*` for all custom options
- Auto-discovery: File structure = configuration (no manual imports)
- Git requirement: `git add` files immediately for Snowfall to see them
- Cross-platform: Shared home modules, platform-specific system modules

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
- Example: `bravo.desktop.wayland.enable = true` enables hyprland, waybar, wofi, swaync, gtk

### Current Module Inventory

**Desktop Environment** (`modules/home/desktop/`):

**Wayland (Linux only):**
- `bravo.desktop.wayland` - Meta-module enabling complete Hyprland environment
- `bravo.desktop.wayland.hyprland` - Hyprland window manager + hyprlock
- `bravo.desktop.wayland.waybar` - Waybar status bar
- `bravo.desktop.wayland.wofi` - Wofi application launcher
- `bravo.desktop.wayland.swaync` - SwayNC notification daemon

**macOS:**
- `bravo.desktop.macos` - Meta-module enabling complete macOS desktop environment with AeroSpace
- `bravo.desktop.macos.aerospace` - AeroSpace tiling window manager
- `bravo.desktop.macos.sketchybar` - SketchyBar status bar
- `bravo.desktop.macos.borders` - Window borders

**Theme & UI (Cross-platform):**
- `bravo.desktop.theme.rosepine` - Rosé Pine Moon color scheme (read-only option, colors available via lib everywhere)
- `bravo.desktop.gtk` - GTK theme (Linux only)

**Development Tools** (`modules/home/` - Cross-platform):
- `bravo.zsh` - Shell with aliases
- `bravo.neovim` - Neovim
- `bravo.doom-emacs` - Doom Emacs
- `bravo.doom-fonts` - Doom Emacs fonts
- `bravo.ghostty` - Terminal emulator (config only on macOS; package + config on Linux)
- `bravo.gpg` - GPG + agent
- `bravo.bat` - Better cat
- `bravo.direnv` - direnv integration
- `bravo.claude` - Claude Code CLI
- `bravo.comic-code-fonts` - Comic Code font (uses SOPS for font files)
- `bravo.lang.elixir` - Elixir environment

**Always-On Modules** (No enable option, auto-applied to all home configs):
- `git` - Git and GitHub CLI configuration (applies everywhere, no `bravo.git.enable` needed)

**System Modules** (Auto-applied, not namespaced):
- `modules/nixos/sops` - SOPS secrets for NixOS (uses upstream `sops.*` options)
- `modules/darwin/sops` - SOPS secrets for Darwin (uses upstream `sops.*` options)
- `modules/darwin/macos-defaults` - Shared macOS system defaults (dock, finder, trackpad, etc.) with `lib.mkDefault` for per-system overrides

**Packages** (`packages/`):
- `claude-code` - Claude Code package

**Overlays** (`overlays/`):
- `unstable` - Provides `channels.unstable` access

## Common Commands

### Building and Switching

**NixOS (tachi)**:
```bash
# Rebuild system (automatically includes home-manager config)
sudo nixos-rebuild switch --flake .#tachi

# Test system without switching
sudo nixos-rebuild test --flake .#tachi

# Build home configuration standalone (if needed)
home-manager switch --flake .#adam@tachi
```

**macOS Darwin (rocinante)**:
```bash
# Rebuild system (automatically includes home-manager config)
darwin-rebuild switch --flake .#rocinante

# Build without switching
darwin-rebuild build --flake .#rocinante

# Build home configuration standalone (if needed)
home-manager switch --flake .#adam@rocinante
```

**How Snowfall Integrates Homes**:
- Snowfall **automatically integrates** home configurations into systems when the hostname matches
- `homes/x86_64-linux/adam@tachi/` → integrated into system `tachi` because `@tachi` matches
- Running `sudo nixos-rebuild switch --flake .#tachi` builds BOTH the system AND home config
- Home configurations are also available as standalone `homeConfigurations` output if needed
- No need to manually add `home-manager.nixosModules.home-manager` - Snowfall does this automatically

**Suggested aliases**:
- For NixOS (in `homes/x86_64-linux/adam@tachi/default.nix`):
  ```nix
  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/.config/snowfall#tachi";
    rebuild-test = "sudo nixos-rebuild test --flake ~/.config/snowfall#tachi";
  };
  ```
- For macOS (in `homes/aarch64-darwin/adam@rocinante/default.nix`):
  ```nix
  programs.zsh.shellAliases = {
    rebuild = "darwin-rebuild switch --flake ~/.config/snowfall#rocinante";
    rebuild-test = "darwin-rebuild build --flake ~/.config/snowfall#rocinante";
  };
  ```

### Secrets Management

**Current Host Keys**:
- `wsl`: `age1dj7j53uh0nu25v0yxrfvgsufuzjqwpghtnusaguur56cv8522y2s27n0r0`
  - note: may need to be updated to use /etc/sops/age/ dir for keys
- `tachi` (NixOS):
  - System key at `/etc/sops/age/tachi.txt` (for boot-time decryption)
  - User key at `~/.config/sops/age/tachi.txt` (for manual editing)
  - Public: `age1xeq2p622qm5ftc7kl23welzvc3552ngqc82df8t947u696ysxgts0mddmt`
- `rocinante` (Darwin): User key at `~/.config/sops/age/rocinante.txt` (public: `age13nu8e3vrjek227g7rjq8jqerzpeft7xwcs2zgxajpg8gztzggv4ses4v8h`)
- `pallas` (Darwin): User key at `~/.config/sops/age/pallas.txt` (public: `age1s20cczctqy8w7l7frnpwfp70rdhz8r8ewm0t298q4vt8leyr7u6qnprs7a`)

Note: All systems use `SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt` for manual `sops` commands.

**Common Commands**:
```bash
# Edit encrypted secrets
# Note: SOPS_AGE_KEY_FILE is set to $HOME/.config/sops/age/keys.txt in all home configs
# No need to manually export - it's set automatically in your shell session
sops secrets/system-secrets.yaml
sops secrets/comic-code-fonts.tar.gz
sops secrets/doom-fonts.tar.gz

# Generate new host age key (for new machines)
mkdir -p ~/.config/sops/age
nix-shell -p age --run 'age-keygen -o ~/.config/sops/age/<hostname>.txt'

# Create password hash (for NixOS user passwords)
nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'

# Verify decrypted secrets at runtime
# NixOS (tachi):
sudo ls -la /run/secrets-for-users/adam-password
sudo ls -la /run/secrets/comic-code-fonts
# Darwin (rocinante):
ls -la /var/lib/secrets/comic-code-fonts

# Note: doom-fonts decrypts during home activation on both platforms:
# NixOS:  ~/.local/share/fonts/doom-fonts/
# Darwin: ~/Library/Fonts/doom-fonts/
```

**File Locations**:
```
Repository:
~/.config/snowfall/
├── .sops.yaml                    # Encryption config (public keys)
├── secrets/
│   ├── system-secrets.yaml       # Encrypted YAML secrets
│   ├── comic-code-fonts.tar.gz   # Encrypted binary (both platforms)
│   └── doom-fonts.tar.gz         # Encrypted binary (both platforms)
└── modules/
    ├── nixos/sops/               # NixOS sops config
    └── darwin/sops/              # Darwin sops config

Local Keys (not in repo):
NixOS (tachi):
  System key (for boot-time decryption):
    /etc/sops/age/
    ├── keys.txt -> tachi.txt     # Symlink (used by sops-nix module)
    └── tachi.txt                 # Host-specific private key (root:root, 600)

  User key (for manual editing):
    ~/.config/sops/age/
    ├── keys.txt -> tachi.txt     # Symlink (used by sops CLI via SOPS_AGE_KEY_FILE)
    └── tachi.txt                 # Host-specific private key (adam:adam, 600)
                                  # ⚠️  Identical content to /etc/sops/age/tachi.txt

Darwin (rocinante, pallas):
  ~/.config/sops/age/
  ├── keys.txt -> <hostname>.txt  # Symlink (used by sops CLI via SOPS_AGE_KEY_FILE)
  └── <hostname>.txt              # Host-specific private key

Runtime (system-level secrets):
NixOS:    /run/secrets-for-users/ # adam-password
          /run/secrets/           # comic-code-fonts
Darwin:   /var/lib/secrets/       # comic-code-fonts

Runtime (home-level secrets - decrypted during activation):
NixOS:    ~/.local/share/fonts/doom-fonts/
Darwin:   ~/Library/Fonts/doom-fonts/
```

See `secrets/README.md` for complete setup, reencryption, and troubleshooting guide.

### Flake Commands

```bash
# Update all inputs
nix flake update

# Update specific input (preferred syntax)
nix flake update nixpkgs

# Update specific input (deprecated - still works but will be removed)
# nix flake lock --update-input nixpkgs

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
  # Functions available as lib.bravo.<name>
  my-function = x: x;
}
```

**Current Libraries**:
- `lib/rose_pine/` - Rosé Pine color palettes and conversion functions
  - Access as: `lib.bravo.rose_pine.moon`, `lib.bravo.rose_pine.toHex`, etc.
  - Available in ALL Nix expressions (modules, systems, homes, packages, overlays)

### Platform-Specific Modules

Snowfall auto-applies modules based on system type:
- `modules/nixos/` - Only applied to NixOS systems (tachi)
- `modules/darwin/` - Only applied to macOS systems (rocinante)
- `modules/home/` - Applied to all Home Manager configurations (both platforms)

When creating modules that work across platforms:
```nix
# In modules/home/my-tool/default.nix
{ lib, config, pkgs, ... }:
let
  cfg = config.bravo.my-tool;
in {
  options.bravo.my-tool.enable = lib.mkEnableOption "my tool";

  config = lib.mkIf cfg.enable {
    # Platform-agnostic config
    home.packages = [ pkgs.my-tool ];

    # Platform-specific config
    home.file.".myconfig".text = lib.optionalString pkgs.stdenv.isDarwin "macOS config"
                               + lib.optionalString pkgs.stdenv.isLinux "Linux config";
  };
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

The Rosé Pine color scheme is available in two ways:

**1. Via Library Functions** (available everywhere):
```nix
{ lib, ... }:
let
  rosepine = lib.bravo.rose_pine;
in {
  # Access color palettes
  some-option = rosepine.moon.base;      # Moon variant: "232136"
  other-option = rosepine.main.base;     # Main variant: "191724"
  color = rosepine.palette.text;         # Default palette (moon): "e0def4"

  # Use helper functions
  hyprland-color = rosepine.toHyprland rosepine.palette.love;  # "0xffeb6f92"
  css-hex = rosepine.toHex rosepine.palette.foam;              # "#9ccfd8"
  css-rgb = rosepine.toRGB rosepine.palette.iris;              # "rgb(196, 167, 231)"
  css-rgba = rosepine.toRGBA "0.5" rosepine.palette.base;      # "rgba(35, 33, 54, 0.5)"
}
```

**2. Via Home Module** (when `bravo.desktop.theme.rosepine.enable = true`):
```nix
{ config, ... }:
{
  # Pre-converted color formats
  some-setting = config.bravo.desktop.theme.rosepine.colors.hex.love;       # "#eb6f92"
  other-setting = config.bravo.desktop.theme.rosepine.colors.hyprland.base; # "0xff232136"
  rgb-color = config.bravo.desktop.theme.rosepine.colors.rgb.foam;          # "rgb(156, 207, 216)"
}
```

**Available in**: `lib/rose_pine/default.nix` - accessible as `lib.bravo.rose_pine` everywhere

### SOPS Integration

SOPS modules are auto-applied based on system type:
- **NixOS** (`modules/nixos/sops`): Uses host age key at `~/.config/sops/age/<hostname>.txt`
- **Darwin** (`modules/darwin/sops`): Uses host age key at `~/.config/sops/age/<hostname>.txt`

**Key Architecture**:
- **Master key**: Stored in 1Password, used only for adding new hosts and reencryption
- **Host keys**: Per-machine age keys at `~/.config/sops/age/<hostname>.txt`
- Each machine only needs its own host key to decrypt secrets
- Secrets are encrypted with ALL keys (master + all hosts)
- `~/.config/sops/age/keys.txt` is a symlink to current host's key

**Adding New Secrets**:
```bash
# 1. Add to `.sops.yaml` creation rules
# 2. Define in sops module: sops.secrets.<name> = { };
# 3. Edit encrypted file
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
nix-shell -p sops --run 'sops secrets/system-secrets.yaml'
```

**Setting Up New Machine** (high-level):
1. Generate host age key: `age-keygen -o ~/.config/sops/age/<hostname>.txt`
2. Add public key to `.sops.yaml` (commit and push)
3. Reencrypt all secrets with master key: `sops updatekeys secrets/*`
4. Pull repo on new machine and build
5. Create symlink: `ln -sf <hostname>.txt ~/.config/sops/age/keys.txt`

See `secrets/README.md` for detailed setup, reencryption steps, and troubleshooting.

### Hyprland Configuration (NixOS only)

Hyprland is configured in `modules/home/desktop/hyprland/default.nix`:
- Main mod: SUPER
- Layout: master (can switch to dwindle)
- Terminal: ghostty (`$mainMod + Return`)
- Launcher: wofi (`ALT + Space`)
- Lock: hyprlock (`$mainMod + Shift + L`)
- Movement: vim keys (HJKL) or arrows

### macOS Integration

**mac-app-util Module**:
The `mac-app-util` home-manager module is automatically included for the rocinante home configuration (configured in `flake.nix`):
```nix
homes.users."adam@rocinante".modules = with inputs; [
  mac-app-util.homeManagerModules.default
];
```

This enables proper macOS app integration for Nix-installed applications (Spotlight, LaunchPad, etc.).

**Shared Darwin Defaults**:
Common macOS system preferences are configured in `modules/darwin/macos-defaults/` and auto-apply to all darwin systems. Settings include:
- Dock configuration (autohide, hot corners, tile size)
- Finder preferences (show extensions, path bar, status bar)
- Trackpad settings (tap-to-click, three-finger drag)
- Global settings (dark mode, screenshots to ~/Workspace)
- Documentation and man pages enabled
- Passwordless sudo for admin group

All settings use `lib.mkDefault` so they can be overridden per-system by setting them directly in system configs. See [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html#sec-options) for available settings.

**Determinate Nix**:
All darwin systems use Determinate Nix installer, which manages the nix daemon. Therefore, `nix.enable = false` is set in the shared darwin defaults to prevent conflicts.

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

**tachi** (NixOS x86_64-linux):
- Desktop: Hyprland + Wayland stack
- Storage: ZFS with auto-scrub and trim
- Login: greetd with tuigreet (TUI greeter)
- Audio: PipeWire (ALSA, PulseAudio, JACK support)
- Users: `mutableUsers = false` - all user management is declarative
- SSH: enabled, password auth disabled, key-based only
- Security: Passwordless sudo for adam

**wsl** (NixOS x86_64-linux):
- Platform: Windows 11 WSL2 (nixos-wsl)
- Docker: Docker Desktop integration enabled
- Network: Custom DNS (10.1.1.8, 10.1.1.9), interop enabled
- Users: `mutableUsers = false` - declarative user management with SOPS password
- SSH: enabled, password auth disabled, key-based only, start-on-demand
- Security: Passwordless sudo for adam, SSH_AUTH_SOCK preserved
- Shell: zsh with development tools (Elixir, Neovim, Doom Emacs)

**rocinante** (macOS aarch64-darwin):
- Personal macOS laptop
- Nix management: Determinate Nix
- Shared darwin defaults auto-applied via `modules/darwin/macos-defaults`
- System config: Minimal (hostname, username, SSH key only)

**pallas** (macOS aarch64-darwin):
- Work macOS laptop
- Nix management: Determinate Nix
- Shared darwin defaults auto-applied via `modules/darwin/macos-defaults`
- System config: Minimal (hostname, username, SSH key only)

### Flake Structure
- Entry point: `flake.nix` uses `snowfall-lib.mkFlake`
- Namespace: `bravo` (set in `snowfall.namespace`)
- Inputs: nixpkgs (nixos-25.05), unstable, home-manager, sops-nix, darwin, mac-app-util, nixos-hardware, nixos-wsl, zen-browser
- Systems: x86_64-linux (NixOS), aarch64-darwin (macOS)
