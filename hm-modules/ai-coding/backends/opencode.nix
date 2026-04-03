# Stub — will be replaced in Task 3
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.modules.ai-coding.backends.opencode = {
    enable = mkEnableOption "OpenCode backend";
    extraPermissions = mkOption { type = types.attrsOf types.anything; default = { }; };
    extraSettings = mkOption { type = types.attrsOf types.anything; default = { }; };
    extraMcpServers = mkOption { type = types.attrsOf types.anything; default = { }; };
    disabledMcpServers = mkOption { type = types.listOf types.str; default = [ ]; };
    plugins = mkOption { type = types.listOf types.path; default = [ ]; };
    prompts = mkOption { type = types.listOf types.path; default = [ ]; };
  };
}
