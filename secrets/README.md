# Secrets Setup Guide

This directory contains encrypted secrets managed by sops-nix.

## Architecture

**Key System:**
- **Master key**: Stored in 1password, used only for adding new hosts and reencryption
- **Host keys**: Per-machine age keys stored at `~/.config/sops/age/<hostname>.txt`
- Each machine only needs its own host key to decrypt secrets
- Secrets are encrypted with ALL keys (master + all hosts)

**Current Hosts:**
- `tachi`: `~/.config/sops/age/tachi.txt` → `age1xeq2p622qm5ftc7kl23welzvc3552ngqc82df8t947u696ysxgts0mddmt`
- `rocinante`: `~/.config/sops/age/rocinante.txt` → `age13nu8e3vrjek227g7rjq8jqerzpeft7xwcs2zgxajpg8gztzggv4ses4v8h`
- `pallas`: `~/.config/sops/age/pallas.txt` → `age1s20cczctqy8w7l7frnpwfp70rdhz8r8ewm0t298q4vt8leyr7u6qnprs7a`
- `wsl`: `~/.config/sops/age/wsl.txt` → `age1dj7j53uh0nu25v0yxrfvgsufuzjqwpghtnusaguur56cv8522y2s27n0r0`

## Editing Secrets on Existing Machine

On a machine that's already set up (like tachi or rocinante):

```bash
# Set the age key file (optional but recommended for clarity)
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# Edit system secrets (YAML)
nix-shell -p sops --run 'sops secrets/system-secrets.yaml'

# Edit binary secrets (fonts)
nix-shell -p sops --run 'sops secrets/comic-code-fonts.tar.gz'
nix-shell -p sops --run 'sops secrets/doom-fonts.tar.gz'
```

Sops automatically uses `~/.config/sops/age/keys.txt` (which is a symlink to your host key), but setting `SOPS_AGE_KEY_FILE` explicitly ensures the correct key is used.

**Note**: If sops can't find your key, explicitly set the environment variable:
```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
nix-shell -p sops --run 'sops secrets/system-secrets.yaml'
```

## Setting Up a New Machine

### 1. On the New Machine

Generate a host-specific age key:

```bash
mkdir -p ~/.config/sops/age
nix-shell -p age --run 'age-keygen -o ~/.config/sops/age/<hostname>.txt'
```

This will output the public key (starts with `age1...`). Save it for step 2.

Create the symlink for sops CLI:

```bash
cd ~/.config/sops/age
ln -sf <hostname>.txt keys.txt
```

### 2. On Any Machine with Internet

Add the new host's public key to `.sops.yaml`:

```yaml
keys:
  - &master age1x4nscwmglq7fxrzhyeqnw43tw5py0cl3gcedwmxwztvxfw3f6crq0kkj8g
  - &tachi age1xeq2p622qm5ftc7kl23welzvc3552ngqc82df8t947u696ysxgts0mddmt
  - &newhost age1...  # Add your new host's public key here

creation_rules:
  - path_regex: secrets/system-secrets\.yaml$
    key_groups:
      - age:
          - *master
          - *tachi
          - *newhost  # Add to all relevant creation rules
  - path_regex: secrets/comic-code-fonts\.tar\.gz$
    key_groups:
      - age:
          - *master
          - *tachi
          - *newhost  # Add to all relevant creation rules
```

Commit and push this change (no secrets needed yet).

### 3. Reencrypt Secrets with New Key

On any machine with the master key:

```bash
# Copy master key from 1password
cp /path/to/master.txt ~/.config/sops/age/master.txt

# Create temporary symlink to use master key
cd ~/.config/sops/age
ln -sf master.txt keys.txt

# Set environment variable so sops can find the key
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# Reencrypt all secrets to include the new host key
cd ~/.config/snowfall
nix-shell -p sops --run 'sops updatekeys secrets/system-secrets.yaml'
nix-shell -p sops --run 'sops updatekeys secrets/comic-code-fonts.tar.gz'

# Commit and push the reencrypted files
git add secrets/
git commit -m "Add newhost to secrets encryption"
git push

# Clean up: restore symlink to your host key
cd ~/.config/sops/age
ln -sf tachi.txt keys.txt  # Or whatever your host is (or newhost.txt if on new host)
rm master.txt
```

### 4. On the New Machine

Pull the repo and build:

```bash
cd ~/.config/snowfall
git pull
sudo nixos-rebuild switch --flake .#newhost
```

The system will decrypt secrets using the host key at activation time.

### 5. Update Sops Module (If Per-Host Config Needed)

If you have host-specific sops configuration, update `modules/nixos/sops/default.nix` or create a host-specific override in `systems/x86_64-linux/<hostname>/default.nix`:

```nix
{
  sops.age.keyFile = "/home/adam/.config/sops/age/<hostname>.txt";
}
```

For tachi, this is already configured in the module.

## Adding New Secrets

### Add a Text Secret

1. Edit the encrypted file:
   ```bash
   export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
   nix-shell -p sops --run 'sops secrets/system-secrets.yaml'
   ```

2. Add your secret in YAML format:
   ```yaml
   my-new-secret: my-secret-value
   ```

3. Configure in `modules/nixos/sops/default.nix`:
   ```nix
   sops.secrets.my-new-secret = { };
   ```

