{ pkgs, ... }:

{
  services.cockpit = {
    enable = true;
    port = 9090;
    settings.WebService.AllowUnencrypted = true;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.mail.enable = false;
  };

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  environment.systemPackages = with pkgs; [
    smartmontools
    lm_sensors
  ];
}
