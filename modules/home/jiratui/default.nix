{ lib, config, pkgs, osConfig, ... }:

let
  cfg = config.bravo.jiratui;
in
{
  options.bravo.jiratui = {
    enable = lib.mkEnableOption "jiratui - Jira TUI client";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.unstable.jiratui ];

    sops = {
      age.keyFile = osConfig.sops.age.keyFile;

      secrets.jiratui-api-token = {
        sopsFile = ../../../secrets/system-secrets.yaml;
        key = "jiratui-api-token";
      };

      templates."jiratui-config" = {
        content = ''
          jira_api_username: 'REDACTED_EMAIL'
          jira_api_token: '${config.sops.placeholder.jiratui-api-token}'
          jira_api_base_url: 'https://REDACTED_URL'
          jira_api_version: 3

          jira_default_project_key: 'LOTC'
          jira_sprint_field_id: 'customfield_10020'
          jira_account_id: 'REDACTED_ACCOUNT_ID'

          tui_title_include_jira_server_title: True
          theme: catppuccin-mocha

          on_start_up_only_fetch_projects: False
          search_on_startup: True

          git_repositories:
           1:
              name: 'FIST'
              path: '~/projects/fist/.git'

          pre_defined_jql_expressions:
            1:
              label: "My issues - current sprint"
              expression: 'project = LOTC AND "Squad" = "[LOT] Fulfillment Beta" AND assignee = currentUser() AND sprint in openSprints()'
            2:
              label: "Beta - current sprint"
              expression: 'project = LOTC AND "Squad" = "[LOT] Fulfillment Beta" AND sprint in openSprints()'
            3:
              label: "Beta - all issues"
              expression: 'project = LOTC AND "Squad" = "[LOT] Fulfillment Beta"'

          jql_expression_id_for_work_items_search: 1
        '';
        path = "${config.home.homeDirectory}/.config/jiratui/config.yaml";
      };
    };
  };
}
