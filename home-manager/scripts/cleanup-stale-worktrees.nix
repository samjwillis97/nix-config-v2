{ pkgs, ... }:
let
  # Interactively clean up STALE git worktrees under an owner directory.
  # Depends on the workspace `rm-tree` tool (see ../cli/rmtree.nix) plus git
  # and coreutils, all of which are provided on PATH by this home-manager
  # configuration. The script body is kept verbatim in the sibling .sh file
  # so it stays identical to the tested version (it relies on `set -uo
  # pipefail` semantics, deliberately without `errexit`).
  cleanup-stale-worktrees = pkgs.writeShellScriptBin "cleanup-stale-worktrees" (
    builtins.readFile ./cleanup-stale-worktrees.sh
  );
in
{
  home.packages = [ cleanup-stale-worktrees ];
}
