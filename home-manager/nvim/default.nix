{ config, lib, pkgs, ... }:
{
    programs.neovim = {
        # TODO: Configure
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        plugins = with pkgs.vimPlugins; [
        ## Must Haves
            plenary-nvim
            popup-nvim
            telescope-nvim
            telescope-fzf-native-nvim
            nvim-treesitter
            nvim-treesitter-context
            # DO NOT REMOVE OUTER BRACKETS
            (nvim-treesitter.withPlugins (p: [
                p.c
                p.java
                p.json
                p.jsonc
                p.yaml
                p.toml
                p.lua
                p.go
                p.typescript
                p.javascript
                p.python
                p.rust
                p.c_sharp
                p.svelte
                p.vue
                p.css
                p.html
                p.nix
            ]))

        ## QoL
            indent-blankline-nvim
            nvim-lastplace
            nvim-autopairs
            gitsigns-nvim

        ## Must Haves from VIM
            vim-commentary
            vim-surround
            vim-fugitive
            vim-tmux-navigator

        ## Formatter
            formatter-nvim

        ## ColorSchemes
            catppuccin-nvim

        ## Icons
            nvim-web-devicons
        
        ## Colorizer
            nvim-colorizer-lua

        ## Statusline
            lualine-nvim

        ## File Navigation
            nvim-tree-lua

        ## Primeagen Harpoon
            harpoon

        ## Language Server Protocol
            nvim-lspconfig
            nvim-cmp
            cmp-nvim-lsp
            cmp-buffer
            cmp-path
            cmp-cmdline
            lspkind-nvim

        ## VSnip
            vim-vsnip
            cmp-vsnip

        ## Outline
            symbols-outline-nvim

        ## Debug Adapter Protocol
            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text

        ## Nice Startup Screen :)
            pkgs.vimExtraPlugins.startup-nvim
        ];

        extraPackages = with pkgs; [
        ## Base Reqs
            gcc
            clang
            zig

        ## Languages
            nodejs
            go
            rustc
            python311Full
            dotnet-sdk_7
            dotnet-runtime_7

        ## Formatters
            gofumpt
            black
            nodePackages.prettier
            stylua
            rustfmt

        # Language Servers
            nodePackages.pyright
            nodePackages.typescript-language-server
            nodePackages.eslint
            gopls
            golangci-lint
            nodePackages.svelte-language-server
            # angularls
            omnisharp-roslyn
            nodePackages.bash-language-server
            nodePackages.vscode-langservers-extracted
            nodePackages.vscode-json-languageserver
            nodePackages.yaml-language-server
            nodePackages.vscode-css-languageserver-bin
            rnix-lsp
            rust-analyzer

        # Telescope tools
            tree-sitter
            ripgrep
            fd
        ];
    };

    xdg.configFile.nvim = {
        source = ./config;
        recursive = true;
    };
}
