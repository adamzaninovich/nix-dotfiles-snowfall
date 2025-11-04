# Snowfall Dotfiles

Personal NixOS and macOS system configuration using [Snowfall Lib](https://snowfall.org/guides/lib/quickstart/) - a convention-over-configuration framework for Nix flakes.

## Systems

- **tachi** - NixOS x86_64-linux with Hyprland desktop environment
- **rocinante** - macOS aarch64-darwin with nix-darwin

## Features

- **Cross-platform**: Shared home modules work on both NixOS and macOS
- **Auto-discovery**: File structure defines configuration (no manual imports)
- **Secret management**: SOPS-encrypted secrets with age keys
- **Modular**: Composable modules with `bravo.*` namespace
- **Declarative**: Immutable users, reproducible builds

### Desktop

**Linux (Wayland):**
- Hyprland window manager with Wayland
- Waybar status bar
- Wofi launcher
- SwayNC notifications
- Rosé Pine Moon theme

**macOS:**
- AeroSpace tiling window manager
- SketchyBar status bar
- Window borders
- Rosé Pine Moon theme

### Development Tools
- Zsh with custom aliases
- Neovim
- Doom Emacs
- Ghostty terminal
- Git, GPG, direnv
- Claude Code CLI
- Elixir environment

## Quick Start

### Prerequisites

**NixOS:**
```bash
# Enable flakes
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

**macOS:**
```bash
# Install Nix with Determinate Nix Installer (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install nix-darwin
nix run nix-darwin -- switch --flake ~/.config/snowfall#rocinante
```

### Setting Up a New Machine

#### 1. Clone this repository

```bash
mkdir -p ~/.config
git clone <repo-url> ~/.config/snowfall
cd ~/.config/snowfall
```

#### 2. Set up SOPS secrets

Generate a host-specific age key:

```bash
mkdir -p ~/.config/sops/age
nix-shell -p age --run 'age-keygen -o ~/.config/sops/age/<hostname>.txt'
```

The command will output your public key (starts with `age1...`). Save it for the next step.

Create symlink for sops CLI:

```bash
cd ~/.config/sops/age
ln -sf <hostname>.txt keys.txt
```

#### 3. Add host to secrets (requires internet access)

On any machine with access to the repository:

1. Add your host's public key to `.sops.yaml`:
   ```yaml
   keys:
     - &master age1x4nscwmglq7fxrzhyeqnw43tw5py0cl3gcedwmxwztvxfw3f6crq0kkj8g
     - &tachi age1xeq2p622qm5ftc7kl23welzvc3552ngqc82df8t947u696ysxgts0mddmt
     - &rocinante age13nu8e3vrjek227g7rjq8jqerzpeft7xwcs2zgxajpg8gztzggv4ses4v8h
     - &newhost <your-public-key>  # Add your new host's public key
   ```

2. Add `*newhost` to all `creation_rules` age lists

3. Commit and push:
   ```bash
   git add .sops.yaml
   git commit -m "Add newhost to secrets encryption"
   git push
   ```

#### 4. Reencrypt secrets with new host key

On a machine with the master key (stored in 1Password):

```bash
# Get master key from 1Password and save to ~/.config/sops/age/master.txt

# Temporarily use master key
cd ~/.config/sops/age
ln -sf master.txt keys.txt

# Reencrypt all secrets
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
cd ~/.config/snowfall
nix-shell -p sops --run 'sops updatekeys secrets/system-secrets.yaml'
nix-shell -p sops --run 'sops updatekeys secrets/comic-code-fonts.tar.gz'
nix-shell -p sops --run 'sops updatekeys secrets/doom-fonts.tar.gz'

# Commit and push
git add secrets/
git commit -m "Reencrypt secrets for newhost"
git push

# Restore symlink to your host key
cd ~/.config/sops/age
ln -sf <your-hostname>.txt keys.txt
rm master.txt
```

#### 5. Create system configuration

Create a new system config:

**NixOS:**
```bash
mkdir -p systems/x86_64-linux/<hostname>
# Copy and modify systems/x86_64-linux/tachi/default.nix
```

**Darwin:**
```bash
mkdir -p systems/aarch64-darwin/<hostname>
# Copy and modify systems/aarch64-darwin/rocinante/default.nix
```

Create home configuration:

**NixOS:**
```bash
mkdir -p homes/x86_64-linux/adam@<hostname>
# Copy and modify homes/x86_64-linux/adam@tachi/default.nix
```

**Darwin:**
```bash
mkdir -p homes/aarch64-darwin/adam@<hostname>
# Copy and modify homes/aarch64-darwin/adam@rocinante/default.nix
```

**Important:** Add all new files to git immediately:
```bash
git add systems/ homes/
```

#### 6. Build the system

Pull the latest changes on your new machine:

```bash
cd ~/.config/snowfall
git pull
```

Build and activate:

**NixOS:**
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

**Darwin:**
```bash
darwin-rebuild switch --flake .#<hostname>
```

## Common Commands

### Building

**NixOS (tachi):**
```bash
sudo nixos-rebuild switch --flake ~/.config/snowfall#tachi    # Build and switch
sudo nixos-rebuild test --flake ~/.config/snowfall#tachi      # Test without switching
```

**Darwin (rocinante):**
```bash
darwin-rebuild switch --flake ~/.config/snowfall#rocinante    # Build and switch
darwin-rebuild build --flake ~/.config/snowfall#rocinante     # Build without switching
```

### Flake Management

```bash
nix flake update                        # Update all inputs
nix flake lock --update-input nixpkgs   # Update specific input
nix flake check                         # Check flake
nix flake show                          # Show outputs
```

### Secrets Management

```bash
# Edit secrets
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
nix-shell -p sops --run 'sops secrets/system-secrets.yaml'
nix-shell -p sops --run 'sops secrets/comic-code-fonts.tar.gz'
nix-shell -p sops --run 'sops secrets/doom-fonts.tar.gz'
```

See `secrets/README.md` for detailed SOPS setup and troubleshooting.

## Directory Structure

```
├── flake.nix              # Snowfall mkFlake configuration
├── systems/               # System configurations (auto-discovered)
│   ├── x86_64-linux/     # NixOS systems
│   └── aarch64-darwin/   # Darwin systems
├── homes/                 # Home Manager configurations (auto-discovered)
│   ├── x86_64-linux/
│   └── aarch64-darwin/
├── modules/               # Modules (auto-applied based on system type)
│   ├── nixos/            # NixOS-only modules
│   ├── darwin/           # Darwin-only modules
│   └── home/             # Cross-platform home modules
├── packages/              # Custom packages (auto-exported)
├── overlays/              # Overlays (auto-applied)
├── lib/                   # Custom library functions (lib.bravo.*)
└── secrets/               # SOPS-encrypted secrets
```

## Module Namespace

All custom modules use the `bravo` namespace:

```nix
# Enable modules in home configuration
bravo.desktop.wayland.enable = true;  # Meta-module (enables hyprland, waybar, etc)
bravo.zsh.enable = true;
bravo.neovim.enable = true;
bravo.doom-emacs.enable = true;
bravo.claude.enable = true;
```

## Documentation

- **[CLAUDE.md](.claude/CLAUDE.md)** - Detailed guide for Claude Code (architecture, development patterns, workflows)
- **[secrets/README.md](secrets/README.md)** - Complete SOPS secrets setup and troubleshooting
- **[Snowfall Lib](https://snowfall.org/guides/lib/quickstart/)** - Framework documentation

## Key Conventions

- **Git tracking required**: Always `git add` new files immediately - Snowfall only sees tracked files
- **No manual imports**: Directory structure defines configuration
- **Namespace everything**: Custom options use `bravo.*` prefix
- **Composable modules**: Meta-modules enable groups of related modules

## License

Personal configuration - use at your own risk.
