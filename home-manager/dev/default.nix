{ super, pkgs, config, flake, system, ... }:
let
  neovim = flake.inputs.modular-neovim.buildNeovimPackage.${system} pkgs [{
    config.vim = {
      theme = {
        enable = true;
        name = "catppuccin";
      };
      visuals = {
        enable = true;
        borderType = "none";
        transparentBackground = true;
      };

      filetree = {
        enable = true;
        location = "center";
      };
      statusline.enable = true;
      qol.enable = true;

      git.enable = true;
      treesitter = {
        enable = true;
        fold = true;
      };
      telescope.enable = true;

      lsp = {
        enable = true;
        codeActionMenu.enable = true;
        lspconfig.enable = true;
        lspkind.enable = true;
      };

      formatter.enable = true;

      autocomplete = {
        enable = true;
        copilot = {
          enable = true;
          workspaceFolders = if super.meta.isDarwin then [
            "/Users/${super.meta.username}/projects"
            "/Users/${super.meta.username}/Projects"
          ] else [
            "/home/${super.meta.username}/projects"
            "/home/${super.meta.username}/Projects"
          ];
        };
      };

      languages = {
        enableTreesitter = true;
        enableLSP = true;
        enableDebugger = true;
        enableFormat = false;
        enableAll = true;
      };

      debugger.enable = true;

      review = {
        enable = true;
        # Home manage secrets work around see: https://github.com/ryantm/agenix/issues/50
        # This should be using config.age, but was returning the wrong path
        tokenPath = if super.meta.isDarwin then
          "$(getconf DARWIN_USER_TEMP_DIR)/agenix.d/1/gh_pat"
        else
          "/run/user/1000/agenix.d/1/gh_pat";
      };

      nmap = { "<C-f>" = "<cmd>silent !tmux neww tmux-sessionizer<CR>"; };
    };
  }];
in {
  imports = [ ../../secrets ];
  home.packages = with pkgs; [
    jq
    direnv
    difftastic
    nodePackages.json-diff
    _1password
    neovim
    nodePackages.wrangler
  ];
}
