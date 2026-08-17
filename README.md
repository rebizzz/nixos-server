# NixOS Server Configuration Flake

Declarative NixOS Flake configuration for `nixos-server` (`10.42.0.172`), featuring automated disko partitioning and nix-anywhere deployment.

## Hardware Overview
- **CPU**: Intel Core i3-3220 @ 3.30GHz
- **Architecture**: `x86_64-linux` (UEFI boot mode)
- **Main SSD (`/dev/sda`)**: 120GB SPCC SSD (Btrfs root + subvolumes)
- **Data Pool (`/dev/sdb` + `/dev/sdc`)**: 2x 500GB HDD ZFS Mirror (`data`)
- **Networking**: Realtek RTL810xE Ethernet & Realtek 802.11ac USB Wi-Fi

## Repository Structure
- `flake.nix`: Main Flake entrypoint (`nixosConfigurations.nixos-server`)
- `disko.nix`: Declarative disk layout for Btrfs SSD + ZFS HDD Mirror
- `hardware-configuration.nix`: Hardware-tuned kernel modules, graphics, CPU microcode, and host ID
- `configuration.nix`: Core NixOS configuration and system packages
- `modules/users.nix`: User `rebiz` with sudo & authorized SSH keys
- `modules/networking.nix`: Hostname setup (`nixos-server`), firewall & OpenSSH daemon
- `modules/zfs.nix`: ZFS auto-scrub and maintenance services

## Deployment via `nix-anywhere`

To deploy NixOS remotely to `rebiz@10.42.0.172` using `nix-anywhere`:

```bash
nix run github:nix-community/nix-anywhere -- --flake .#nixos-server root@10.42.0.172
```

Or with `rebiz` user (providing password prompt if target sudo is enabled):

```bash
nix run github:nix-community/nix-anywhere -- --flake .#nixos-server rebiz@10.42.0.172
```
