{
  imports = [ ../../../shared/theme.nix ];
  theme = {
    colors = with builtins; fromJSON (readFile ./dracula.json);
  };
}
