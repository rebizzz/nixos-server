_: {
  flake.modules.nixos.zfs = _: {
    boot.zfs.extraPools = ["data"];
    boot.zfs.forceImportRoot = false;

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "Sun, 02:00";
        pools = ["data"];
      };
      trim.enable = false; # mechanical HDDs, not SSDs
    };

    services.btrfs.autoScrub = {
      enable = true;
      interval = "*-*-15 03:00:00"; # staggered from the ZFS scrub
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
  };
}
