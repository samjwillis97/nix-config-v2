{
  config,
  pkgs,
  lib,
  ...
}:
let
  packageSettings = lib.optionalAttrs pkgs.stdenv.isDarwin { package = pkgs.firefox-bin; };
in
{
  programs.firefox = {
    enable = true;

    profiles.${config.home.username} = {
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        decentraleyes
        onepassword-password-manager
        multi-account-containers
        ublock-origin
        temporary-containers
        i-dont-care-about-cookies
        cookie-autodelete
        terms-of-service-didnt-read
        sponsorblock
        okta-browser-plugin
      ];

      search = {
        force = true;
        default = "ddg";
        order = [ "ddg" ];
      };
      bookmarks = {
        force = true;

        settings = [
          {
            name = "Duck Duck Go";
            keyword = "d";
            url = "https://duckduckgo.com/?q=%s";
          }
          {
            name = "Google Search";
            keyword = "g";
            url = "https://www.google.com/search?q=%s";
          }
          {
            name = "Google Search AU";
            keyword = "ga";
            url = "https://www.google.com.au/search?q=%s";
          }
          {
            name = "Github Code Search";
            keyword = "cs";
            url = "https://cs.github.com/?scopeName=All+repos&scope=&q=%s";
          }
          {
            name = "Nix Pkg Search";
            keyword = "np";
            url = "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&query=%s";
          }
          {
            name = "Nix Options Search";
            keyword = "no";
            url = "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&query=%s";
          }
          {
            name = "OSRSWiki";
            keyword = "osrs";
            url = "https://oldschool.runescape.wiki/?search=%s&title=Special%3ASearch&fulltext=Search";
          }
          # TODO: Jira/Confluence/Bitbucket, HN, OZb, Twitter, Github, AWARE
        ];
      };
      settings = {
        "browser.quitShortcut.disabled" = true;
      };
    };
    # TODO: Bookmarks
    # TODO: Extensions
    # TODO: Profile
  } // packageSettings;
}
