# nixos-server

A NixOS config for a headless home server. You point `nixos-rebuild` at this repo and it builds the whole machine: disk layout, network, services, all of it. No manual setup steps beyond the first install.

Everything below assumes you're new to this repo or setting it up on different hardware.

## The disk, in plain terms

The system disk (`/dev/sda`, a small SSD) is split into separate Btrfs subvolumes for `/`, `/home`, `/nix`, `/persistent`, `/tmp`, and `/var/log`. All of them are regular, persistent storage, nothing here gets wiped on reboot.

`/persistent` exists as a deliberate convention: things that matter (SSH host keys, Docker's data, Tailscale's state) are bind-mounted from there into their normal location, declared in `modules/system/services/persistence.nix`. That list was originally meant to back an ephemeral root (wipe `/` every boot, keep only what's explicitly listed), but that wipe was never actually implemented, `/` just persists like any normal Linux install. The bind-mounts are harmless leftovers from that original plan, not load-bearing for anything working today.

Separately, two old spinning hard drives (`/dev/sdb` + `/dev/sdc`) are mirrored together with ZFS into a pool called `data`, mounted at `/mnt/data`. This is where actual data goes, media files, backups, whatever, because it survives a single drive dying (the system SSD is not mirrored, and a dead SSD takes the whole machine down).

```
system SSD (Btrfs, all persistent)
├── /boot
├── /              ← OS + anything installed outside of this repo (see caveat below)
├── /persistent    ← convention for "stuff this repo explicitly cares about"
├── /nix           ← the actual OS, built from this repo
└── /var/log

data pool (ZFS mirror, 2 HDDs, survives one drive dying)
└── /mnt/data      ← put your actual files here
```

**Caveat**: because `/` isn't wiped, anything you do by hand on the box (installing a package with `nix-env`, editing a file outside of git) will silently survive reboots instead of resetting to what this repo declares. If you want the machine to always exactly match this repo, don't rely on that, only change things by editing this repo and deploying.

## How the config is organized

Everything lives under `modules/`, one concern per file. Instead of one giant config file importing everything, each file declares itself into a shared registry (`flake.modules.nixos.<name>`) and a "base" module in `modules/system/core/base.nix` automatically pulls in all of them. You don't have to remember to wire up a new file, if it's under `modules/system/`, it's included automatically.

```
modules/
├── hosts/nixos-server/     ← THIS machine's specifics: disk layout, hardware, hostname
│   ├── default.nix         ← wires the host together
│   ├── _disko.nix          ← which physical disks, how they're partitioned
│   └── _hardware.nix       ← kernel modules, RAM-dependent tuning, hostId
└── system/
    ├── core/                ← boot, locale, users, auto-updates
    ├── hardware/            ← ZFS, zram, power/watchdog settings
    └── services/            ← networking, SSH, Docker, Cockpit, Tailscale, etc.
```

Files starting with `_` (the two under `hosts/nixos-server/`) are hardware-specific and don't get auto-included, they're wired in by hand in `default.nix` because they only make sense for this exact machine.

## What's actually running

- **Auto-updates**: once a week the box pulls this repo from GitHub and rebuilds itself. It only reboots if the kernel changed, and only in a 3–5am window. If a bad update ever leaves it unbootable, the boot menu keeps the last 10 generations, pick an older one.
- **Health banner**: every time you SSH in, you get a one-line warning if anything's actually wrong (failed service, unhealthy disk, degraded ZFS pool). Silent if everything's fine.
- **Wi-Fi self-heal**: a background check every minute makes sure Wi-Fi is actually connected and reconnects it if not (NetworkManager has a known bug where it doesn't always autoconnect on its own).
- **Cleans up after itself**: old system versions, unused Docker images, old ZFS snapshots, and journal logs all get pruned automatically on a schedule. Disk usage doesn't creep up over time.
- **Cockpit**: a web dashboard at `http://nixos-server.local:9090` for a GUI view of the machine.
- **Tailscale**: a VPN so you can reach the box from anywhere without opening ports on your router.

## Jellyfin (media server), optional

Jellyfin isn't turned on by default. It's a media server (think self-hosted Netflix for your own files) that lives in `modules/system/services/media.nix`, and it's set up to use this box's Intel GPU for hardware video transcoding instead of burning the CPU.

It's off by default because not everyone running this repo wants a media server eating resources. To turn it on, edit `modules/hosts/nixos-server/default.nix` and uncomment one line:

```nix
modules = [
  inputs.self.modules.nixos.base
  ./_disko.nix
  ./_hardware.nix
  inputs.self.modules.nixos.media  # was commented out
];
```

Push, deploy (see below), then open `http://nixos-server.local:8096` and put your media files in `/mnt/data/media`.

## Setting this up on your own machine

This repo is currently wired for one specific box (an old i3 with 2 spinning disks + 1 SSD). If you want to reuse it for different hardware, here's everything that's hardware-specific and needs changing:

| What | Where | What to change it to |
|---|---|---|
| Disk device names | `modules/hosts/nixos-server/_disko.nix` | Your actual `/dev/sdX` (or better, `/dev/disk/by-id/...`) paths. Run `lsblk` on the target machine to find them. |
| Hostname | `modules/system/services/networking.nix` | Whatever you want the box to be called. |
| Machine-unique ZFS ID | `modules/hosts/nixos-server/_hardware.nix` (`networking.hostId`) | Any random 8 hex digits, just needs to be unique. `head -c4 /dev/urandom \| od -A none -t x4` generates one. |
| RAM-based tuning (ZFS ARC, zram) | `modules/hosts/nixos-server/_hardware.nix`, `modules/system/hardware/power.nix` | Check `free -h` on the target machine and size these to roughly a quarter to a third of total RAM, not a fixed number copied from here. |
| Wi-Fi network name/password | `modules/system/services/networking.nix` (`ensureProfiles.profiles`), `secrets/secrets.yaml` (the `wifi_psk` secret) | Your own SSID, and re-encrypt the secret for your own age key (see below). |
| Smartd disk IDs, hdparm spindown rule | `modules/system/services/services.nix` | The `by-id` paths of your own disks, from `ls /dev/disk/by-id/`. Skip entirely if you don't have spinning disks. |
| Cockpit allowed origins | `modules/system/services/services.nix` (`Origins`) | Your box's hostname and IP, in place of `nixos-server.local` / `10.42.0.42`. |
| SSH keys, GitHub repo URL for auto-upgrade | `modules/system/core/user.nix`, `modules/system/core/autoupgrade.nix` | Your own SSH public keys, and your own fork's URL if you're not pushing to `rebizzz/nixos-server`. |
| USB Wi-Fi modeswitch IDs | `modules/system/services/networking.nix` | Only relevant if you have a USB Wi-Fi dongle that boots into a fake CD-ROM mode. Remove this whole block if not, or find your device's IDs with `lsusb`. |

### Secrets

Secrets (the wifi password, the login password) are encrypted with [sops](https://github.com/getsops/sops) into `secrets/secrets.yaml`, and only decryptable with the age key declared in `.sops.yaml`. To use this repo on your own machine:

1. Generate your own age key: `age-keygen -o key.txt`
2. Put the public key it prints into `.sops.yaml`
3. Re-encrypt the secrets file for your key: `sops updatekeys secrets/secrets.yaml`
4. Put the private key (`key.txt`) at `/persistent/etc/sops/age/keys.txt` on the target machine, this is the one thing that has to exist there before secrets can decrypt, and it's not something git can hand you back if you lose it. Keep a backup somewhere else too.

### Installing fresh

Boot the target machine into the [NixOS minimal ISO](https://nixos.org/download), then from your own computer:

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#nixos-server rebiz@<installer-ip>
```

This partitions the disks exactly as declared in `_disko.nix`, installs NixOS, and reboots into the finished system. After it comes back up:

```bash
ssh rebiz@nixos-server.local
passwd                       # change the initial password
sudo tailscale up            # join your tailnet, if using it
zpool status data            # confirm the ZFS pool imported cleanly
```

## Making changes after that

You don't need a checkout of this repo on the server itself, edit locally, push to GitHub, then:

```bash
ssh rebiz@10.42.0.42 'sudo nixos-rebuild switch --flake github:rebizzz/nixos-server#nixos-server'
```

Most weeks you won't even need to do this, the auto-upgrade timer does it for you. Useful commands either way:

```bash
nix flake check                # catch config errors before deploying
systemctl --failed             # any broken services right now
zpool status data              # ZFS pool health
sudo journalctl -p err -b      # boot errors, if something looks off
```

## Logging in

- **SSH**: key-based only (no passwords accepted). Your public key needs to be in `modules/system/core/user.nix`.
- **Sudo**: passwordless for the `rebiz` user, no separate root login exists.
- **Cockpit**: `http://nixos-server.local:9090`, same login as SSH.

## License

MIT
