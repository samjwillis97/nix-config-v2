{ lib, ... }:
# This should build out a user
# Users should be like { module, userOverrides, extraHomeModules}
{
  buildUserConfig = { users ? [ ] }:
    # buildUserConfig = { module, extraHomeModules ? [], userOverrides ? {} }: 
    let
      # userConfig = module // userOverrides;
      # homeModules = module.homeModules ++ extraHomeModules;

      # buildNixOSUser = ( userConfig: userOverrides: 
      # {${userConfig.username} = {
      #     inherit (userConfig) isNormalUser uid extraGroups;
      #     # TODO: shell, password/File, ssh keys
      #   };
      # })

      buildHMUser = (userModule: extraHomeModules: {
        ${userModule.username} = userModule.homeModules ++ extraHomeModules;
      });

      hmUsers = lib.lists.map
        ((u: buildHMUser (u.module // u.userOverrides) u.extraHomeModules)
          builtins.filter ((u: u.isHomeManaged) users));
    in {
      home-manager = {
        useUserPackages = true;
        users = hmUsers;
        extraSpecialArgs = {
          # TODO: Finish 
        };
      };
      # users.users.${userConfig.username} = {
      #   inherit (userConfig) isNormalUser uid extraGroups;
      #   # TODO: shell, password/File, ssh keys
      # };

      # home-manager = if userConfig.isHomeManaged then {
      #   useUserPackages = true;
      #   users.${userConfig.username} = homeModules;
      #   extraSpecialArgs = { 
      #   };
      # } else {};
    };
}
