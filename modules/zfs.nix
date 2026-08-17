{ pkgs, ... }:

{
  # ZFS Maintenance and Monitoring
  boot.zfs.forceImportRoot = false;

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # Sanoid automated ZFS snapshot management
  services.sanoid = {
    enable = true;
    datasets = {
      "data" = {
        useTemplate = [ "production" ];
        recursive = true;
      };
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
}
