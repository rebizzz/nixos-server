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
    ./modules/persistence.nix
  ];

  # Bootloader (UEFI systemd-boot)
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10; # Prevent /boot partition exhaustion
    };
    efi.canTouchEfiVariables = true;
  };

  # Keep /tmp in RAM — avoids SSD write wear on ephemeral files
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";
    cleanOnBoot = true;
  };

  # Time zone and locale
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix configuration
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

  # zram swap — compressed in-RAM swap, protects SSD from swap wear
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Systemd OOM daemon — gracefully kills runaway processes before hard freeze
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableSystemSlice = true;
  };

  # Core system packages
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

  # Import ZFS data pool on boot
  boot.zfs.extraPools = [ "data" ];

  system.stateVersion = "26.05";
}
