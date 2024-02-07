{ pkgs, ... }: {
  home.packages = with pkgs; [
    terraform
    terraform-providers.azurerm
    azure-cli
  ];
}
