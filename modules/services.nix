{ pkgs, ... }:

{
  # Cockpit Web Management Dashboard (Port 9090)
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };

  # Tailscale Mesh VPN for headless remote access
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # SMART disk health daemon for SSD and ZFS HDDs
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.mail.enable = false;
  };

  # Essential server utilities
  environment.systemPackages = with pkgs; [
    smartmontools
    btop
    htop
    lm_sensors
    tailscale
    cockpit
  ];
}
