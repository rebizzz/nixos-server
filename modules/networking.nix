{ pkgs, ... }:

{
  networking = {
    hostName = "nixos-server";
    networkmanager = {
      enable = true;
      wifi = {
        powersave = false;         # Keep USB Wi-Fi dongle always awake
        backend = "wpa_supplicant";
      };
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 9090 ]; # SSH, Cockpit
      allowedUDPPorts = [ 5353 ];    # mDNS
      # Tailscale interface is trusted — allow all traffic through it
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose"; # Required for Tailscale subnet routing
    };
  };

  # mDNS via Avahi — enables nixos-server.local hostname resolution on LAN
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

  # OpenSSH server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };

  # Useful network CLI tools
  environment.systemPackages = with pkgs; [
    iw
    ethtool
  ];
}
