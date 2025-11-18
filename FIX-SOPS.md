# SOPS User Password Fix Plan

## Problem Statement

The SOPS-encrypted user password on NixOS (tachi) is not being decrypted during boot, preventing the user account from being created with the correct password. This forces the use of recovery shell to access the system.

### Root Cause

The age key is stored at `/home/adam/.config/sops/age/keys.txt`, which is not accessible during early boot when user accounts are created. The boot logs show:

```
cannot read keyfile '/home/adam/.config/sops/age/keys.txt': open /home/adam/.config/sops/age/keys.txt: no such file or directory
```

**Why this happens:**
1. NixOS boot process creates users BEFORE mounting home directories
2. Secrets with `neededForUsers = true` (like `adam-password`) must decrypt during early boot
3. At early boot time, `/home/adam/` doesn't exist yet (especially on ZFS)
4. SOPS falls back to SSH host keys, but secrets are encrypted with the tachi age key, not the SSH key
5. Decryption fails, password file isn't created, user gets no password set

### Platform Differences

- **NixOS (tachi)**: Early boot needs user password → requires system-accessible key location
- **macOS (rocinante/pallas)**: No `neededForUsers` constraint, home always available → current setup works fine
- **Future WSL2**: Would have same constraints as NixOS → needs same solution

## Solution: System-Level Keys for NixOS

Move age keys to `/etc/sops/age/` for NixOS systems only, keeping Darwin unchanged.

### Architecture Overview

**NixOS Systems (tachi, future WSL2):**
- Age key location: `/etc/sops/age/<hostname>.txt`
- Symlink: `/etc/sops/age/keys.txt -> <hostname>.txt`
- Environment variable: `SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt`
- Secrets decrypt to: `/run/secrets/`, `/run/secrets-for-users/`

**Darwin Systems (rocinante, pallas):**
- Age key location: `~/.config/sops/age/<hostname>.txt` (unchanged)
- Symlink: `~/.config/sops/age/keys.txt -> <hostname>.txt` (unchanged)
- Environment variable: `SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt`
- Secrets decrypt to: `/var/lib/secrets/`

### Benefits

1. **Early boot access**: `/etc/sops/age/` is available before home directories mount
2. **Cross-platform consistency**: NixOS and WSL2 use same pattern, Darwin keeps working setup
3. **Maintains host-agnostic pattern**: Still uses symlink strategy for multi-host repos
4. **No reencryption needed**: Same age key, just moved location
5. **Automatic CLI usage**: `SOPS_AGE_KEY_FILE` ensures `sops` command works correctly on each system

## Implementation Steps

### 1. Copy Age Key to System Location (tachi only)

```bash
sudo mkdir -p /etc/sops/age
sudo cp ~/.config/sops/age/tachi.txt /etc/sops/age/tachi.txt
sudo chmod 600 /etc/sops/age/tachi.txt
sudo chown root:root /etc/sops/age/tachi.txt
sudo ln -sf tachi.txt /etc/sops/age/keys.txt
```

**Verification:**
```bash
ls -la /etc/sops/age/
# Should show:
# lrwxrwxrwx - root root keys.txt -> tachi.txt
# -rw------- - root root tachi.txt
```

### 2. Update NixOS SOPS Module

**File:** `modules/nixos/sops/default.nix`

**Change:**
```nix
# OLD:
keyFile = lib.mkOption {
  type = lib.types.path;
  default = "/home/adam/.config/sops/age/keys.txt";
  description = "Path to the sops age key file. Use keys.txt symlink for host-agnostic config.";
};

# NEW:
keyFile = lib.mkOption {
  type = lib.types.path;
  default = "/etc/sops/age/keys.txt";
  description = "Path to the sops age key file for system-level secrets. Use keys.txt symlink for host-agnostic config.";
};
```

**Impact:** This changes the default key path for ALL NixOS systems. Darwin module remains unchanged.

### 3. Set SOPS_AGE_KEY_FILE Environment Variable

This ensures when you manually edit secrets with `sops`, it uses the correct key on each system.

**File:** `homes/x86_64-linux/adam@tachi/default.nix`

**Add:**
```nix
{
  # ... existing config ...

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
  };
}
```

**Files:** `homes/aarch64-darwin/adam@rocinante/default.nix` and `homes/aarch64-darwin/adam@pallas/default.nix`

**Add:**
```nix
{
  # ... existing config ...

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
  };
}
```

**Impact:** The `sops` CLI will automatically use the correct key file on each system without needing to manually export the variable.

### 4. Rebuild System

```bash
sudo nixos-rebuild switch --flake .#tachi
```

**What happens:**
1. New activation scripts generated with `/etc/sops/age/keys.txt` path
2. SOPS secrets decryption runs during early boot
3. `/run/secrets-for-users/adam-password` gets created with correct password hash
4. User `adam` created with password from secrets file
5. Home-manager activation succeeds (comic-code-fonts accessible)

### 5. Verification Steps

**Check secrets exist:**
```bash
sudo ls -la /run/secrets-for-users/
# Should show: adam-password (106 bytes, mode 0400)

sudo ls -la /run/secrets/
# Should show: comic-code-fonts (~10MB, mode 0444)
```

