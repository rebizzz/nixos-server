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

    # Auto-recover from a hung boot/service since no one is around to power-cycle it.
    systemd.settings.Manager = {
      RuntimeWatchdogSec = "30s";
      RebootWatchdogSec = "5m";
      KExecWatchdogSec = "5m";
      DefaultTimeoutStopSec = "30s";
      DefaultTimeoutStartSec = "60s";
    };
  };
}
