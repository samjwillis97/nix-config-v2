{ super, pkgs, ... }:
let
  osSpecificPackages = if super.meta.isDarwin then [ ] else with pkgs; [ gcc ];
in
{
  home.packages =
    with pkgs;
    [
      cargo
      rustc
      rustfmt
      rust-analyzer
    ]
    ++ osSpecificPackages;
}
