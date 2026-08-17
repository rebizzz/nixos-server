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

  # Tailscale Mesh VPN for secure remote access
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

  # Additional server monitoring and diagnostic utilities
  environment.systemPackages = with pkgs; [
    smartmontools
    glances
    lm_sensors
    tailscale
  ];
}
