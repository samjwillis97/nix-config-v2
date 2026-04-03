# Stub — will be replaced in Task 4
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.modules.ai-coding.backends.claude = {
    enable = mkEnableOption "Claude Code backend";
    extraPermissions = mkOption { type = types.attrsOf types.anything; default = { }; };
    extraSettings = mkOption { type = types.attrsOf types.anything; default = { }; };
    extraMcpServers = mkOption { type = types.attrsOf types.anything; default = { }; };
    disabledMcpServers = mkOption { type = types.listOf types.str; default = [ ]; };
  };
}
