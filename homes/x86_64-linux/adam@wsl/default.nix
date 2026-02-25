{ pkgs, ... }:
let
  fix-wsl-firewall = pkgs.writeShellScriptBin "fix-wsl-firewall" ''
    set -euo pipefail

    PS_SCRIPT=$(mktemp /tmp/fix-firewall-XXXXXX.ps1)
    trap 'rm -f "$PS_SCRIPT"' EXIT

    cat > "$PS_SCRIPT" << 'PSEOF'
    # Docker WSL Firewall Rules
    # Idempotent: removes and recreates rules each run
    # To add a new port, add an entry to the $rules array below
    $rules = @(
        @{ Port = 80;   Name = "HTTP" }
        @{ Port = 81;   Name = "Nginx Proxy Manager Admin" }
        @{ Port = 443;  Name = "HTTPS" }
        @{ Port = 5001; Name = "Dockge" }
    )

    $prefix = "Docker WSL"

    Write-Host "Configuring Windows Firewall rules for Docker WSL services..." -ForegroundColor Cyan
    Write-Host ""

    foreach ($rule in $rules) {
        $displayName = "$prefix - $($rule.Name) ($($rule.Port))"
        Remove-NetFirewallRule -DisplayName $displayName -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName $displayName `
            -Direction Inbound -Action Allow `
            -Protocol TCP -LocalPort $rule.Port | Out-Null
        Write-Host "  Allowed port $($rule.Port) ($($rule.Name))" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Done. All firewall rules applied." -ForegroundColor Cyan
    Write-Host "Press any key to close..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    PSEOF

    WIN_SCRIPT=$(wslpath -w "$PS_SCRIPT")

    echo "Configuring Windows Firewall rules for Docker WSL services"
    echo "Ports: 80 (HTTP), 81 (NPM Admin), 443 (HTTPS), 5001 (Dockge)"
    echo ""
    echo "Requesting administrator privileges (UAC prompt)..."

    powershell.exe -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-ExecutionPolicy Bypass -File \"$WIN_SCRIPT\"'"

    echo ""
    echo "Verifying rules..."
    powershell.exe -Command "Get-NetFirewallRule -DisplayName 'Docker WSL*' | Select-Object DisplayName, Enabled | Format-Table -AutoSize"
  '';
in
{
  # Enable fontconfig for proper font rendering
  fonts.fontconfig.enable = true;

  # Bravo modules
  bravo = {
    bat.enable = true;
    claude.enable = true;
    comic-code-fonts.enable = true;
    direnv.enable = true;
    doom-emacs.enable = true;
    doom-fonts.enable = true;
    gpg.enable = true;
    lang.elixir.enable = true;
    neovim.enable = true;
    zsh.enable = true;
  };

  # Shell configuration
  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/.config/snowfall#wsl";
    rebuild-test = "sudo nixos-rebuild test --flake ~/.config/snowfall#wsl";
  };

  programs.home-manager.enable = true;

  # Home Manager settings
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "25.05";

    packages = with pkgs; [
      # WSL utilities
      wslu
      fix-wsl-firewall

      # Development tools
      autoconf
      automake
      cmake
      gnumake
      gcc

      # CLI utilities
      curl
      eza
      fd
      jq
      ripgrep
      zip
      nixfmt-rfc-style
      fontconfig
      ffmpeg

      # Audio transcription
      bravo.transcribe-audio
      bravo.process-transcript
    ];

    sessionVariables = {
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
    };
  };
}