**Check home-manager service:**
```bash
systemctl status home-manager-adam.service
# Should show: active (exited)
```

**Check environment variable:**
```bash
echo $SOPS_AGE_KEY_FILE
# Should show: /etc/sops/age/keys.txt
```

**Test password login:**
- Reboot the system
- At greetd login, enter username and password
- Should successfully login without needing recovery shell

**Test secrets editing:**
```bash
sops secrets/system-secrets.yaml
# Should open in editor without errors
# The SOPS_AGE_KEY_FILE env var ensures it uses /etc/sops/age/keys.txt
```

### 6. Update Documentation

**File:** `.claude/CLAUDE.md`

**Sections to update:**

1. **"Current Host Keys"** - Add note about NixOS vs Darwin locations
2. **"Common Commands > Secrets Management"** - Note env var is set automatically
3. **"File Locations"** - Document different locations per platform

**Changes:**

```markdown
**Current Host Keys**:
- `tachi` (NixOS): System key at `/etc/sops/age/tachi.txt` (public: `age1xeq2p622qm5ftc7kl23welzvc3552ngqc82df8t947u696ysxgts0mddmt`)
- `rocinante` (Darwin): User key at `~/.config/sops/age/rocinante.txt` (public: `age13nu8e3vrjek227g7rjq8jqerzpeft7xwcs2zgxajpg8gztzggv4ses4v8h`)
- `pallas` (Darwin): User key at `~/.config/sops/age/pallas.txt` (public: `age1s20cczctqy8w7l7frnpwfp70rdhz8r8ewm0t298q4vt8leyr7u6qnprs7a`)

**Common Commands**:
```bash
# Edit encrypted secrets
# Note: SOPS_AGE_KEY_FILE is set automatically per-system in home configs
sops secrets/system-secrets.yaml
sops secrets/comic-code-fonts.tar.gz
sops secrets/doom-fonts.tar.gz
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
    ├── nixos/sops/               # NixOS sops config (uses /etc/sops/age/)
    └── darwin/sops/              # Darwin sops config (uses ~/.config/sops/age/)

Local Keys (not in repo):
NixOS (tachi):
  /etc/sops/age/
  ├── keys.txt -> tachi.txt       # Symlink to current host key
  └── tachi.txt                   # Host-specific private key

Darwin (rocinante, pallas):
  ~/.config/sops/age/
  ├── keys.txt -> <hostname>.txt  # Symlink to current host key
  └── <hostname>.txt              # Host-specific private key

Runtime (system-level secrets):
NixOS:    /run/secrets-for-users/ # adam-password
          /run/secrets/           # comic-code-fonts
Darwin:   /var/lib/secrets/       # comic-code-fonts

Runtime (home-level secrets - decrypted during activation):
NixOS:    ~/.local/share/fonts/doom-fonts/
Darwin:   ~/Library/Fonts/doom-fonts/
```
```

## Future: Adding WSL2

When adding a WSL2 system, follow the NixOS pattern:

1. Generate age key on WSL2: `age-keygen -o /etc/sops/age/wsl-hostname.txt`
2. Add public key to `.sops.yaml`
3. Reencrypt secrets: `sops updatekeys secrets/*`
4. Create symlink: `ln -sf wsl-hostname.txt /etc/sops/age/keys.txt`
5. Set `SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt` in home config
6. The system will automatically decrypt secrets during early boot

## Rollback Plan

If something goes wrong:

1. **Immediate access:** Boot into recovery shell, set temporary password
2. **Restore key location:** Copy key back to `~/.config/sops/age/`
3. **Revert module change:** Change `modules/nixos/sops/default.nix` back to old path
4. **Rebuild:** `sudo nixos-rebuild switch --flake .#tachi`

## Security Considerations

**Question:** Is it less secure to have keys at `/etc/sops/age/` vs `~/.config/sops/age/`?

**Answer:** Not significantly. Both locations:
- Are readable only by root (mode 600, owner root:root)
- Require root privileges to access
- Are protected by system permissions

The main difference is backup strategy:
- User home keys: Backed up with dotfiles
- System keys: Need separate backup strategy (but same key, just different location)

**Recommendation:** Keep a backup of the age keys in 1Password (already storing master key there).

## Testing Checklist

Before considering this complete:

- [ ] Age key exists at `/etc/sops/age/keys.txt` on tachi
- [ ] NixOS SOPS module updated to use `/etc/sops/age/keys.txt`
- [ ] `SOPS_AGE_KEY_FILE` set in all three home configs
- [ ] System rebuilds without errors
- [ ] `/run/secrets-for-users/adam-password` exists and has content
- [ ] `/run/secrets/comic-code-fonts` exists and has content
- [ ] `home-manager-adam.service` is active/exited (not failed)
- [ ] Can login at greetd with password
- [ ] `echo $SOPS_AGE_KEY_FILE` shows correct path
- [ ] `sops secrets/system-secrets.yaml` opens without errors
- [ ] CLAUDE.md updated with new documentation
- [ ] This plan document moved to `docs/` or deleted after completion

## References

- SOPS-nix documentation: https://github.com/Mic92/sops-nix
- Age encryption: https://age-encryption.org/
- Boot logs showing error: `journalctl -b | grep sops-install-secrets`
