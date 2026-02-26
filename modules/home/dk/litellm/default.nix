{ lib, config, osConfig, ... }:
let
  cfg = config.bravo.dk.litellm;
in
{
  options.bravo.dk.litellm = {
    enable = lib.mkEnableOption "LiteLLM proxy authentication for Claude Code";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      CLAUDE_CODE_USE_BEDROCK = "1";
      CLAUDE_CODE_SKIP_BEDROCK_AUTH = "1";
    };

    sops = {
      age.keyFile = osConfig.sops.age.keyFile;

      secrets.litellm-virtual-key = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "litellm-virtual-key";
      };

      secrets.dk-litellm-base-url = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-litellm-base-url";
      };

      templates."litellm-env" = {
        content = ''
          export ANTHROPIC_AUTH_TOKEN="${config.sops.placeholder.litellm-virtual-key}"
          export ANTHROPIC_BEDROCK_BASE_URL="${config.sops.placeholder.dk-litellm-base-url}"
        '';
        path = "${config.home.homeDirectory}/.config/litellm/env";
      };
    };

    programs.zsh.initContent = lib.mkOrder 500 ''
      if [ -f "${config.home.homeDirectory}/.config/litellm/env" ]; then
        source "${config.home.homeDirectory}/.config/litellm/env"
      fi
    '';
  };
}
