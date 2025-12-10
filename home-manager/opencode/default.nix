{
  config,
  pkgs,
  lib,
  ...
}:
let
  github-mcp-wrapped = pkgs.writeShellScriptBin "github-mcp-wrapped" ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.age.secrets.gh_pat.path})
    ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
  '';

  getFilesInDir = (
    dir: ext:
    lib.mapAttrsToList (name: value: dir + ("/" + name)) (
      lib.filterAttrs (key: value: value == "regular" && lib.hasSuffix ext key) (builtins.readDir dir)
    )
  );

  node = pkgs.nodejs_24;

  plugins =
    getFilesInDir ./plugins ".js"
    ++ (if (pkgs.stdenv.isDarwin) then getFilesInDir ./plugins/darwin ".js" else [ ]);

  marpThemes = getFilesInDir ./themes/marp ".css";
in
{
  imports = [
    ../../hm-modules/opencode.nix
  ];

  # Install Marp themes to user config directory
  home.activation.opencode-marp-themes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.config/opencode/themes/marp
    rm -f $HOME/.config/opencode/themes/marp/*
    ${lib.concatMapStringsSep "\n" (theme: ''
      theme_src=${theme}
      theme_bn=$(basename "$theme_src")
      theme_name=''${theme_bn#*-}
      cp "$theme_src" "$HOME/.config/opencode/themes/marp/$theme_name"
    '') marpThemes}
  '';

  # For some reason with these MCP's you need node globally :(
  home.packages = with pkgs; [
    node
    marp-cli
    terminal-notifier
  ];

  modules.opencode = {
    enable = true;
    plugins = plugins;
    commands = getFilesInDir ./commands ".md";
    agents = getFilesInDir ./agents ".md";
    prompts = getFilesInDir ./prompts ".txt";
    settings = {
      share = "disabled";
      instructions = [
        ".instructions.md"
        "CONTRIBUTING.md"
        ".cursor/rules/*.md"
        ".github/*.md"
      ];
      keybinds = {
        messages_half_page_up = "ctrl+u";
        messages_half_page_down = "ctrl+d";
      };
      permission = {
        bash = {
          "*" = "ask";
          "git status" = "allow";
          "git diff" = "allow";
          "git add" = "allow";
          "git commit" = "allow";
          "git checkout" = "allow";
          "git stash" = "allow";
          "ls" = "allow";
          "pwd" = "allow";
          "mkdir" = "allow";
          "npm" = "allow";
          "npm run" = "allow";
          "bun run" = "allow";
          "pnpm run" = "allow";
        };
      };
      agent = {
        code-researcher = {
          mode = "subagent";
          prompt = "{file:./prompts/code-researcher.txt}";
          description = "Always use this agent when asked to research a codebase.";
          permission = {
            edit = "deny";
            bash = {
              "*" = "ask";
              "f -p" = "allow";
              "f -L" = "allow";
              "grep" = "allow";
              "find" = "allow";
              "cd" = "allow";
              "head" = "allow";
              "tail" = "allow";
              "wc" = "allow";
              "rg" = "allow";
              "sort" = "allow";
            };
            webfetch = "deny";
          };
          tools = {
            "*" = false;
            bash = true;
            read = true;
            grep = true;
            glob = true;
            list = true;
          };
        };
        # github-researcher = {
        #   mode = "subagent";
        #   prompt = "{file:./prompts/github-researcher.txt}";
        #   description = "Use this agent to research code on GitHub, finding relevant repositories, files, and code snippets based on the user's query. Provide links to the most relevant results.";
        #   permission = {
        #     edit = "deny";
        #     bash = "deny";
        #     webfetch = "deny";
        #   };
        #   tools = {
        #     "*" = false;
        #     github_search_repositories = true;
        #     github_search_code = true;
        #     github_get_file_contents = true;
        #     github_list_branches = true;
        #     github_list_commits = true;
        #     github_get_commit = true;
        #   };
        # };
        jira-writer = {
          mode = "primary";
          prompt = "{file:./prompts/jira-writer.txt}";
          permission = {
            edit = "deny";
            bash = "deny";
            webfetch = "deny";
          };
          tools = {
            "atlassian_*" = false;
            atlassian_getJiraIssue = true;
            atlassian_getJiraIssueRemoteIssueLinks = true;
            atlassian_getTransitionsForJiraIssue = true;
            atlassian_getVisibleJiraProjects = true;
            atlassian_getJiraProjectIssueTypesMetadata = true;
            atlassian_getJiraIssueTypeMetaWithFields = true;
            atlassian_searchJiraIssuesUsingJql = true;
            atlassian_lookupJiraAccountId = true;
            atlassian_createJiraIssue = true;
            atlassian_editJiraIssue = true;
            atlassian_addCommentToJiraIssue = true;
            atlassian_transitionJiraIssue = true;
          };
        };
        jira-planner = {
          mode = "primary";
          prompt = "{file:./prompts/jira-planner.txt}";
          permission = {
            edit = "allow";
            bash = "deny";
            webfetch = "deny";
          };
          tools = {
            write = true;
            edit = true;
            "atlassian_*" = false;
            atlassian_getJiraIssue = true;
            atlassian_getJiraIssueRemoteIssueLinks = true;
            atlassian_getTransitionsForJiraIssue = true;
            atlassian_getVisibleJiraProjects = true;
            atlassian_getJiraProjectIssueTypesMetadata = true;
            atlassian_getJiraIssueTypeMetaWithFields = true;
            atlassian_searchJiraIssuesUsingJql = true;
            atlassian_lookupJiraAccountId = true;
            atlassian_getConfluencePage = true;
          };
        };
        jira-query = {
          mode = "all";
          prompt = "{file:./prompts/jira-query.txt}";
          description = "Use this agent to query and search Jira issues. Provides quick access to issue details, search using JQL or natural language, and retrieve issue information.";
          permission = {
            edit = "allow";
            bash = "deny";
            webfetch = "deny";
          };
          tools = {
            write = true;
            read = true;
            "atlassian_*" = false;
            atlassian_getAccessibleAtlassianResources = true;
            atlassian_getJiraIssue = true;
            atlassian_searchJiraIssuesUsingJql = true;
            atlassian_search = true;
            atlassian_fetch = true;
            atlassian_getJiraIssueRemoteIssueLinks = true;
            atlassian_getTransitionsForJiraIssue = true;
            atlassian_lookupJiraAccountId = true;
            atlassian_getConfluenceSpaces = true;
            atlassian_getConfluencePage = true;
            atlassian_getPagesInConfluenceSpace = true;
            atlassian_getConfluencePageDescendants = true;
            atlassian_searchConfluenceUsingCql = true;
          };
        };
        slides-generator = {
          mode = "primary";
          prompt = "{file:./prompts/slides-generator.txt}";
          description = "Generate presentation slides from markdown documents";
          permission = {
            edit = "allow";
            bash = {
              "*" = "ask";
              "cd" = "allow";
              "marp" = "allow";
              "test -w" = "allow";
              "test -d" = "allow";
              "mkdir -p" = "allow";
              "ls" = "allow";
              "rm" = "ask";
              "which" = "allow";
              "grep" = "allow";
              "mv" = "allow";
              "rm -rf marp-preview" = "allow";
              "rm -rf marp-preview/*" = "allow";
            };
            webfetch = "deny";
          };
          tools = {
            bash = true;
            read = true;
            write = true;
            edit = true;
            glob = true;
            list = true;
            task = true;
          };
        };
        slide-reviewer = {
          mode = "subagent";
          prompt = "{file:./prompts/slide-reviewer.txt}";
          description = "Review individual presentation slides for visual quality and readability";
          permission = {
            edit = "deny";
            bash = "deny";
            webfetch = "deny";
          };
          tools = {
            "*" = false;
            read = true;
          };
        };
      };
      mcp = {
        atlassian = {
          type = "local";
          command = [
            "${node}/bin/npx"
            "-y"
            "mcp-remote"
            "https://mcp.atlassian.com/v1/sse"
          ];
          enabled = true;
        };
        sentry = {
          type = "local";
          command = [
            "${node}/bin/npx"
            "-y"
            "mcp-remote"
            "https://mcp.sentry.dev/sse"
          ];
          enabled = false; # Bit annoying
        };
        github = {
          type = "local";
          command = [
            "${github-mcp-wrapped}/bin/github-mcp-wrapped"
            "stdio"
          ];
          enabled = true;
        };
        playwright =
          let
            browsers =
              (builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json")).browsers;
            chromium-rev = (builtins.head (builtins.filter (x: x.name == "chromium") browsers)).revision;
            exePath = "${pkgs.playwright.browsers}/chromium-${chromium-rev}/chrome-mac/Chromium.app/Contents/MacOS/Chromium";
          in
          {
            type = "local";
            command = [
              (pkgs.lib.getExe pkgs.playwright-mcp)
              "--executable-path=${exePath}"
              "--user-data-dir=$USER_DATA_DIR"
            ];
            environment = {
              PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright.browsers}";
              PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
              PLAYWRIGHT_NODEJS_PATH = "${node}/bin/node";
              USER_DATA_DIR = "$TMPDIR/chrome-mcp";
            };
            enabled = true;
          };
        httpcraft = {
          type = "local";
          command = [
            "${pkgs.httpcraft-mcp}/bin/httpcraft-mcp"
          ];
          enabled = true;
        };
      };
    };
  };
}
