{ lib, config, pkgs, osConfig, ... }:

let
  cfg = config.bravo.dk.jiratui;
  p = config.sops.placeholder;
in
{
  options.bravo.dk.jiratui = {
    enable = lib.mkEnableOption "jiratui - Jira TUI client";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.unstable.jiratui ];

    sops = {
      age.keyFile = osConfig.sops.age.keyFile;

      secrets.jiratui-api-token = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "jiratui-api-token";
      };

      secrets.dk-jira-username = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-username";
      };

      secrets.dk-jira-base-url = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-base-url";
      };

      secrets.dk-jira-account-id = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-account-id";
      };

      secrets.dk-jira-project-key = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-project-key";
      };

      secrets.dk-jira-sprint-field = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-sprint-field";
      };

      secrets.dk-jira-squad = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-squad";
      };

      secrets.dk-jira-repo-name = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-repo-name";
      };

      secrets.dk-jira-repo-path = {
        sopsFile = ../../../../secrets/system-secrets.yaml;
        key = "dk-jira-repo-path";
      };

      templates."jiratui-config" = {
        content = ''
          jira_api_username: '${p.dk-jira-username}'
          jira_api_token: '${p.jiratui-api-token}'
          jira_api_base_url: '${p.dk-jira-base-url}'
          jira_api_version: 3

          jira_default_project_key: '${p.dk-jira-project-key}'
          jira_sprint_field_id: '${p.dk-jira-sprint-field}'
          jira_account_id: '${p.dk-jira-account-id}'

          tui_title_include_jira_server_title: True
          theme: catppuccin-mocha

          on_start_up_only_fetch_projects: False
          search_on_startup: True

          git_repositories:
           1:
              name: '${p.dk-jira-repo-name}'
              path: '${p.dk-jira-repo-path}'

          pre_defined_jql_expressions:
            1:
              label: "My issues - current sprint"
              expression: 'project = ${p.dk-jira-project-key} AND "Squad" = "${p.dk-jira-squad}" AND assignee = currentUser() AND sprint in openSprints()'
            2:
              label: "Beta - current sprint"
              expression: 'project = ${p.dk-jira-project-key} AND "Squad" = "${p.dk-jira-squad}" AND sprint in openSprints()'
            3:
              label: "Beta - all issues"
              expression: 'project = ${p.dk-jira-project-key} AND "Squad" = "${p.dk-jira-squad}"'

          jql_expression_id_for_work_items_search: 1
        '';
        path = "${config.home.homeDirectory}/.config/jiratui/config.yaml";
      };
    };
  };
}
