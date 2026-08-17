{ pkgs, ... }:

{
  # Container Runtime (Docker & Podman support)
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Keep Docker native client as primary
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    docker-compose
    podman-compose
  ];
}
