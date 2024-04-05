{ config, pkgs, ... }:
{
  programs.qutebrowser = {
    enable = true;
    # searchEngines = {
    #   "d" = "https://duckduckgo.com/?q=%s";
    #   "g" = "https://www.google.com/search?q=%s";
    #   "ga" = "https://www.google.com.au/search?q=%s";
    #   "cs" = "https://cs.github.com/?scopeName=All+repos&scope=&q=%s";
    #   "np" =
    #     "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&query=%s";
    #   "no" =
    #     "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&query=%s";
    #   "ns" =
    #     "https://search.nix.gsc.io/?q=%s&i=nope&files=&excludeFiles=&repos=";
    #   "j" = "https://ampcontrol.atlassian.net/issues/?jql=project%20%3D%20%s";
    #   "c" = "https://ampcontrol.atlassian.net/wiki/search?text=$s";
    #   "b" =
    #     "https://bitbucket.org/search?account=%7Be6dcdc2b-7ec9-42aa-85c0-062c35547eb0%7D&q=%s";
    #   "osrs" =
    #     "https://oldschool.runescape.wiki/?search=%s&title=Special%3ASearch&fulltext=Search";
    # };
  };
}
