{
  super,
  pkgs,
  flake,
  system,
  ...
}:
let
  neovim = flake.inputs.modular-neovim.buildNeovimPackage.${system} pkgs [
    {
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

        folding = {
          enable = true;
          mode = "ufo";
          defaultFoldNumber = 99;
        };

        ai.copilot = {
          enableAll = true;
          completion = {
            workspaceFolders =
              if super.meta.isDarwin then
                [
                  "/Users/${super.meta.username}/projects"
                  "/Users/${super.meta.username}/Projects"
                ]
              else
                [
                  "/home/${super.meta.username}/projects"
                  "/home/${super.meta.username}/Projects"
                ];
          };
          chat = {
            prompts = [
              {
                name = "NibCommit";
                prompt = "Write commit message for the change. Make sure the title has maximum 50 characters and is a concise summary of the included work, do not under any circumstances go over 50 characters. Underneath the title include a set of bullet points with a `-` summarising important changes. Wrap the whole message in code block with language gitcommit. If there are any variable, class, function or other names from the code wrap them in backticks.";
                selection = ''
                  function(source)
                    return select.gitdiff(source, true)
                  end
                '';
              }
            ];
          };
        };

        autocomplete = {
          enable = true;
        };

        languages = {
          enableTreesitter = true;
          enableLSP = true;
          enableDebugger = true;
          enableFormat = true;
          enableLinting = true;
          enableAll = true;
        };

        debugger.enable = true;

        review = {
          enable = true;
          # Home manage secrets work around see: https://github.com/ryantm/agenix/issues/50
          # This should be using config.age, but was returning the wrong path
          tokenPath =
            if super.meta.isDarwin then
              "$(getconf DARWIN_USER_TEMP_DIR)/agenix.d/1/gh_pat"
            else
              "/run/user/1000/agenix.d/1/gh_pat";
        };

        nmap =
          { }
          // (
            if super.meta.isDarwin then
              { "<C-f>" = "<cmd>silent !tmux neww ${pkgs.f-tmux}/bin/f-fzf-tmux-wrapper<CR>"; }
            else
              { }
          );
      };
    }
  ];
in
{
  imports = [ ../../secrets/github ];
  home.packages =
    with pkgs;
    [
      jq
      direnv
      difftastic
      nodePackages.json-diff
      _1password
      neovim
    ]
    ++ (with pkgs; if super.meta.isDarwin then [ f ] else [ ]);
}
