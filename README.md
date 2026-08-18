# nixos-server

A clean, declarative NixOS setup for a headless home server. It handles the entire machine: disk partitioning, network mesh, ZFS storage, secrets, and daily self-maintenance.

---

## ⚡ Quick Links & Access

- **Web Dashboard (Cockpit)**: `http://nixos-server.local:9090` (or `http://10.42.0.42:9090`)
- **SSH**: `ssh rebiz@nixos-server.local` (Key-based only)
- **Tailscale Mesh**: Connected with Subnet Router enabled

---

## 🗄️ Storage Layout

The server uses a fast SSD for the operating system and two mirrored hard drives for data.

```
System SSD (120 GB Kingston, Btrfs)
├── /boot          -> UEFI bootloader (systemd-boot)
├── /              -> Ephemeral root (automatically wiped clean on every boot)
├── /persistent    -> Preserved state (machine-id, SSH host keys, Docker, Tailscale)
├── /nix           -> Immutable Nix store
└── /var/log       -> Systemd journal logs

Data Pool (450 GB ZFS Mirror, 2x Seagate HDDs)
├── /mnt/data/media    -> Movies, shows, music (1M recordsize for smooth streaming)
├── /mnt/data/backup   -> Local snapshots and backup archives
└── /mnt/data/storage  -> General file shares and documents
```

### Why this design?
1. **Zero System Drift**: The root filesystem (`/`) wipes itself on every boot. Only paths explicitly listed in `persistence.nix` survive. The machine never accumulates random leftover junk.
2. **Dual Drive Safety**: The two mechanical drives mirror each other. If one drive fails, the server continues running with zero data loss.
3. **1M Block Optimization**: The `media` dataset uses 1 MB block sizes, cutting ZFS RAM overhead and boosting movie read speeds from spinning disks.

---

## 🚀 Key Features

- **Live MOTD Dashboard**: Instant system stats every time you log in (CPU load, uptime, RAM, swap, SSD/ZFS health, and IP addresses) with zero login delay.
- **Smart Memory (zram)**: 5.7 GB of compressed in-RAM swap (`zstd`) matched 1:1 to physical memory. Eliminates disk swapping and prevents out-of-memory crashes.
- **Auto-Updates**: Rebuilds itself weekly from GitHub. Only reboots during a quiet 3:00 AM to 5:00 AM window if the kernel changes.
- **Automated ZFS & Btrfs Health**: Automatic weekly ZFS pool scrubs and monthly Btrfs filesystem checks.
- **Wi-Fi Watchdog**: Auto-detects lost connections and reconnects the Wi-Fi card in the background.
- **Encrypted Secrets (SOPS + Age)**: Wi-Fi passwords and credentials stay encrypted inside git. Decryptable by the server and your laptop master SSH key.

---

## 📁 Repository Structure

```
.
├── flake.nix                       -> Entrypoint using flake-parts & import-tree
├── secrets/                        -> SOPS-encrypted secrets (secrets.yaml)
└── modules/
    ├── hosts/nixos-server/         -> Hardware definitions and host wiring
    │   ├── default.nix             -> Host module registry
    │   ├── _disko.nix              -> Declarative disk partitioning
    │   └── _hardware.nix           -> CPU tuning, initrd rollback, ZFS parameters
    └── system/
        ├── core/                   -> Base system, bootloader, users, auto-updates
        ├── hardware/               -> ZFS, graphics acceleration, power & thermals
        └── services/               -> Networking, SSH, Cockpit, MOTD, Docker
```

---

## 🛠️ Common Operations

### Deploy changes from your computer:
```bash
# Check syntax first
nix flake check

# Deploy to server over SSH
nixos-rebuild switch --flake .#nixos-server --target-host rebiz@nixos-server.local --use-remote-sudo
```

### Useful diagnostic commands on the server:
```bash
# Check ZFS pool health and datasets
zpool status data
zfs list

# Check for any failed background services
systemctl --failed

# View recent system errors
sudo journalctl -p err -b
```

---

## 🔑 Managing Secrets

Secrets live in `secrets/secrets.yaml` and are encrypted with [sops](https://github.com/getsops/sops).

Both the **server** and your **laptop SSH key** are configured as recipients in `.sops.yaml`. You can edit secrets directly on your laptop:

```bash
# Edit secrets on your laptop
sops secrets/secrets.yaml

# Re-encrypt for all keys listed in .sops.yaml
sops updatekeys secrets/secrets.yaml
```

---

## 📄 License

MIT
