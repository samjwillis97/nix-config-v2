{
  config,
  # super,
  # pkgs,
  flake,
  # system,
  ...
}:
let
  helpers = config.lib.nixvim;

  borderStyle = "rounded";
  treeWidth = 35;
in
{
  imports = [
    flake.inputs.nixvim.homeManagerModules.nixvim
  ];
  programs.nixvim = {
    enable = true;

    colorschemes = {
      dracula-nvim = {
        autoLoad = true;
        enable = true;
      };
    };

    opts = {
      number = true;
      relativenumber = true;

      smartindent = true;
      autoindent = true;
    };

    keymaps = [
      {
        key = "jk";
	mode = "i";
        action = "<Esc>";
      }
      {
        key = "j";
        action = "gj";
      }
      {
        key = "k";
        action = "gk";
      }
      {
        key = "<C-n>";
        action = "<CMD>NvimTreeToggle<CR>";
        options.desc = "Toggle NvimTree";
      }
      {
        key = ",n";
        action = "<CMD>NvimTreeFindFile<CR>";
        options.desc = "Go to current file in NvimTree";
      }
      {
        key = "<C-J>";
        action = "<C-W><C-J>";
        options.desc = "Move to window below";
      }
      {
        key = "<C-K>";
        action = "<C-W><C-K>";
        options.desc = "Move to window above";
      }
      {
        key = "<C-L>";
        action = "<C-W><C-L>";
        options.desc = "Move to window right";
      }
      {
        key = "<C-H>";
        action = "<C-W><C-H>";
        options.desc = "Move to window left";
      }
      {
        key = "<C-U>";
        action = "<C-U>zz";
      }
      {
        key = "<C-D>";
        action = "<C-D>zz";
      }
      {
        key = "<C-I>";
        action = "<C-I>zz";
      }
      {
        key = "<C-O>";
        action = "<C-O>zz";
      }
      {
        key = "n";
        action = "nzz";
      }
      {
        key = "N";
        action = "Nzz";
      }
      {
        key = "GG";
        action = "GGzz";
      }
    ];

    plugins = {
      transparent = {
        enable = true;
      };

      nui = {
        enable = true;
      };

      web-devicons = {
        enable = true;
      };

      nvim-tree = {
        enable = true;

        view = {
          width = 35;
          float = {
            enable = true;
            openWinConfig = helpers.mkRaw ''
              function()
                local screen_w = vim.opt.columns:get()
                local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                local window_w = screen_w * 0.${toString (treeWidth)}
                local window_h = screen_h * 0.8
                local window_w_int = math.floor(window_w)
                local window_h_int = math.floor(window_h)
                local center_x = (screen_w - window_w) / 2
                local center_y = ((vim.opt.lines:get() - window_h) / 2)
                                 - vim.opt.cmdheight:get()
                return {
                  border = "rounded",
                  relative = "editor",
                  row = center_y,
                  col = center_x,
                  width = window_w_int,
                  height = window_h_int,
                }
              end,
            '';

          };
        };

        actions = {
          windowPicker = {
            enable = true;
            chars = "JDKSLA";
          };
        };
      };

      treesitter = {
      	enable = true;

	folding = true;

	nixvimInjections = true;
	nixGrammars = true;

	settings = {
	  highlight.enable = true;
	  indent.enable = true;
	};
      };

      treesitter-context = {
        enable = true;
	settings = {
          line_numbers = true;
          max_lines = 10;
          multiline_threshold = 5;
	};
      };

      # neo-tree = {
      #   enable = true;
      #
      #   popupBorderStyle = "rounded";
      #

      #   # window = {
      #   #   mappings = {
      #   #   };
      #   # };
      #
      # };
    };
  };
  # home.packages = [ flake.inputs.nixvim.packages.${system}.default ];
}
