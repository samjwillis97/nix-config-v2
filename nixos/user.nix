{ super, ... }:
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
}
