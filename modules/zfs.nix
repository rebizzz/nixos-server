_: {
  boot.zfs.forceImportRoot = false;

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
      pools = ["data"];
    };
    trim.enable = false;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = ["/"];
  };

  services.sanoid = {
    enable = true;
    datasets."data" = {
      useTemplate = ["production"];
      recursive = true;
    };
    templates.production = {
      frequently = 0;
      hourly = 24;
      daily = 7;
      monthly = 3;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
    MaxRetentionSec=1month
  '';
}
