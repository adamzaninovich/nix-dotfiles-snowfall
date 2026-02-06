{ lib, config, osConfig, ... }:
let
  cfg = config.bravo.dk.litellm;
in
{
  options.bravo.dk.litellm = {
    enable = lib.mkEnableOption "LiteLLM proxy authentication for Claude Code";

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = "REDACTED_URL";
      description = "LiteLLM proxy base URL for Bedrock API";
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      CLAUDE_CODE_USE_BEDROCK = "1";
      CLAUDE_CODE_SKIP_BEDROCK_AUTH = "1";
      ANTHROPIC_BEDROCK_BASE_URL = cfg.baseUrl;
    };

    sops = {
      age.keyFile = osConfig.sops.age.keyFile;

      secrets.litellm-virtual-key = {
        sopsFile = ../../../../secrets/pallas-secrets.yaml;
        key = "litellm-virtual-key";
      };
    };

    programs.zsh.initContent = lib.mkOrder 500 ''
      if [ -f "${config.sops.secrets.litellm-virtual-key.path}" ]; then
        export ANTHROPIC_AUTH_TOKEN="$(cat ${config.sops.secrets.litellm-virtual-key.path})"
      fi
    '';
  };
}
