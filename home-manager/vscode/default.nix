{ config, pkgs, ... }:
let
  github-mcp-wrapped = pkgs.writeShellScriptBin "github-mcp-wrapped" ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.age.secrets.gh_pat.path})
    ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
  '';

  node = pkgs.nodejs;
in
{
  home.packages = [
    node
  ];

  programs.vscode = {
    enable = true;

    mutableExtensionsDir = false;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        # Theme
        catppuccin.catppuccin-vsc

        # Javascript/Typescript
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        yoavbls.pretty-ts-errors

        # YAML
        redhat.vscode-yaml

        # Nix
        mkhl.direnv
        jnoortheen.nix-ide

        # Docker
        ms-azuretools.vscode-docker

        # Intellisense
        visualstudioexptteam.vscodeintellicode
        visualstudioexptteam.intellicode-api-usage-examples
        christian-kohler.path-intellisense

        # Copilot
        github.copilot
        github.copilot-chat

        # Roo Code AI
        rooveterinaryinc.roo-cline

        # Github
        github.vscode-pull-request-github
        github.vscode-github-actions

        # Terraform
        hashicorp.terraform

        # Markdown
        bierner.markdown-mermaid
        bierner.markdown-preview-github-styles

        # Vim
        # Not usable until this is fixed https://github.com/vscode-neovim/vscode-neovim/issues/2407
        # asvetliakov.vscode-neovim
        # Temporarily using this instead
        vscodevim.vim
      ];

      globalSnippets = {};

      keybindings = [
        # # Fix for: https://github.com/vscode-neovim/vscode-neovim/issues/2434
        #  {
        #   "key" = "ctrl+u";
        #   "command" =  "vscode-neovim.send";
        #   "args" = "<C-u>";
        #   "when" = "editorTextFocus && neovim.ctrlKeysNormal.u && neovim.init && neovim.mode != 'insert' && editorLangId not in 'neovim.editorLangIdExclusions'";
        # }
        # {
        #   "key" = "ctrl+d";
        #   "command" = "vscode-neovim.send";
        #   "args" = "<C-d>";
        #   "when" = "editorTextFocus && neovim.ctrlKeysNormal.d && neovim.init && neovim.mode != 'insert' && editorLangId not in 'neovim.editorLangIdExclusions'";
        # }
        {
          key = "ctrl+h";
          command = "workbench.action.navigateLeft";
          when = "explorerViewletVisible && fileExplorerFocus && !inputFocus";
        }
        {
          key = "ctrl+l";
          command = "workbench.action.navigateRight";
          when = "explorerViewletVisible && fileExplorerFocus && !inputFocus";
        }
      ];

      userSettings = {
        "extensions.experimental.affinity" = {
          "vscodevim.vim" = 1;
        };

        # Styling
        "editor.fontFamily" = "FiraMono Nerd Font Mono";
        "workbench.colorTheme" = "Catppuccin Mocha";
        "editor.bracketPairColorization.enabled" = true;
        "workbench.editor.showTabs" = false;
        "workbench.startupEditor" = "newUntitledFile";
        "editor.minimap.enabled" = false;
        "editor.lineNumbers" = "relative";

        # Copilot
        # "github.copilot.selectedCompletionModel" = "gpt-4o-copilot";
        "github.copilot.selectedCompletionModel" = "claude-3.7-sonnet";
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.chat.codeGeneration.useInstructionFiles" = true;

        # Copilot Agent mode
        "chat.agent.enabled" = true;
        "chat.agent.maxRequests" = 30;

        # Respecting .gitignore files
        "search.useIgnoreFiles" = true; 
        "search.useGlobalIgnoreFiles" = true;
        "search.useParentIgnoreFiles" = true;
        "explorer.excludeGitIgnore" = true;
        "search.exclude" = {
          "package-lock.json" = true;
        };

        # Copilot Agent MCP
        "mcp" = {
          "inputs" = [];

          "servers" = {
            github = {
              type = "stdio";
              command = "${github-mcp-wrapped}/bin/github-mcp-wrapped";
              args = [ "stdio" ];
            };
            sentry = {
              type = "stdio";
              command = "${node}/bin/npx";
              args = [ 
                "-y"
                "mcp-remote"
                "https://mcp.sentry.dev/sse"
              ];
              env = {};
            };
            # atlassian = {
            #   transport = "sse";
            #   command = "${node}/bin/npx";
            #   args = [
            #     "-y"
            #     "mcp-remote"
            #     "https://mcp.atlassian.com/v1/sse"
            #   ];
            #   env = {};
            # };
          };
        };

        "editor.formatOnSave" = true;
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[json]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[yaml]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[dockercompose]" = {
          "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
        };
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };

        "typescript.updateImportsOnFileMove.enabled" = "always";

        "direnv.path.executable" = "${pkgs.direnv}/bin/direnv";
        "direnv.restart.automatic" = true;

        "git.autofetch" = false;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;

        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
        "nix.serverSettings" = {
          nixd = {
            formatting.command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
            "options" = {
              # darwin.expr = ''(builtins.getFlake ).options.darwin'';
              # home-manager.expr = ''(builtins.getFlake "${nix-options}").options.home-manager'';
              nixos.expr = ''(builtins.getFlake "$HOME/code/github.com/samjwillis97/nix-config-v2/main").nixosConfigurations.<name>.options'';
            };
          };
        };

        "vim.easymotion" = true;
        "vim.surround" = true;

        "vim.incsearch" = true;
        "vim.useSystemClipboard" = true;
        "vim.useCtrlKeys" = true;
        "vim.hlsearch" = true;
        "vim.insertModeKeyBindings" = [
          {
            "before" = ["j" "k"];
            "after" = ["<Esc>"];
          }
        ];
        "vim.normalModeKeyBindingsNonRecursive" = [
          {
            "before" = ["<C-j>"];
            "commands" = ["workbench.action.navigateDown"];
          }
          {
            "before" = ["<C-k>"];
            "commands" = ["workbench.action.navigateUp"];
          }
          {
            "before" = ["<C-h>"];
            "commands" = ["workbench.action.navigateLeft"];
          }
          {
            "before" = ["<C-l>"];
            "commands" = ["workbench.action.navigateRight"];
          }
          {
            "before" = ["<leader>" "f" "f"];
            "commands" = ["workbench.action.quickOpen"];
          }
          {
            "before" = ["<leader>" "s" "f"];
            "commands" = ["workbench.action.findInFiles"];
          }
          {
            "before" = ["g" "r"];
            "commands" = ["editor.action.goToReferences"];
          }
          {
            "before" = ["<leader>" "space"];
            "commands" = [":nohlsearch"];
          }
        ];
        "vim.leader" = "\\";
        # keys to be handled by vscode instead of vim
        "vim.handleKeys" = {
        };


      #   "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim-vscode}/bin/nvim";
      #   "vscode-neovim.neovimClean" = true; # starts neovim without any plugins
      #   "vscode-neovim.compositeKeys" = {
      #     "jk" = {
      #       # Use lua to execute any logic
      #       "command" =  "vscode-neovim.lua";
      #       "args" =  [
      #         [
      #           "local code = require('vscode')"
      #           "code.action('vscode-neovim.escape')"
      #         ]
      #       ];
      #     };
      #   };

        "roo-cline.allowedCommands" = [
          "npm test"
          "npm install"
          "tsc"
          "git log"
          "git diff"
          "git show"
        ];
      };
    };
  };
}
