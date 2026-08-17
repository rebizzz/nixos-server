{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./modules/users.nix
    ./modules/networking.nix
    ./modules/zfs.nix
    ./modules/containers.nix
    ./modules/services.nix
    ./modules/security.nix
  ];

  # Bootloader setup (UEFI systemd-boot)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Time zone and locale settings
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable Nix Flakes and modern CLI tools
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Core system packages
  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    curl
    wget
    htop
    btop
    tmux
    pciutils
    usbutils
    lm_sensors
    btrfs-progs
    zfs
    e2fsprogs
  ];

  # Enable zfs service for importing data pool on boot
  boot.zfs.extraPools = [ "data" ];

  # System state version
  system.stateVersion = "26.05";
}
