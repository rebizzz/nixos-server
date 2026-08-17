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
}
