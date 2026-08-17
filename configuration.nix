{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./modules/secrets.nix
    ./modules/users.nix
    ./modules/networking.nix
    ./modules/zfs.nix
    ./modules/containers.nix
    ./modules/services.nix
    ./modules/security.nix
    ./modules/persistence.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableSystemSlice = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    btop
    tmux
    pciutils
    usbutils
    btrfs-progs
    e2fsprogs
  ];

  boot.zfs.extraPools = ["data"];

  system.stateVersion = "26.05";
}