4. Use in your configuration:
   ```nix
   services.myservice.secretFile = config.sops.secrets.my-new-secret.path;
   ```

### Add a Binary Secret

1. Create the unencrypted file in a temp location:
   ```bash
   cp /path/to/secret.bin /tmp/secret.bin
   ```

2. Add creation rule to `.sops.yaml`:
   ```yaml
   - path_regex: secrets/secret\.bin$
     key_groups:
       - age:
           - *master
           - *tachi
           # Add all host keys
   ```

3. Encrypt the file:
   ```bash
   cp /tmp/secret.bin secrets/secret.bin
   nix-shell -p sops --run 'sops -e -i secrets/secret.bin'
   ```

4. Configure in sops module:
   ```nix
   sops.secrets.my-binary = {
     sopsFile = ../../../secrets/secret.bin;
     format = "binary";
   };
   ```

## Adding User Passwords

1. Generate password hash:
   ```bash
   nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'
   ```

2. Add to encrypted secrets:
   ```bash
   export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
   nix-shell -p sops --run 'sops secrets/system-secrets.yaml'
   ```

   Add:
   ```yaml
   username-password: $6$your_hashed_password_here
   ```

3. Configure in sops module:
   ```nix
   sops.secrets.username-password = { neededForUsers = true; };
   ```

4. Use in user configuration:
   ```nix
   users.users.username = {
     isNormalUser = true;
     hashedPasswordFile = config.sops.secrets.username-password.path;
   };
   ```

## Troubleshooting

### "no key could be found to decrypt the data key"

**Cause**: Your host key isn't authorized to decrypt the secret.

**Solution**: Reencrypt secrets with your host key included (see "Reencrypt Secrets with New Key" above).

### "error loading config: no matching creation rules found"

**Cause**: File path doesn't match any regex in `.sops.yaml`.

**Solution**:
- Check that the file path matches the regex (e.g., `secrets/system-secrets.yaml`)
- Make sure you're running sops from the repo root where `.sops.yaml` exists
- Use `-i` flag to encrypt in-place: `sops -e -i secrets/file.yaml`

### Permission denied when editing secrets

**Cause**: No readable private key found at `~/.config/sops/age/keys.txt`.

**Solution**:
```bash
# Check that keys.txt exists and is a symlink to your host key
ls -la ~/.config/sops/age/

# Recreate symlink if needed
cd ~/.config/sops/age
ln -sf tachi.txt keys.txt
```

### System fails to decrypt at activation

**Cause**: Key file specified in sops module doesn't exist or is wrong.

**Solution**:
- Check `modules/nixos/sops/default.nix` has correct `age.keyFile` path
- Verify the key file exists: `ls -la ~/.config/sops/age/tachi.txt`
- Make sure the key has correct permissions (600)

## Security Notes

- **Host Keys**: Stored in user home directory (`~/.config/sops/age/<hostname>.txt`), backed up with dotfiles
- **Master Key**: Stored in 1password, never committed to repo, only used temporarily for reencryption
- **Encrypted Files**: Safe to commit (`secrets/*.yaml`, `secrets/*.tar.gz`)
- **Public Keys**: Safe to commit (`.sops.yaml`)
- **.sops.yaml**: Contains only public keys, safe to commit

## Key Management

### Backing Up Keys

**Host keys**: Already in your dotfiles at `~/.config/sops/age/`
- Make sure to back up your entire `.config` directory

**Master key**: Stored in 1password
- Should be the only copy
- Download temporarily when needed for reencryption

### Rotating Keys

If a host key is compromised:

1. Generate new key for that host
2. Update `.sops.yaml` with new public key
3. Reencrypt all secrets using master key
4. Deploy new key to the compromised host
5. Rebuild the system

If master key is compromised:

1. Generate new master key
2. Update `.sops.yaml` with new master public key
3. Reencrypt all secrets
4. Update master key in 1password
5. Destroy old master key

## File Locations

```
Repository:
~/.config/snowfall/
├── .sops.yaml                           # Encryption configuration (public keys)
├── secrets/
│   ├── system-secrets.yaml              # Encrypted YAML secrets
│   ├── comic-code-fonts.tar.gz          # Encrypted binary (both platforms)
│   └── doom-fonts.tar.gz                # Encrypted binary (both platforms)
└── modules/
    ├── nixos/sops/default.nix           # NixOS sops-nix configuration
    ├── darwin/sops/default.nix          # Darwin sops-nix configuration
    └── home/doom-fonts/default.nix      # Home-level doom-fonts decryption

Local Keys (not in repo):
~/.config/sops/age/
├── keys.txt                             # Symlink to current host key
└── <hostname>.txt                       # Host-specific private key

Runtime (system-level secrets):
NixOS (/run/secrets/):
├── adam-password                        # Decrypted password
└── comic-code-fonts                     # Decrypted fonts tarball

Darwin (/var/lib/secrets/):
└── comic-code-fonts                     # Decrypted fonts tarball

Runtime (home-level secrets - decrypted during home activation):
NixOS:    ~/.local/share/fonts/doom-fonts/
Darwin:   ~/Library/Fonts/doom-fonts/

Note: doom-fonts uses home-level decryption on both platforms:
- Decrypted by doom-fonts home module during activation (not system sops)
- Automatically enabled when doom-emacs is enabled
- Uses osConfig.sops.age.keyFile for decryption
```
