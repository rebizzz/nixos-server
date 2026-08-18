_: {
  flake.modules.nixos.autoupgrade = _: {
    system.autoUpgrade = {
      enable = true;
      flake = "git+https://github.com/rebizzz/nixos-server.git#nixos-server";
      dates = "04:00";
      randomizedDelaySec = "45min";
      allowReboot = true;
      rebootWindow = {
        lower = "03:00";
        upper = "05:00";
      };
      operation = "switch";
    };
  };
}
