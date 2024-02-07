{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    extensions = with pkgs.vscode-extensions; [
      ms-dotnettools.csharp
      catppuccin.catppuccin-vsc
    ];

    userSettings = { "workbench.colorTheme" = "Catppuccin Mocha"; };
  };
}
