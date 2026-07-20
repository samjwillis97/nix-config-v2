{ pkgs, config, ... }:
let
  # Jira token setup - https://github.com/ankitpokhrel/jira-cli/issues/850#issuecomment-4540653500
  # mySecureJira = pkgs.writeShellApplication {
  #   name = "jira";
  #   runtimeInputs = [ pkgs.jira-cli-go ];
  #   text = ''
  #     JIRA_API_TOKEN=$(cat "${config.age.secrets.jira-token.path}")
  #     export JIRA_API_TOKEN
  #     ${pkgs.jira-cli-go}/bin/jira "$@"
  #   '';
  # };
in
{
  imports = [
    ../../secrets/work
  ];

  home.packages = with pkgs; [
    awscli2
    # jira-cli-go
    # mySecureJira
  ];
  #
  # modules.pi.sandbox.extraAllowedPackages = [ mySecureJira ];
  # modules.pi.sandbox.extraStateDirs = [
  #   "$HOME/.config/.jira"
  # ];
  # modules.pi.sandbox.extraStateFiles = [
  #   "$(cat \"${config.age.secrets.jira-token.path}\")"
  # ];
  # modules.pi.sandbox.allowedDomains = {
  #   "api.atlassian.com" = "tunnel";
  # };
}
