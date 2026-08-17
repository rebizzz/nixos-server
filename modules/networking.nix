{
  config,
  pkgs,
  ...
}: {
  networking = {
    hostName = "nixos-server";
    networkmanager = {
      enable = true;
      wifi = {
        powersave = false;
        backend = "wpa_supplicant";
      };
      ensureProfiles = {
        environmentFiles = [config.sops.templates."network-manager.env".path];
        profiles.ReBiz = {
          connection = {
            id = "ReBiz";
            type = "wifi";
            autoconnect = true;
            autoconnect-priority = 100;
          };
          wifi = {
            mode = "infrastructure";
            ssid = "ReBiz";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$WIFI_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [22 9090];
      allowedUDPPorts = [5353];
      trustedInterfaces = ["tailscale0"];
      checkReversePath = "loose";
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
    };
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };

  environment.systemPackages = with pkgs; [
    iw
    ethtool
  ];
}
