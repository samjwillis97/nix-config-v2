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
        catppuccin.catppuccin-vsc-icons

        # Javascript/Typescript
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        yoavbls.pretty-ts-errors

        # Testing
        pkgs.vscode-marketplace.ms-playwright.playwright

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
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "amp";
          publisher = "sourcegraph";
          version = "0.0.1748419909";
          sha256 = "NIKtEC/EFbuzdtKIzo7L8mYukD3gJLyA+EItEjIca5o=";
        }
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

        # Make sure navigating in and out of sidebars works
        {
          key = "ctrl+h";
          command = "workbench.action.navigateLeft";
          when = "sideBarFocus || workbench.panel.chat.view.copilot.active";
        }
        {
          key = "ctrl+l";
          command = "workbench.action.navigateRight";
          when = "sideBarFocus || workbench.panel.chat.view.copilot.active";
        }

        # Toggle left (file) side bar
        {
          key = "ctrl+n";
          command = "workbench.action.toggleSidebarVisibility";
          when = "editorTextFocus || sideBarFocus";
        }
        {
          key = "escape";
          command = "workbench.action.toggleSidebarVisibility";
          when = "sideBarFocus";
        }

        # Make sure that ctrl+n and ctrl+p work in the quickSelect thing
        {
            key = "ctrl+n";
            command = "workbench.action.quickOpenSelectNext";
            when = "!editorFocus && !sideBarFocus";
        }
        {
            key = "ctrl+p";
            command = "workbench.action.quickOpenSelectPrevious";
            when = "!editorFocus && !sideBarFocus";
        }

        # Close Copilot Chat
        {
          key = "escape";
          command = "workbench.action.toggleAuxiliaryBar";
          when = "auxiliaryBarFocus";
        }
      ];

      userSettings = {
        "extensions.experimental.affinity" = {
          "vscodevim.vim" = 1;
        };

        # Styling
        "editor.fontFamily" = "FiraMono Nerd Font Mono";
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";
        "editor.bracketPairColorization.enabled" = true;
        "workbench.editor.showTabs" = false;
        "workbench.editor.enablePreview" = false;
        "workbench.editor.enablePreviewFromQuickOpen" = false;
        "workbench.startupEditor" = "newUntitledFile";
        "editor.minimap.enabled" = false;
        "editor.lineNumbers" = "relative";
        "editor.scrollBeyondLastLine" = false;
        "editor.cursorSurroundingLines" = 8;
        "editor.smoothScrolling" = true;
        "editor.guides.bracketPairs" = true;
        "editor.cursorSmoothCaretAnimation" = true;

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
          "inputs" = [
            {
              description = "Jira URL";
              type = "promptString";
              id = "jira-url";
              password = false;
            }
            {
              description = "Jira Username";
              type = "promptString";
              id = "jira-username";
              password = false;
            }
            {
              description = "Jira API Token";
              type = "promptString";
              id = "jira-api-token";
              password = true;
            }
            {
              description = "Confluence URL";
              type = "promptString";
              id = "confluence-url";
              password = false;
            }
            {
              description = "Confluence Username";
              type = "promptString";
              id = "confluence-username";
              password = false;
            }
            {
              description = "Confluence API Token";
              type = "promptString";
              id = "confluence-api-token";
              password = true;
            }
          ];

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
            atlassian-mcp = {
              command = "docker";
              args = [
                "run"
                "-i"
                "--rm"
                "-e" "JIRA_URL"
                "-e" "JIRA_USERNAME"
                "-e" "JIRA_API_TOKEN"
                "-e" "CONFLUENCE_URL"
                "-e" "CONFLUENCE_USERNAME"
                "-e" "CONFLUENCE_API_TOKEN"
                "ghcr.io/sooperset/mcp-atlassian:latest"
              ];
              env =  {
                JIRA_URL = "\${input:jira-url}";
                JIRA_USERNAME = "\${input:jira-username}";
                JIRA_API_TOKEN = "\${input:jira-api-token}";
                CONFLUENCE_URL = "\${input:confluence-url}";
                CONFLUENCE_USERNAME = "\${input:confluence-username}";
                CONFLUENCE_API_TOKEN = "\${input:confluence-api-token}";
              };
            };
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

        "vim.foldfix" = true;
        "vim.easymotion" = true;
        "vim.surround" = true;
        "vim.incsearch" = true;
        "vim.useSystemClipboard" = true;
        "vim.useCtrlKeys" = true;
        "vim.hlsearch" = true;
        "vim.startup.firstline" = false;
        "vim.insertModeKeyBindings" = [
          {
            "before" = ["j" "k"];
            "after" = ["<Esc>"];
          }
        ];
        "vim.normalModeKeyBindingsNonRecursive" = [
          # {
          #   "before" = ["<C-n>"];
          #   "commands" = ["workbench.action.toggleSidebarVisibility"];
          # }
          {
            "before" = ["," "n"];
            "commands" = ["revealInExplorer"];
          }
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
            "before" = ["<leader>" "g" "g"];
            "commands" = ["workbench.view.scm"];
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
            "before" = ["<leader>" "a" "a"];
            "commands" = ["workbench.panel.chat"];
          }
          {
            "before" = ["<leader>" "a" "e"];
            "commands" = ["inlineChat.start"];
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
          "<C-d>" = true;
          "<C-u>" = true;

          "<C-n>" = true;

          "<C-f>" = false;
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
