{ pkgs, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    userName = "samjwillis97";
    userEmail = "sam@williscloud.org";

    extraConfig = {
      merge = { tool = "fugitive"; };
      push = { autoSetupRemote = true; };
      safe = { directory = "*"; };
      # mergetool = {
      # fugitive = """
      # nvim -f -c \"Gvdiffsplit!\" \"$MERGED\"
      # """;
      # };
    };

    difftastic = {
      enable = true;
      background = "dark";
    };

    ignores = [
      "*~"
      "*.swp"
      ".idea/*"
      ".vscode/*"
      ".history/"
      "node_modules/"
      ".DS_Store"
      "venv/"
    ];

    aliases = {
      lg1 = "lg1-specific --all";
      lg2 = "lg2-specific --all";
      lg3 = "lg3-specific --all";
      lg1-specific =
        "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
      lg2-specific =
        "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      lg3-specific =
        "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
      s = "status";
      sp = "switch $1 && !git pull";
      tug = "!git fetch && git pull";
      blamer =
        ''!f() { git blame "$@" | sed 's/Sam Willis/Jeremy Carter/g'; }; f'';
    };
  };
}
