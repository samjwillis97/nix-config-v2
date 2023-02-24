{ super, config, lib, pkgs, ... }:
{
    programs.i3status-rust = {
        enable = true;
        package = pkgs.i3status-rust;
        bars =
            let
                settings = {
                    theme = {
                        name = "plain";
						overrides = with config.theme.colors; {
                            idle_bg = base00;
                            idle_fg = base05;
                            info_bg = base0D;
                            info_fg = base00;
                            good_bg = base00;
                            good_fg = base05;
                            warning_bg = base0A;
                            warning_fg = base00;
                            critical_bg = base08;
                            critical_fg = base00;
                            separator_bg = base00;
                            separator = " ";
                        };
                    };
                    icons = {
                        name = "awesome5";
                        overrides = {
                            memory_swap = " ";
                            disk_drive = " ";
                            caffeine_on = "  ";
                            caffeine_off = "  ";
                            notification_on = "  ";
                            notification_off = "  ";
                        };
                    };
                };

                netBlock = {
                    block = "net";
                    device = "${super.meta.networkAdapterName}";
                    format = "{ip} {speed_down;K*b} {graph_down;K*b}";
                    interval = 5;
                };

                diskBlock = {
                    block = "disk_space";
                    path = "/";
                    alias = "/";
                    info_type = "available";
                    unit = "GB";
                    interval = 20;
                    warning = 20.0;
                    alert = 10.0;
                };

                memoryBlock = {
                    block = "memory";
                    display_type = "memory";
                    format_mem = "{mem_used_percents}";
                    format_swap = "{swap_used_percents}";
                };

                cpuBlock = {
                    block = "cpu";
                    interval = 1;
                };

                loadBlock = {
                    block = "load";
                    interval = 1;
                    format = "{1m}";
                };

                soundBlock = {
                    block = "sound";
                };

                timeBlock = {
                    block = "time";
                    interval = 5;
                    format = "%a %d/%m %R";
                };
            in
            {
                i3 = {
                    inherit settings;

                    blocks = lib.lists.flatten [
                        netBlock
                        diskBlock
                        memoryBlock
                        cpuBlock
                        loadBlock
                        soundBlock
                        timeBlock
                    ];
                };
            };
    };
}
