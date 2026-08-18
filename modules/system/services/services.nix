_: {
  flake.modules.nixos.services = {
    pkgs,
    lib,
    hostVars,
    ...
  }: {
    services.cockpit = {
      enable = true;
      port = 9090;
      settings.WebService = {
        AllowUnencrypted = true;
        Origins = lib.mkForce (lib.concatStringsSep " " [
          "https://localhost:9090"
          "http://localhost:9090"
          "http://${hostVars.hostName}.local:9090"
          "https://${hostVars.hostName}.local:9090"
          "http://${hostVars.network.lanIp}:9090"
          "https://${hostVars.network.lanIp}:9090"
        ]);
      };
    };

    environment.systemPackages = [
      pkgs.cockpit
    ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };

    services.irqbalance.enable = true;

    services.udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="block", ENV{ID_BUS}=="ata", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"
    '';

    services.smartd = {
      enable = true;
      autodetect = false;
      devices = hostVars.smartDevices;
      notifications.mail.enable = false;
    };

    services.fstrim = {
      enable = true;
      interval = "weekly";
    };
  };
}
