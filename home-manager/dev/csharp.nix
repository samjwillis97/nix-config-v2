{ pkgs, ... }: {
  home.packages = with pkgs; [
    dotnet-sdk_7
    mono
    # msbuild
    # dotnet-aspnetcore_7
    # dotnet-runtime_7
  ];
}
