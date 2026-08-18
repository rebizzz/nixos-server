_: {
  flake.modules.nixos.services = {pkgs, ...}: {
    services.cockpit = {
      enable = true;
      port = 9090;
      settings.WebService.AllowUnencrypted = true;
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    # No spindown on continuously-running mechanical drives: spin-up/down
    # cycling wears these old HDDs more than just leaving them spinning.
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[bc]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"
    '';

    # by-id paths, not /dev/sdX, so a BIOS/USB re-enumeration can't silently
    # point smartd at the wrong disk.
    services.smartd = {
      enable = true;
      autodetect = false;
      defaults.autodetected = "-a -o on -S on -n standby,q -s (S/../.././03|L/../../6/04) -W 4,45,55";
      devices = [
        {device = "/dev/disk/by-id/ata-ST500DM002-1BD142_Z6E0EBEW";}
        {device = "/dev/disk/by-id/ata-ST3500414CS_6VVEHZ3V";}
      ];
      notifications.mail.enable = false;
    };

    services.fstrim = {
      enable = true;
      interval = "weekly";
    };
  };
}
