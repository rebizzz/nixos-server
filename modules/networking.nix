{pkgs, ...}: {
  networking = {
    hostName = "nixos-server";
    networkmanager = {
      enable = true;
      wifi = {
        powersave = false;
        backend = "wpa_supplicant";
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
