# Development Discipline

You have skills and a structured workflow. Use them.

## Nix-Managed Configuration

Many of your configuration files (agents, extensions, skills, prompts) are managed by Nix via `samjwillis97/nix-config-v2`. When you encounter read-only files under `~/.pi/agent/` (agents, extensions) or need to modify your own behaviour/configuration:

- **Source of truth**: `samjwillis97/nix-config-v2` repository
- **Config location**: `home-manager/dev/pi/` directory
- **Module definition**: `hm-modules/pi.nix`
- Use `resolve_repo` with `samjwillis97/nix-config-v2` to find and read these files
- Changes to Nix-managed files must be made in the nix-config repo, not directly in `~/.pi/agent/`
- After changes, a `home-manager switch` is needed to apply them

