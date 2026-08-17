{ pkgs, ... }:

{
  networking = {
    hostName = "nixos-server";
    networkmanager = {
      enable = true;
      wifi = {
        powersave = false; # Disable Wi-Fi power saving for server stability
        backend = "wpa_supplicant";
      };
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 9090 ]; # SSH, HTTP, HTTPS, Cockpit
      allowedUDPPorts = [ ];
    };
  };

  # Wireless tools and network management packages
  environment.systemPackages = with pkgs; [
    iw
    wirelesstools
    wpa_supplicant
    networkmanager
    ethtool
  ];

  # OpenSSH server configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };
}
