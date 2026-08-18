# nixos-server

NixOS configuration for a headless home server / homelab. Built with Flakes, `flake-parts` + `import-tree` (dendritic module layout), Disko, and opt-in persistence via the `preservation` module.

## Hardware

| Component | Details |
|---|---|
| CPU | Intel Core i3-3220 @ 3.30GHz (Ivy Bridge, 4T) |
| RAM | ~5.7 GiB — ZFS ARC/zram tunables in this repo are sized for this |
| Boot | UEFI |
| System SSD | `/dev/sda` — 120GB (Btrfs root) |
| Data Pool | `/dev/sdb` + `/dev/sdc` — 2× 500GB HDD ZFS Mirror (`data`) |
| Network | Realtek RTL810xE Ethernet + Realtek 802.11ac USB Wi-Fi |
| Hostname | `nixos-server` / `nixos-server.local` (mDNS) |
| LAN IP | `10.42.0.42` |

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

/dev/sdb + /dev/sdc (ZFS Mirror, nofail)
└── data           → /mnt/data
```

## Module Structure

Every module file registers itself into `flake.modules.nixos.<name>`; the host composes them by name instead of a flat `imports` list (the "dendritic" flake-parts pattern via [`import-tree`](https://github.com/vic/import-tree)). Files/dirs prefixed with `_` (host disk/hardware specs) are excluded from auto-registration and imported explicitly.

```
nixos-config/
├── flake.nix
├── modules/
│   ├── flake/flake-parts.nix        # enables flake.modules.* via flake-parts
│   ├── hosts/nixos-server/
│   │   ├── default.nix              # nixosSystem, composes named modules
│   │   ├── _disko.nix               # declarative disk partitioning
│   │   └── _hardware.nix            # kernel modules, ZFS ARC sizing, hostId
│   └── system/
│       ├── core/                    # base (boot/locale/stateVersion), nix (GC/optimise), autoupgrade, secrets, user
│       ├── hardware/                # zfs (scrubs/snapshots), power (zram/watchdog/oomd)
│       └── services/                # networking, security, containers, services (cockpit/tailscale/smartd), persistence, media (optional)
└── secrets/                          # sops-encrypted
```

## What's Included

- **Btrfs root** with ephemeral `/` (wiped on reboot), opt-in state at `/persistent`
- **ZFS mirror pool** (`data`) with monthly scrubs, staggered Btrfs scrubs, and Sanoid automated snapshots
- **ZFS ARC** capped at 2 GiB / min 512 MiB — sized for the real ~5.7 GiB of RAM on this box, not a generic default
- **USB Wi-Fi auto-modeswitch**: the dongle boots into a factory CD-ROM mode and is auto-ejected into real NIC mode via udev, no manual `usb-modeswitch` needed
- **zram** compressed swap (50% of RAM) — protects the SSD from swap wear
- **Tailscale** mesh VPN, **Cockpit** web console (`:9090`), **Docker** with weekly auto-prune
- **mDNS** via Avahi — reachable as `nixos-server.local` on LAN
- **fail2ban** on SSH + Cockpit, TCP BBR + sysctl hardening, systemd watchdogs, `systemd-oomd`
- **Unattended self-maintenance**: weekly `nixos-rebuild switch` from this repo (`system.autoUpgrade`, see below), weekly `nix.gc`/`nix.optimise`, `docker` autoprune, `fstrim`, smartd self-tests — most of this repo runs itself without you SSHing in
- SSH host keys, `machine-id`, and NetworkManager/Tailscale/Cockpit state persisted (no reboot fingerprint warnings, no re-pairing)

## Self-Maintenance (`system.autoUpgrade`)

`modules/system/core/autoupgrade.nix` pulls `git+https://github.com/rebizzz/nixos-server.git` (public repo, no deploy key needed) weekly at 04:00 (±45min jitter), runs `nixos-rebuild switch`, and reboots only if the kernel/modules changed, restricted to a 03:00–05:00 window. Rollback safety net is `boot.loader.systemd-boot.configurationLimit = 10` — the last 10 generations stay bootable from the boot menu if a switch goes bad.

To disable temporarily: `sudo systemctl stop nixos-upgrade.timer`.

## Optional Modules

**Jellyfin media server** with Intel VA-API hardware transcoding — not imported by default. To enable, uncomment the line in `modules/hosts/nixos-server/default.nix`:

```nix
# inputs.self.modules.nixos.media
```

Then deploy and open `http://nixos-server.local:8096`. Put media files at `/mnt/data/media`.

## Deployment

### Requirements

- Target machine booted into the [NixOS minimal ISO](https://nixos.org/download)
- SSH access from the deploying machine

### Fresh install (disko + nixos-anywhere)

```bash
cd /path/to/nixos-config
nix run github:nix-community/nixos-anywhere -- --flake .#nixos-server rebiz@<installer-ip>
```

This partitions/formats disks per `modules/hosts/nixos-server/_disko.nix`, installs NixOS, and reboots into the new system.

### After First Boot

```bash
ssh rebiz@nixos-server.local
passwd                       # change the initial password
sudo tailscale up
zpool status data            # confirm the pool imported
systemctl status cockpit tailscaled smartd sshd
```

### Day-to-Day Operations

Normally you shouldn't need any of this — `system.autoUpgrade` handles routine updates. For manual changes:

```bash
# From your workstation, after editing + pushing:
ssh rebiz@10.42.0.42 'cd /etc/nixos && sudo nixos-rebuild switch --flake .#nixos-server'

# Or run locally on the server, from a checked-out copy of this repo:
sudo nixos-rebuild switch --flake .#nixos-server

nix flake check                        # verify eval before deploying
nix flake update                       # bump flake inputs
sudo nix-collect-garbage -d            # reclaim store space immediately
zpool status data                      # ZFS pool health
sudo sanoid --list-snapshots           # list snapshots
sudo journalctl -p err -b              # boot errors, if something looks off
systemctl --failed                     # any failed units
```

### Verifying a Deploy

```bash
systemctl --failed                                 # expect: 0 loaded units
zpool status data                                   # expect: ONLINE, no errors
free -h                                             # sanity-check memory headroom
cat /sys/module/zfs/parameters/zfs_arc_max          # confirm ARC cap took effect
systemctl status sshd cockpit docker tailscaled smartd fail2ban
```

## Login

- **SSH**: key-based, authorized keys declared in `modules/system/core/user.nix`
- **Sudo**: passwordless for `rebiz`, restricted to `wheel` group members (`execWheelOnly`)
- **Cockpit**: `http://nixos-server.local:9090`
- Root/user password is sops-encrypted (`secrets/secrets.yaml`) — see `modules/system/core/secrets.nix`

## License

MIT
