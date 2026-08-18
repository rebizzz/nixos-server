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
    ├── flake/                      -> flake-parts wiring, devShell, deploy-rs checks
    ├── hosts/nixos-server/         -> One directory per machine
    │   ├── default.nix             -> Registers nixosConfigurations.<host> + deploy.nodes.<host>
    │   ├── _host.nix                -> All host-specific values (disks, hostId, wifi, IP, ...)
    │   ├── _disko.nix              -> Declarative disk partitioning (reads _host.nix)
    │   └── _hardware.nix           -> CPU tuning, initrd rollback, ZFS parameters, kernel modules
    └── system/
        ├── core/                   -> Base system, bootloader, users, auto-updates
        ├── hardware/               -> ZFS, graphics acceleration, power & thermals
        └── services/               -> Networking, SSH, Cockpit, MOTD, Docker
```

Files prefixed with `_` are plain data/host modules, deliberately excluded from
`import-tree`'s auto-discovery (which otherwise treats every `.nix` file under
`modules/` as a flake-parts module) — they're wired in explicitly instead.

---

## 🖥️ Adding a new host / reinstalling this one (nixos-anywhere)

This flake is a template: every machine gets its own `modules/hosts/<name>/`
directory, and everything that differs between machines (disks, `hostId`,
wifi SSID, LAN IP, SMART device serials, timezone) lives in one file:
`_host.nix`.

1. **Copy the host directory:**
   ```bash
   cp -r modules/hosts/nixos-server modules/hosts/<new-host>
   ```
2. **Edit `_host.nix`** — set `hostName`, a fresh `hostId`
   (`head -c4 /dev/urandom | od -A none -t x4`), the real disk devices,
   wifi SSID, LAN IP, and SMART device paths for the new machine.
3. **Regenerate hardware detection** from a live ISO booted on the target,
   then copy the relevant bits (`boot.initrd.availableKernelModules`,
   `boot.kernelModules`, CPU vendor) into `_hardware.nix`:
   ```bash
   nixos-anywhere --generate-hardware-config nixos-generate-config \
     ./modules/hosts/<new-host>/_hardware-generated.nix root@<target-ip>
   ```
4. **Install remotely with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)**
   from your laptop, targeting a machine booted off any Linux live
   environment with SSH (or via kexec on an already-running NixOS):
   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#<new-host> \
     --extra-files ./secrets/extra-files \
     root@<target-ip>
   ```
   `--extra-files` solves the chicken-and-egg secrets problem: put the host's
   sops age key at `./secrets/extra-files/persistent/etc/sops/age/keys.txt`
   (mode 600) before running the command, and nixos-anywhere copies it into
   place *before* the first boot, so `sops-nix` can decrypt `user_password`
   etc. immediately. Delete the local copy afterwards; the file only needs to
   exist transiently on your laptop.
5. **Add the new age key** to `.sops.yaml` and run `sops updatekeys secrets/secrets.yaml`.

For the existing `nixos-server` box specifically, the same command re-installs
it from scratch (disko wipes and repartitions the disks it's told to):
```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#nixos-server --extra-files ./secrets/extra-files root@<ip>
```

`install.sh` is kept as a fallback for running the install *locally* on a
low-RAM live ISO (it sets up zram swap and expands tmpfs before invoking
disko + `nixos-install`) — prefer nixos-anywhere when you can SSH in.

---

## 🛠️ Common Operations

### Deploy changes with deploy-rs (recommended):
```bash
nix develop   # brings deploy-rs, sops, nixos-anywhere into PATH

# Check syntax + deploy-rs schema first
nix flake check

# Deploy to the server over SSH (interactive confirmation + auto-rollback
# if the new generation doesn't check in within ~30s)
deploy .#nixos-server
```
`deploy.nodes.nixos-server` (in `modules/hosts/nixos-server/default.nix`)
targets `rebiz@nixos-server.local` as `root`, with `magicRollback` and
`autoRollback` enabled — a bad deploy reverts itself automatically.

### Deploy changes with plain nixos-rebuild (fallback):
```bash
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
