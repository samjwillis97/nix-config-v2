{
  programs.ashell = {
    enable = true;

    systemd.enable = true;

    settings = {
      modules = {
        left = [
          "Workspaces"
          "KeyboardSubmap"
        ];

        center = [
          "WindowTitle"
        ];

        right = [
          "MediaPlayer"
          "SystemInfo"
          [
            "Privacy"
            "Tray"
            "Settings"
            "Tempo"
          ]
        ];
      };

      workspaces = {
        visibilityMode = "MonitorSpecific";
        groupByMonitor = false;
        enableWorkspaceFilling = false;
        disableSpecialWorkspaces = false;
      };

      systemInfo = {
        indicators = [
          "Temperature"
          "Cpu"
          "Memory"
          # "Disk"
        ];
        interval = 1;

        cpu = {
          warnThreshold = 70;
          alertThreshold = 90;
        };

        memory = {
          warnThreshold = 70;
          alertThreshold = 85;
        };

        # disk = {
        #   warnThreshold = 80;
        #   alertThreshold = 90;
        # };

        temperature = {
          warnThreshold = 60;
          alertThreshold = 80;
          sensor = "k10temp Tctl";
        };
      };
    };
  };
}
