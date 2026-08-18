_: {
  flake.modules.nixos.power = _: {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
      priority = 100;
    };

    systemd.oomd = {
      enable = true;
      enableUserSlices = true;
      enableSystemSlice = true;
    };

    systemd.settings.Manager = {
      RuntimeWatchdogSec = "30s";
      RebootWatchdogSec = "5m";
      KExecWatchdogSec = "5m";
      DefaultTimeoutStopSec = "30s";
      DefaultTimeoutStartSec = "60s";
    };
  };
}
