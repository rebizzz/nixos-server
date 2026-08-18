{
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.systemd.services.rollback-root = {
    description = "Roll back / to a blank btrfs snapshot";
    wantedBy = ["initrd.target"];
    after = ["dev-disk-by\\x2dpartlabel-disk\\x2dsda\\x2droot.device"];
    requires = ["dev-disk-by\\x2dpartlabel-disk\\x2dsda\\x2droot.device"];
    before = ["sysroot.mount"];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    path = [pkgs.btrfs-progs pkgs.coreutils pkgs.util-linux];
    script = ''
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ /dev/disk/by-partlabel/disk-sda-root /mnt
      btrfs subvolume list -o /mnt/@ |
        cut -f9 -d' ' |
        while read -r subvolume; do
          btrfs subvolume delete "/mnt/$subvolume"
        done
      btrfs subvolume delete /mnt/@
      btrfs subvolume snapshot /mnt/@blank /mnt/@
      umount /mnt
    '';
  };

  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "panic=10"
    "oops=panic"
    "zfs.zfs_arc_min=536870912" # 512 MiB
    "zfs.zfs_arc_max=2147483648" # 2 GiB
    "zfs.zfs_arc_sys_free=536870912" # 512 MiB headroom
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "ehci_pci"
    "usb_storage"
    "sd_mod"
    "sr_mod"
    "r8169"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [
    "kvm-intel"
    "tcp_bbr"
    "rtw88_8821cu"
    "rtw88_core"
    "rtw88_usb"
    "btusb"
  ];
  boot.extraModulePackages = [];

  boot.supportedFilesystems = ["btrfs" "zfs"];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.wirelessRegulatoryDatabase = true;

  networking.hostId = "8425e349";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
