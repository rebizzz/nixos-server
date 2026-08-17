{ ... }:

{
  boot.zfs.forceImportRoot = false;

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
      pools = [ "data" ];
    };
    # HDDs don't support TRIM — disable to avoid spurious errors
    trim.enable = false;
  };

  # Btrfs root SSD scrub — catches bitrot on system drive
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Sanoid automated ZFS snapshots for data pool
  services.sanoid = {
    enable = true;
    datasets."data" = {
      useTemplate = [ "production" ];
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

  # Cap journal size to prevent SSD write churn
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
    MaxRetentionSec=1month
  '';
}
