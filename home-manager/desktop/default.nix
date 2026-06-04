# TODO:
#   - Flameshot
#   - OBS
#   - Solaar
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../media
    ../social
    ../firefox
    ../alacritty
    ../wezterm
    ../ghostty
    ../theme
  ];

  home.packages = with pkgs; [
    arandr
    gammastep
    pavucontrol
    pamixer
    udiskie
    xclip
    chromium
    filezilla
    thunar
    thunar-archive-plugin
    obs-studio
    peek
    btop
    _1password-gui
  ];

  services.udiskie = {
    enable = true;
    tray = "always";
  };

  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Browser
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";

        # Terminal
        "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
        "application/x-terminal-emulator" = "com.mitchellh.ghostty.desktop";

        # File manager
        "inode/directory" = "thunar.desktop";

        # Media
        "audio/mpeg" = "vlc.desktop";
        "audio/ogg" = "vlc.desktop";
        "audio/flac" = "vlc.desktop";
        "audio/x-wav" = "vlc.desktop";
        "video/mp4" = "vlc.desktop";
        "video/x-matroska" = "vlc.desktop";
        "video/webm" = "vlc.desktop";
        "video/avi" = "vlc.desktop";
        "video/quicktime" = "vlc.desktop";

        # Code / text
        "text/plain" = "code.desktop";
        "text/x-shellscript" = "code.desktop";
        "text/x-python" = "code.desktop";
        "text/x-go" = "code.desktop";
        "text/x-csharp" = "code.desktop";
        "text/x-javascript" = "code.desktop";
        "text/x-typescript" = "code.desktop";
        "text/x-lua" = "code.desktop";
        "text/x-rust" = "code.desktop";
        "application/json" = "code.desktop";
        "application/x-yaml" = "code.desktop";
        "application/toml" = "code.desktop";
        "application/xml" = "code.desktop";

        # Protocol handlers
        "x-scheme-handler/slack" = "slack.desktop";
        "x-scheme-handler/discord" = "vesktop.desktop";
        "x-scheme-handler/steam" = "steam.desktop";
        "x-scheme-handler/steamlink" = "steam.desktop";
        "x-scheme-handler/onepassword" = "1password.desktop";
        "x-scheme-handler/ftp" = "filezilla.desktop";
        "x-scheme-handler/ftps" = "filezilla.desktop";
        "x-scheme-handler/sftp" = "filezilla.desktop";
        "x-scheme-handler/plex" = "plex.desktop";
      };
    };
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
