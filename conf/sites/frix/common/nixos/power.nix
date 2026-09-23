{
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = [ pkgs.brightnessctl ];

  powerManagement.powertop.enable = true;

  services = {
    power-profiles-daemon.enable = lib.mkForce false;

    thermald = {
      enable = true;
      ignoreCpuidCheck = true;
    };

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_BAT = "auto";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "auto";
        CPU_MAX_PERF_ON_BAT = 50; # 限制电池下最大性能百分比，按需调整
        START_CHARGE_THRESH_BAT0 = 40; # 延长电池寿命
        STOP_CHARGE_THRESH_BAT0 = 80; # 延长电池寿命
      };
    };

    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  };
}
