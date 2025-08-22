{
  config,
  pkgs,
  lib,
  ...
}:
let
  # packageSettings = if pkgs.stdenv.isDarwin then { package = pkgs.firefox-bin; } else null;
in
{
  programs.firefox = {
    enable = true;
    # package = pkgs.firefox-bin;
    # package = pkgs.librewolf;

    # package = packageSettings;

    profiles.${config.home.username} = {
      id = 0;

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
        engines = {
          "bing".metaData.hidden = true;
          "ebay".metaData.hidden = true;
          "google".metaData.hidden = true;
          "wikipedia".hidden = true;
        };
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
            url = "https://www.google.com.au/search?q=%s";
          }
          {
            name = "Github Code Search";
            keyword = "cs";
            url = "https://github.com/search?type=code&q=%s";
          }
          {
            name = "Github Nix Code Search";
            keyword = "ncs";
            url = "https://github.com/search?type=code&q=language%3Anix+%s";
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
            name = "Nix Home Manager Options Search";
            keyword = "hm";
            url = "https://home-manager-options.extranix.com/?query=%s";
          }

          {
            name = "OSRSWiki";
            keyword = "osrs";
            url = "https://oldschool.runescape.wiki/?search=%s&title=Special%3ASearch&fulltext=Search";
          }

          {
            name = "nib Jira Search";
            keyword = "j";
            url = "https://nibgroup.atlassian.net/issues/?jql=text~%22%s%22%20or%20description%20~%20%22%s%22%20or%20summary%20~%20%22%s%22";
          }
          {
            name = "nib Confluence Search";
            keyword = "c";
            url = "https://nibgroup.atlassian.net/wiki/search/?text=%s";
          }
          {
            name = "nib Github Search";
            keyword = "ngh";
            url = "https://github.com/nib-group?q=%s&type=&language=";
          }
          {
            name = "nib Buildkite Search";
            keyword = "bk";
            url = "https://buildkite.com/nib-health-funds-ltd?filter=%s";
          }
        ];
      };
      settings = {
        "browser.quitShortcut.disabled" = true;
      };
    };
    # TODO: Bookmarks
    # TODO: Extensions
    # TODO: Profile
  };
  # // packageSettings;
}
