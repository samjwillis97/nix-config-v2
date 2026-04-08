# home-manager/ai-coding/default.nix
{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
let
  getFilesInDir =
    dir: ext:
    lib.mapAttrsToList (name: _: dir + ("/" + name)) (
      lib.filterAttrs (key: value: value == "regular" && lib.hasSuffix ext key) (builtins.readDir dir)
    );

  getDirsInDir =
    dir:
    lib.mapAttrsToList (name: _: dir + ("/" + name)) (
      lib.filterAttrs (_: value: value == "directory") (builtins.readDir dir)
    );

  plugins = [
    "${pkgs.opencode-notifier}/dist/index.js"
    "${pkgs.tmux-session-cache-plugin}/dist/index.js"
  ]
  ++ getFilesInDir ./plugins ".js"
  ++ (if pkgs.stdenv.isDarwin then getFilesInDir ./plugins/darwin ".js" else [ ]);

  workEnabled = config.modules.darwin.work;
in
{
  imports = [
    ../../hm-modules/ai-coding
  ];

  home.packages = with pkgs; [
    gh
    # acli
    # jira-cli-go
    llm-agents.agent-browser
  ];

  home.file.".config/opencode/opencode-notifier.json".text = builtins.toJSON {
    sound = true;
    notification = true;
    timeout = 5;
    showProjectName = true;
    showSessionTitle = true;
    showIcon = true;
    suppressWhenFocused = true;
    enableOnDesktop = false;
    notificationSystem = "osascript";
    linux.grouping = false;
  };

  modules.ai-coding = {
    enable = true;

    backends.opencode.enable = true;
    backends.opencode.sandbox.enable = true;
    backends.claude.enable = true;
    backends.claude.sandbox.enable = true;

    sandbox.extraAllowedPackages = with pkgs; [
      gh
      f
      httpcraft
      llm-agents.agent-browser
      nix
      bun
      pnpm
      rsync
      # acli
      # jira-cli-go
    ];

    sandbox.extraStateDirs = [
      "$HOME/.npm"
      "$HOME/.cache"
      "$HOME/.agent-browser"
      "$HOME/.config/httpcraft"
    ];

    # rules = ./AGENTS.md;  # Uncomment when ready

    modelAliases = {
      sonnet = {
        opencode = "anthropic/claude-sonnet-4-20250514";
      };
      opus = {
        opencode = "anthropic/claude-opus-4-20250514";
      };
      haiku = {
        opencode = "anthropic/claude-haiku-4-20250514";
      };
    };

    permissions = {
      external_directory = {
        "~/.agent-browser/**" = "allow";
        "~/code/**" = "allow";
        "~/.config/httpcraft/**" = "allow";
        "~/.config/opencode/**" = "allow";
        "~/.local/share/opencode/**" = "allow";
        "~/nix/store/**" = "allow";
      };
      edit = {
        "~/.config/httpcraft" = "deny";
      };
      bash = {
        "*" = "ask";
        "git status*" = "allow";
        "git diff*" = "allow";
        "git add*" = "allow";
        "git commit*" = "allow";
        "git checkout*" = "allow";
        "git stash*" = "allow";
        "git log*" = "allow";
        "git show*" = "allow";
        "git remote*" = "allow";
        "git rev-parse*" = "allow";
        "git branch*" = "allow";
        "git ls-tree*" = "allow";
        "ls*" = "allow";
        "pwd*" = "allow";
        "mkdir*" = "allow";
        "npm*" = "allow";
        "bun*" = "allow";
        "pnpm*" = "allow";
        "echo*" = "allow";
        "cat*" = "allow";
        "grep*" = "allow";
        "find*" = "allow";
        "fd*" = "allow";
        "rg*" = "allow";
        "wc*" = "allow";
        "jq*" = "allow";
        "sort*" = "allow";
        "head*" = "allow";
        "tail*" = "allow";
        "nix*" = "allow";
        "xargs*" = "allow";
        "true*" = "allow";
        "readlink*" = "allow";
        "f*" = "allow";
        "httpcraft*" = "allow";
        "agent-browser*" = "allow";
        "gh api*" = "allow";
        "gh api *" = "allow";
        "gh browse*" = "allow";
        "gh pr list*" = "allow";
        "gh pr view*" = "allow";
        "gh pr diff*" = "allow";
        "gh repo view*" = "allow";
        "f -L*" = "allow";
      };
    };

    mcpServers = {
      nixos = {
        type = "stdio";
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        enabled = false;
      };
      atlassian = {
        type = "stdio";
        command = "${pkgs.nodejs_24}/bin/npx";
        args = [
          "-y"
          "mcp-remote"
          "https://mcp.atlassian.com/v1/sse"
        ];
        enabled = false;
      };
      buildkite = {
        type = "http";
        url = "https://mcp.buildkite.com/mcp/readonly";
        enabled = false;
        headers = {
          X-Buildkite-Toolsets = "user,pipelines,builds,logs,tests,annotations";
        };
        oauth = { };
      };
    };

    agents = {
      reviewer = {
        description = ''
          Use this agent when the user provides (or is about to provide) a code diff, a set of changed files, a commit, pull/merge request content, or clearly requests a code review. Also invoke it proactively right after the user completes a logical unit of implementation (e.g., finishes writing a function, class, module, test, migration, API endpoint, or refactor) even if they did not explicitly ask for a review. Do NOT use it for general Q&A, architecture brainstorming, or whole-repository audits unless the user explicitly asks.

          Triggering conditions:

          - User says: "review this", "any feedback on this?", "does this look good?"

          - User pastes code that appears to be newly written or modified

          - User shows a git diff / patch / PR description / commit message

          - User finishes a feature and moves on without requesting feedback (proactive suggestion)

          - User asks: "What should I improve before merging?"

          Avoid triggering when:

          - User is still in the middle of typing (partial/incomplete code blocks)

          - User asks conceptual or design questions without code

          - User wants runtime debugging or execution results

          Examples:
            <example>
                Context: The user is creating a code-review agent that should be called after a logical chunk of code is written.
                user: "Please write a function that checks if a number is prime"
                assistant: "Here is the relevant function:\nfunction isPrime(n){ if(n < 2) return false; for(let i=2;i*i<=n;i++){ if(n % i===0) return false; } return true }"
                <commentary>
                Since the user has produced a complete logical function implementation, use the Task tool to launch the code-diff-reviewer agent to evaluate correctness, edge cases, performance, and style.
                </commentary>
                assistant: "Now let me use the code-diff-reviewer agent to review the code."
              </example>
            <example>
                Context: User is incrementally building a feature and just pasted a multi-file diff without explicitly asking for review.
                user: "Added these changes:\ncommit 123abc\n diff --git a/src/auth.js b/src/auth.js ... (diff content)"
                assistant: "I'm going to use the Task tool to launch the code-diff-reviewer agent to analyze this diff for security, correctness, and test coverage gaps."
                <commentary>
                Since the user provided a commit diff, invoke the code-diff-reviewer agent to perform a structured review.
                </commentary>
              </example>
            <example>
                Context: User explicitly asks for feedback after writing code.
                user: "Here's my refactored repository layer. Thoughts?" (code snippet follows)
                assistant: "I'll invoke the Task tool to run the code-diff-reviewer agent for a thorough refactor assessment."
                <commentary>
                User requested review; trigger code-diff-reviewer.
                </commentary>
              </example>
            <example>
                Context: User is drafting code and has only shared a partial, clearly incomplete snippet.
                user: "class CacheManager { constructor(client) { this.client = client; } async get(key) {" (trails off)
                assistant: "Let me know once the snippet is complete and I'll run the code-diff-reviewer agent."
                <commentary>
                Do not trigger yet because code is incomplete.
                </commentary>
              </example>'';
        instructions = ./agents/reviewer.md;
        permissions = {
          bash = {
            "*" = "deny";
            "echo" = "allow";
            "git status" = "allow";
            "git branch" = "allow";
            "git log *" = "allow";
            "git diff *" = "allow";
            "git commit *" = "deny";
            "git add *" = "deny";
            "git stage *" = "deny";
            "git reset *" = "deny";
            "git restore *" = "deny";
          };
        };
        tools = {
          bash = true;
          write = false;
          edit = false;
          task = false;
        };
        opencode = {
          mode = "all";
        };
      };

      httpcraft = {
        description = ''Use this agent every time the user asks you to "call", "hit", "test", or "try" an endpoint or API. This specialised agent is for making HTTP API calls with `httpcraft` which provides authentication as well variables and profiles for making complicated HTTP calls.'';
        instructions = ./agents/httpcraft.md;
        permissions = {
          edit = "deny";
          bash = "deny";
          webfetch = "ask";
        };
        tools = {
          read = true;
          grep = true;
          glob = true;
          list = true;
          "httpcraft_*" = true;
          write = false;
          edit = false;
          bash = false;
        };
        opencode = {
          mode = "subagent";
          temperature = 0.15;
          disable = false;
          additional = {
            reasoningEffort = "low";
          };
        };
      };

      architect = {
        description = "Use this agent when you need architectural guidance, system design decisions, or technical leadership perspective on complex software problems. Examples: <example>Context: The user is designing a new microservices architecture for a high-traffic e-commerce platform. user: 'I need to design the order processing system for our e-commerce platform that handles 10k orders per minute' assistant: 'I'll use the lead-architect-advisor agent to provide comprehensive architectural guidance for this high-performance system design.'</example> <example>Context: The user is facing performance issues with their current database setup. user: 'Our application is slowing down as we scale - the database queries are taking too long' assistant: 'Let me engage the lead-architect-advisor agent to analyze your performance bottlenecks and recommend architectural improvements.'</example> <example>Context: The user needs to evaluate technology choices for a new project. user: 'Should we use GraphQL or REST for our new API, and what about database choices?' assistant: 'I'll use the lead-architect-advisor agent to help evaluate these technology decisions based on your specific requirements and constraints.'</example>";
        instructions = ./agents/architect.md;
        tools = {
          bash = false;
          write = false;
          edit = false;
        };
      };

      docs = {
        description = "ALWAYS use this when writing docs";
        instructions = ./agents/docs.md;
      };

      code-researcher = {
        description = "Always use this agent when asked to research a codebase.";
        instructions = ./agents/code-researcher.md;
        permissions = {
          external_directory = {
            "~/code/**" = "allow";
            "~/nix/store/**" = "allow";
          };
          edit = "deny";
          bash = {
            "*" = "ask";
            "gh*" = "deny";
            "ls*" = "allow";
            "pwd*" = "allow";
            "grep*" = "allow";
            "find*" = "allow";
            "cd*" = "allow";
            "head*" = "allow";
            "tail*" = "allow";
            "wc*" = "allow";
            "rg*" = "allow";
            "sort*" = "allow";
            "true*" = "allow";
            "echo*" = "allow";
            "jq*" = "allow";
            "cat*" = "allow";
            "f*" = "allow";
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
        opencode = {
          mode = "subagent";
        };
      };
    };

    commands = getFilesInDir ./commands ".md";

    skills = {
      local = getDirsInDir ./skills;
      sources = [
        {
          name = "superpowers";
          src = flake.inputs.superpowers;
          exclude = [ "using-git-worktrees" ];
        }
        {
          name = "github-skills";
          src = flake.inputs.github-skills;
          include = [ "gh-cli" ];
        }
        {
          name = "agent-browser";
          src = flake.inputs.vercel-labs-agent-browser;
        }
        {
          name = "f";
          src = flake.inputs.f;
        }
        {
          name = "httpcraft";
          src = flake.inputs.httpcraft;
        }
      ];
    };

    # OpenCode-specific settings
    backends.opencode = {
      plugins = plugins;
      prompts = getFilesInDir ./prompts ".txt";
      extraSettings = {
        share = "disabled";
        plugin = [ ];
        provider = lib.mkIf workEnabled {
          amazon-bedrock = {
            options = {
              region = "ap-southeast-2";
              profile = "default";
            };
            models = {
              "anthropic-claude-sonnet-4.5" = {
                id = "{file:~/.config/opencode/bedrock/inference-profile.txt}";
              };
            };
          };
        };
        instructions = [
          ".instructions.md"
          "CONTRIBUTING.md"
          ".cursor/rules/*.md"
          ".github/*.md"
        ];
        tui = {
          scroll_acceleration.enabled = true;
        };
        keybinds = {
          messages_half_page_up = "ctrl+u";
          messages_half_page_down = "ctrl+d";
        };
      };
    };

    # Claude-specific settings (minimal for now)
    backends.claude = { };
  };
}
