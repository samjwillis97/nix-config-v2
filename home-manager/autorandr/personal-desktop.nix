{ config, lib, pkgs, ... }: {
  programs.autorandr.profiles = {
    "primary" = {
      fingerprint = {
        DisplayPort-2 =
          "00ffffffffffff00410c0b093d0900001b1c0104b54628783a5905af4f42af270e5054bd4b00d1c081808140950f9500b30081c001014dd000a0f0703e8030203500ba8e2100001aa36600a0f0701f8030203500ba8e2100001a000000fc0050484c203332385036560a2020000000fd0017501ea03c010a202020202020011e020326f14b101f04130312021101051423090707830100006d030c00100019782000600102038c0ad08a20e02d10103e9600ba8e21000018011d007251d01e206e285500ba8e2100001e023a80d072382d40102c4580ba8e2100001e7d3900a080381f4030203a00ba8e2100001a000000000000000000000000000000000018";
        # HDMI-A-0 = "00ffffffffffff001e6dd658fe5700000a16010380301b78ea9535a159579f270e5054a54b00714f8180818fb3000101010101010101023a801871382d40582c4500dd0c1100001e000000fd00384b1e530f000a202020202020000000fc004950533232340a202020202020000000ff00323130494e5542304e3532360a00d4";
      };
      config = {
        DisplayPort-2 = {
          enable = true;
          primary = true;
          position = "0x0";
          mode = "3840x2160";
          rate = "60.00";
        };
        # HDMI-A-0 = {
        # enable = true;
        # primary = false;
        # position = "3840x404";
        # mode = "1920x1080";
        # rate = "60.00";
        # };
      };
    };
  };
}
