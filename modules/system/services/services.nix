_: {
  flake.modules.nixos.services = {
    pkgs,
    lib,
    ...
  }: {
    services.cockpit = {
      enable = true;
      port = 9090;
      settings.WebService = {
        AllowUnencrypted = true;
        # the cockpit module defaults this to "https://localhost:9090" alone;
        # must list every scheme+host+port combo actually used to reach it
        Origins = lib.mkForce "https://localhost:9090 http://localhost:9090 http://nixos-server.local:9090 https://nixos-server.local:9090 http://10.42.0.42:9090 https://10.42.0.42:9090";
      };
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    # spin-up/down cycling wears these old HDDs more than leaving them spinning
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[bc]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"
    '';

    # by-id paths so a BIOS/USB re-enumeration can't point smartd at the wrong disk
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
