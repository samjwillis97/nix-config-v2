{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;

    mutableExtensionsDir = true;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        catppuccin.catppuccin-vsc

        esbenp.prettier-vscode
        dbaeumer.vscode-eslint

        visualstudioexptteam.vscodeintellicode
        visualstudioexptteam.intellicode-api-usage-examples

        github.copilot
        github.copilot-chat

        github.vscode-pull-request-github

        christian-kohler.path-intellisense

        yoavbls.pretty-ts-errors
      ];

      userSettings = {
        "workbench.colorTheme" = "Catppuccin Mocha";

        "github.copilot.selectedCompletionModel" = "gpt-4o-copilot";
        "github.copilot.nextEditSuggestions.enabled" = true;
      };
    };
  };
}
