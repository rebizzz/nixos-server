# nixos-server

NixOS configuration for a headless home server / homelab. Built with Flakes, Disko, and opt-in persistence via the `preservation` module.

## Hardware

| Component | Details |
|---|---|
| CPU | Intel Core i3-3220 @ 3.30GHz (Ivy Bridge, 4T) |
| Boot | UEFI |
| System SSD | `/dev/sda` — 120GB SPCC (Btrfs root) |
| Data Pool | `/dev/sdb` + `/dev/sdc` — 2× 500GB HDD ZFS Mirror (`data`) |
| Network | Realtek RTL810xE Ethernet + Realtek 802.11ac USB Wi-Fi |
| Hostname | `nixos-server` / `nixos-server.local` (mDNS) |

## Storage Layout

```
/dev/sda (Btrfs)
├── /boot          (FAT32 EFI, 1GB)
├── @              → /              (ephemeral root)
├── @home          → /home
├── @nix           → /nix
├── @persistent    → /persistent    (opt-in state)
├── @tmp           → /tmp           (cleared on reboot)
└── @log           → /var/log

/dev/sdb + /dev/sdc (ZFS Mirror)
└── data           → /mnt/data
```

## Module Structure

```
nixos-config/
├── flake.nix
├── configuration.nix       # Top-level config
├── hardware-configuration.nix
├── disko.nix               # Declarative disk partitioning
└── modules/
    ├── users.nix           # User accounts & SSH keys
    ├── networking.nix      # NetworkManager, mDNS, SSH, firewall
    ├── security.nix        # fail2ban, sysctl hardening, TCP BBR
    ├── zfs.nix             # ZFS scrub, Sanoid snapshots, Btrfs scrub
    ├── containers.nix      # Docker + docker-compose
    ├── services.nix        # Cockpit, Tailscale, smartd, fstrim
    ├── persistence.nix     # Preservation (opt-in state across reboots)
    └── media.nix           # [OPTIONAL] Jellyfin + Intel VA-API (disabled by default)
```

## What's Included

- **Btrfs root** with ephemeral `/` (wiped on reboot), opt-in state at `/persistent`
- **ZFS mirror pool** (`data`) with weekly scrubs and Sanoid automated snapshots
- **Tailscale** mesh VPN
- **Cockpit** web management console at `:9090`
- **Docker** with weekly auto-prune
- **mDNS** via Avahi — reachable as `nixos-server.local` on LAN
- **fail2ban** SSH protection
- **TCP BBR** congestion control + comprehensive sysctl tuning
- **ZFS ARC** capped at 1.5GB to avoid RAM pressure
- **zram** compressed swap (protects SSD from swap wear)
- **SSH host keys** and `machine-id` persisted (no fingerprint warnings on reboot)

## Optional Modules

**Jellyfin media server** with Intel VA-API hardware transcoding:

```nix
# configuration.nix — uncomment this line:
./modules/media.nix
```

Then deploy and open `http://nixos-server.local:8096` to finish setup.

Put media files at `/mnt/data/media`.

## Deployment

### Requirements

- Target machine booted into [NixOS minimal ISO](https://nixos.org/download)
- SSH access from deploying machine

### Install with nix-anywhere

```bash
cd /path/to/nixos-config
nix run github:nix-community/nix-anywhere -- --flake .#nixos-server rebiz@10.42.0.172
```

This will:
1. Partition and format all disks according to `disko.nix`
2. Install NixOS with this flake configuration
3. Reboot into the new system

### After First Boot

```bash
# SSH in
ssh rebiz@nixos-server.local

# Change your password
passwd

# Connect Tailscale
sudo tailscale up

# Check ZFS pool imported
zpool list

# Check everything is running
systemctl status cockpit tailscaled smartd
```

## Day-to-Day Operations

```bash
# Rebuild & switch config (run on server)
sudo nixos-rebuild switch --flake .#nixos-server

# Update flake inputs
nix flake update

# Garbage collect old generations
sudo nix-collect-garbage -d

# Check ZFS pool health
zpool status data

# View Sanoid snapshots
sudo sanoid --list-snapshots
```

## Login

- **Password**: `reejitbiswas` (change on first boot with `passwd`)
- **SSH**: Key-based, authorized keys pre-configured
- **Sudo**: Passwordless for `rebiz`
- **Cockpit**: `http://nixos-server.local:9090`

## License

MIT
