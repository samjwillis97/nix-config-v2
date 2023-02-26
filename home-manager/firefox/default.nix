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
                terms-of-service-didnt-read
                sponsorblock
            ];

            search = {
                default = "DuckDuckGo";
                order = [ "DuckDuckGo" ];
            };
            bookmarks = {
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
