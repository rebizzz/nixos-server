{inputs, ...}: {
  # pulls in every other flake.modules.nixos.* except "media" (opt-in per host)
  flake.modules.nixos.base = {pkgs, ...}: {
    imports =
      [
        inputs.disko.nixosModules.disko
        inputs.preservation.nixosModules.default
        inputs.sops-nix.nixosModules.sops
      ]
      ++ builtins.attrValues (builtins.removeAttrs inputs.self.modules.nixos ["base" "media"]);

    time.timeZone = "Asia/Kolkata";
    i18n.defaultLocale = "en_US.UTF-8";

    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      timeout = 3;
      efi.canTouchEfiVariables = true;
    };

    systemd.enableEmergencyMode = false;

    environment.systemPackages = with pkgs; [
      git
      nano
      curl
      wget
      btop
      fastfetch
      tmux
      pciutils
      usbutils
      btrfs-progs
      e2fsprogs
      hdparm
      smartmontools
      lm_sensors
      nh
    ];

    system.stateVersion = "26.05";
  };
}
