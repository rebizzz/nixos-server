{ pkgs, ... }:

{
  # Cockpit web management console (port 9090)
  services.cockpit = {
    enable = true;
    port = 9090;
    settings.WebService.AllowUnencrypted = true;
  };

  # Tailscale mesh VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # SMART disk health monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.mail.enable = false;
  };

  # Periodic SSD TRIM (batched weekly — better for NAND longevity than continuous discard)
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  environment.systemPackages = with pkgs; [
    smartmontools
    lm_sensors
  ];
}
