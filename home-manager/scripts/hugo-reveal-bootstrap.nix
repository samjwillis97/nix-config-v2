{ pkgs, ... }:
let
  templatePath = ../hugo-reveal/template;

  hugo-reveal-bootstrap = pkgs.writeShellScriptBin "hugo-reveal-bootstrap" ''
    #!/usr/bin/env bash

    set -Eeuo pipefail

    # Template path from nix store
    TEMPLATE_PATH="${templatePath}"

    # Color setup
    setup_colors() {
      if [[ -t 2 ]] && [[ -z "''${NO_COLOR-}" ]] && [[ "''${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
      else
        NOFORMAT=''' RED=''' GREEN=''' YELLOW='''
      fi
    }

    msg() {
      echo >&2 -e "''${1-}"
    }

    usage() {
      cat << EOF
    Usage: $(basename "''${BASH_SOURCE[0]}") [-h] [project-name]

    Bootstrap a Hugo project with reveal.js theme and nib styling.

    Arguments:
        project-name    Optional name for the project (default: presentation-XXXXXX)

    Options:
        -h, --help      Print this help and exit
        -v, --verbose   Print script debug info

    Examples:
        hugo-reveal-bootstrap                    # Creates /tmp/presentation-XXXXXX
        hugo-reveal-bootstrap my-presentation    # Creates /tmp/my-presentation

    Output: JSON object with project paths and status
    EOF
      exit 0
    }

    error_json() {
      local error_msg="$1"
      local details="''${2-}"
      
      cat << EOF
    {
      "status": "error",
      "error": "$error_msg",
      "details": "$details"
    }
    EOF
      exit 1
    }

    success_json() {
      local temp_dir="$1"
      local project_dir="$2"
      local content_file="$3"
      local hugo_toml="$4"
      local screenshots_dir="$5"
      
      cat << EOF
    {
      "project_dir": "$project_dir",
      "content_file": "$content_file",
      "hugo_toml": "$hugo_toml",
      "screenshots_dir": "$screenshots_dir",
      "temp_dir": "$temp_dir",
      "status": "success"
    }
    EOF
    }

    # Pre-flight checks
    preflight_checks() {
      msg "''${YELLOW}Running pre-flight checks...''${NOFORMAT}"
      
      if ! command -v hugo &> /dev/null; then
        error_json "Hugo not found in PATH" "Install Hugo or ensure it's in your PATH"
      fi
      
      if ! command -v go &> /dev/null; then
        error_json "Go not found in PATH" "Go is required for Hugo modules. Install Go or ensure it's in your PATH"
      fi
      
      if [ ! -d "$TEMPLATE_PATH" ]; then
        error_json "Template directory not found" "Expected template at: $TEMPLATE_PATH"
      fi
    }

    # Create project directory
    create_project_dir() {
      local project_name="''${1-}"
      local temp_dir
      local project_dir
      
      msg "''${YELLOW}Creating project directory...''${NOFORMAT}"
      
      if [ -n "$project_name" ]; then
        # Use custom name with mktemp template pattern
        temp_dir=$(mktemp -d -t "$project_name-presentation-XXXXXX")
      else
        temp_dir=$(mktemp -d -t presentation-XXXXXX)
      fi
      
      project_dir="$temp_dir/presentation"
      mkdir -p "$project_dir"
      
      echo "$temp_dir"
    }

    # Copy template assets
    copy_template_assets() {
      local project_dir="$1"
      
      msg "''${YELLOW}Copying template assets...''${NOFORMAT}"
      
      # Copy all files and directories from template, preserving structure
      cp -r "$TEMPLATE_PATH"/* "$project_dir/"
      
      # Ensure proper permissions
      find "$project_dir" -type f -exec chmod 644 {} \;
      find "$project_dir" -type d -exec chmod 755 {} \;
    }

    # Initialize Hugo modules
    init_hugo_modules() {
      local project_dir="$1"
      
      msg "''${YELLOW}Initializing Hugo modules...''${NOFORMAT}"
      
      cd "$project_dir"
      
      # Initialize Hugo module
      if ! hugo mod init presentation-temp 2>&1 | grep -v "go: creating new go.mod"; then
        error_json "Failed to initialize Hugo module" "Check that Go is installed and working"
      fi
      
      # Get reveal-hugo theme
      if ! hugo mod get github.com/joshed-io/reveal-hugo 2>&1; then
        error_json "Failed to download reveal-hugo module" "Check internet connection or GitHub access"
      fi
    }

    # Validate setup
    validate_setup() {
      local project_dir="$1"
      
      msg "''${YELLOW}Validating setup...''${NOFORMAT}"
      
      # Check required files exist
      local required_files=(
        "hugo.toml"
        "content/_index.md"
        "layouts/_default/baseof.html"
        "layouts/_markup/render-codeblock-mermaid.html"
        "assets/stylesheets/nib-theme.scss"
      )
      
      for file in "''${required_files[@]}"; do
        if [ ! -f "$project_dir/$file" ]; then
          error_json "Required file missing" "File not found: $file"
        fi
      done
      
      # Try to build the site to validate configuration
      cd "$project_dir"
      if ! hugo --quiet 2>&1; then
        error_json "Hugo build validation failed" "The site configuration may be invalid"
      fi
    }

    # Cleanup on error
    cleanup_on_error() {
      local temp_dir="$1"
      
      if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        msg "''${RED}Cleaning up failed project...''${NOFORMAT}"
        rm -rf "$temp_dir"
      fi
    }

    # Main execution
    main() {
      local project_name="''${1-}"
      local temp_dir
      local project_dir
      
      setup_colors
      
      # Handle help flag
      case "''${project_name-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x; shift; project_name="''${1-}" ;;
      esac
      
      # Run preflight checks
      preflight_checks
      
      # Create project directory
      temp_dir=$(create_project_dir "$project_name")
      project_dir="$temp_dir/presentation"
      
      # Set up trap to cleanup on error
      trap 'cleanup_on_error "$temp_dir"' ERR
      
      # Copy template files
      copy_template_assets "$project_dir"
      
      # Initialize Hugo modules
      init_hugo_modules "$project_dir"
      
      # Validate the setup
      validate_setup "$project_dir"
      
      # Create screenshots directory
      mkdir -p "$project_dir/screenshots"
      
      # Success - output JSON result
      msg "''${GREEN}Success! Hugo project created.''${NOFORMAT}"
      success_json \
        "$temp_dir" \
        "$project_dir" \
        "$project_dir/content/_index.md" \
        "$project_dir/hugo.toml" \
        "$project_dir/screenshots"
    }

    main "$@"
  '';
in
{
  home.packages = [ hugo-reveal-bootstrap ];
}
