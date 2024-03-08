# from: https://notes.billmill.org/blog/2024/03/How_I_use_git_worktrees.html?utm_source=pocket_saves
{ pkgs, ... }:
let
  rm-tree = pkgs.writeShellApplication {
    name = "rm-tree";
    runtimeInputs = with pkgs; [ gum ];
    text = ''
      MAIN_BRANCH=''${MAIN_BRANCH:-main}
      VERBOSE=

      function usage {
        cat <<"EOF"
rmtree [-vh] [-m <MAIN_BRANCH>] <worktree directory to delete>

remove a worktree from a git repository. Assumes you're in a directory with
folders representing both a worktree and the main branch of your project.

FLAGS:

    -h: print this help
    -v: verbose mode
    -m: MAIN_BRANCH defaults to `main`, and will check for `master` if that
        doesn't exist. Use this flag to pass a different main branch name.
        You may also set the MAIN_BRANCH environment variable to set the
        main branch name.

EOF
        exit 1
      }

      function die {
        # if verbose was set, and we're exiting early, make sure that we set +x to
        # stop the shell echoing verbosely
        if [ -n "$VERBOSE" ]; then
            set +x
        fi

        gum log --structured --level error "$1"
        exit 1
      }

      function warn {
        gum log --structured --level warn "$1"
      }

      function err {
        gum log --structured --level error "$1"
      }

      # rmtree <dir> will remove a worktree's directory, then prune the worktree list
      # and delete the branch
      function rmtree {
        if [ -n "$VERBOSE" ]; then
          set -x
        fi

        # verify that the first argument is a directory that exists, that we want
        # to remove
        if [ -z "$1" ]; then
          die "You must provide a directory name that is a worktree to remove"
        fi

        # for each argument, delete the directory and remove the worktree
        while [ -n "$1" ]; do
          if [ ! -d "$1" ]; then
            err "Unable to find directory $1, skipping"
            shift
            continue
          fi

          warn "removing $1"

          # verify that the main branch exists
          if [ ! -d "$MAIN_BRANCH" ]; then
            # for legacy reasons, check "master" as a possibility for the main
            # branch
            if [ -d "master" ] ; then
              MAIN_BRANCH=master
            else
              die "Could not find main branch directory <$MAIN_BRANCH>"
            fi
          fi

          branch_name=$(cd "$1" && git rev-parse --abbrev-ref HEAD)
          rm -rf "$1"
          (cd "$MAIN_BRANCH" && git worktree prune && git branch -D "$branch_name")

          shift
        done
      }

      while true; do
        case $1 in
          help | -h | --help)
            usage "$@"
            ;;
          -v | --verbose)
            VERBOSE=true
            shift
            ;;
          -m | --main-branch)
            MAIN_BRANCH=$2
            shift
            ;;
          *)
            break
            ;;
        esac
      done

      rmtree "$@"
    '';
  };
in
{
  home.packages = [ rm-tree ];
}
