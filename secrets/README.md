# Secrets Setup Guide

This directory contains encrypted secrets managed by sops-nix.

## How It Works

The `modules/nixos/sops/default.nix` module automatically configures sops-nix for all NixOS systems with:
- Uses SSH host key (`/etc/ssh/ssh_host_ed25519_key`) for encryption
- Auto-generates age key at `/var/lib/sops-nix/key.txt`
- Defaults to `secrets/system-secrets.yaml` for secrets
- No configuration needed in individual system files

## Initial Setup on Tachi

### 1. Get SSH Host Key's Age Public Key

On the **tachi** machine, get the age public key from the SSH host key:

```bash
sudo nix-shell -p ssh-to-age --run 'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
```

Copy the output (starts with `age1...`).

### 2. Update .sops.yaml

Edit `.sops.yaml` in the repo root and replace `YOUR_AGE_PUBLIC_KEY_HERE` with the key from step 1.

### 3. Create Password Hash

Generate a hashed password for adam:

```bash
nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'
```

Copy the hash (starts with `$6$...`).

### 4. Create and Encrypt Secrets File

```bash
nix-shell -p sops --run 'sops secrets/system-secrets.yaml'
```

In the editor, add:

```yaml
adam-password: $6$YOUR_HASHED_PASSWORD_HERE
```

Save and close (file will be encrypted automatically).

### 5. Rebuild

```bash
switch
```

The age key will be auto-generated on first boot.

### 6. Verify

```bash
ls -la /run/secrets/adam-password
ls -la /var/lib/sops-nix/key.txt
```

## Adding More Secrets

### Edit Existing Secrets

```bash
nix-shell -p sops --run 'sops secrets/system-secrets.yaml'
```

### Use Secrets in Configuration

In the sops module or system configuration:

```nix
sops.secrets.my-api-key = { };

# Then reference it
services.myservice.apiKeyFile = config.sops.secrets.my-api-key.path;
```

### Add More User Passwords

In the sops module, add:

```nix
secrets.alice-password = { neededForUsers = true; };
```

In the system configuration:

```nix
users.users.alice = {
  isNormalUser = true;
  hashedPasswordFile = config.sops.secrets.alice-password.path;
};
```

Then add the secret to the encrypted file.

## Security Notes

- **SSH Host Key**: `/etc/ssh/ssh_host_ed25519_key` - backup this key!
- **Age Key**: Auto-generated at `/var/lib/sops-nix/key.txt`
- **Encrypted Files**: Safe to commit (`secrets/system-secrets.yaml`)
- **Public Keys**: Safe to commit (`.sops.yaml`)
