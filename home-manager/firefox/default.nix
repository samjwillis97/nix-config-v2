{ config, pkgs, ... }:
{
  programs.firefox = {
    enable = true;

    profiles.${config.home.username} = {
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        decentraleyes
        onepassword-password-manager
        multi-account-containers
        ublock-origin
        temporary-containers
        i-dont-care-about-cookies
        cookie-autodelete
        terms-of-service-didnt-read
        sponsorblock
      ];

      search = {
        force = true;
        default = "DuckDuckGo";
        order = [ "DuckDuckGo" ];
      };
      bookmarks = {
        "Duck Duck Go" = {
          keyword = "d";
          url = "https://duckduckgo.com/?q=%s";
        };
        "Google Search" = {
          keyword = "g";
          url = "https://www.google.com/search?q=%s";
        };
        "Google Search AU" = {
          keyword = "ga";
          url = "https://www.google.com.au/search?q=%s";
        };
        "Github Code Search" = {
          keyword = "cs";
          url = "https://cs.github.com/?scopeName=All+repos&scope=&q=%s";
        };
        "Nix Pkg Search" = {
          keyword = "np";
          url = "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&query=%s";
        };
        "Nix Options Search" = {
          keyword = "no";
          url = "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&query=%s";
        };
        "Nix Uber Search" = {
          keyword = "ns";
          url = "https://search.nix.gsc.io/?q=%s&i=nope&files=&excludeFiles=&repos=";
        };
        "Ampcontrol Jira Search" = {
          keyword = "j";
          url = "https://ampcontrol.atlassian.net/issues/?jql=project%20%3D%20%s";
        };
        "Ampcontrol Confluence Search" = {
          keyword = "c";
          url = "https://ampcontrol.atlassian.net/wiki/search?text=$s";
        };
        "Ampcontrol Bitbucket Search" = {
          keyword = "b";
          url = "https://bitbucket.org/search?account=%7Be6dcdc2b-7ec9-42aa-85c0-062c35547eb0%7D&q=%s";
        };
        OSRSWiki = {
          keyword = "osrs";
          url = "https://oldschool.runescape.wiki/?search=%s&title=Special%3ASearch&fulltext=Search";
        };
        # TODO: Jira/Confluence/Bitbucket, HN, OZb, Twitter, Github, AWARE
      };
      settings = {
        "browser.quitShortcut.disabled" = true;
      };
    };
    # TODO: Bookmarks
    # TODO: Extensions
    # TODO: Profile
  };
}
