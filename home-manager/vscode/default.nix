{ config, pkgs, ... }:
let
  github-mcp-wrapped = pkgs.writeShellScriptBin "github-mcp-wrapped" ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.age.secrets.gh_pat.path})
    ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
  '';
in
{
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

      # keybindings = [
      #   # Fix for: https://github.com/vscode-neovim/vscode-neovim/issues/2434
      #    {
      #     "key" = "ctrl+u";
      #     "command" =  "vscode-neovim.send";
      #     "args" = "<C-u>";
      #     "when" = "editorTextFocus && neovim.ctrlKeysNormal.u && neovim.init && neovim.mode != 'insert' && editorLangId not in 'neovim.editorLangIdExclusions'";
      #   }
      #   {
      #     "key" = "ctrl+d";
      #     "command" = "vscode-neovim.send";
      #     "args" = "<C-d>";
      #     "when" = "editorTextFocus && neovim.ctrlKeysNormal.d && neovim.init && neovim.mode != 'insert' && editorLangId not in 'neovim.editorLangIdExclusions'";
      #   }
      # ];
      #
      userSettings = {
        "extensions.experimental.affinity" = {
          "vscodevim.vim" = 1;
        };

        "editor.fontFamily" = "FiraMono Nerd Font Mono";
        "workbench.colorTheme" = "Catppuccin Mocha";
        "editor.bracketPairColorization.enabled" = true;

        "github.copilot.selectedCompletionModel" = "gpt-4o-copilot";
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.chat.codeGeneration.useInstructionFiles" = true;

        "chat.agent.enabled" = true;
        "chat.agent.maxRequests" = 30;

        "mcp" = {
          "servers" = {
            # "github" = {
            #   "type" = "stdio";
            #   "command" = "${github-mcp-wrapped}/bin/github-mcp-wrapped";
            #   "args" = [ "stdio" ];
            # };
            "sentry" = {
              "type" = "stdio";
              "command" = "${pkgs.nodejs}/bin/npx";
              "args" = [ "@sentry/mcp-server@latest" ];
              "env" = {
                SENTRY_AUTH_TOKEN = "";
                SENTRY_HOST = "sentry.io" ;
              };
            };
            # "mcp-atlassian" = {
            #   "command" = "docker";
            #   "args" = [
            #     "run"
            #     "-i"
            #     "--rm"
            #     "-e"
            #     "JIRA_URL"
            #     "-e"
            #     "JIRA_USERNAME"
            #     "-e"
            #     "JIRA_API_TOKEN"
            #     "ghcr.io/sooperset/mcp-atlassian:latest"
            #   ];
            #   env = {
            #     JIRA_URL = "";
            #     JIRA_USERNAME = "";
            #     JIR_API_TOKEN = "";
            #   };
            # };
          };
        };

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
            "commands" = ["<C-w>" "j"];
          }
          {
            "before" = ["<C-k>"];
            "commands" = ["<C-w>" "k"];
          }
          {
            "before" = ["<C-h>"];
            "commands" = ["<C-w>" "h"];
          }
          {
            "before" = ["<C-l>"];
            "commands" = ["<C-w>" "l"];
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
      };
    };
  };
}
