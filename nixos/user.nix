{
  super,
  ...
}:
let
  inherit (super.meta) username useHomeManager;
in
{
  imports = [ ../modules/system/users ];

  modules.system.users.standardUser = {
    enable = true;
    username = username;
    useHomeManager = useHomeManager;
  };

  users.users.deployer = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    password = "very-complex-password";
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENzw8pIt2UVGWcXUx4E4AxxWj8zA+DLZSp0y7RGK5VW samuel.willis@nib.com.au"
      ];
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "deployer" ];
      commands = [
        { 
          command = "ALL" ;
          options= [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
        }
      ];
    }
  ];

  programs.zsh.enable = true;
}
