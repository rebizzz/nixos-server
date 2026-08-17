{pkgs, ...}: {
  # Jellyfin with Intel VA-API hardware transcoding (i3-3220 supports VA-API via i965 driver)
  #
  # To enable: uncomment ./modules/media.nix in configuration.nix imports
  # Access: http://nixos-server.local:8096 or http://10.42.0.172:8096
  # First run: open in browser and follow setup wizard, set media library to /mnt/data/media

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # VA-API hardware acceleration drivers (Intel Ivy Bridge uses i965)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver # i965 driver for Ivy Bridge / Haswell
      libvdpau-va-gl
    ];
  };

  users.users.jellyfin.extraGroups = ["video" "render"];

  # Persist Jellyfin config and metadata across ephemeral root reboots
  preservation.preserveAt."/persistent".directories = [
    "/var/lib/jellyfin"
  ];
}
