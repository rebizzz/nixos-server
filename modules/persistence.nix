{ pkgs, ... }:

{
  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      commonMountOptions = [ "x-gvfs-hide" ];
      directories = [
        # NixOS UID/GID state — must be in initrd
        { directory = "/var/lib/nixos"; inInitrd = true; }

        # Systemd runtime state
        "/var/lib/systemd/timers"

        # Persistent logs
        "/var/log/journal"

        # Networking
        "/var/lib/NetworkManager"
        "/etc/NetworkManager/system-connections"

        # Bluetooth
        "/var/lib/bluetooth"

        # SMART history
        "/var/lib/smartmontools"

        # Docker container state
        "/var/lib/docker"

        # Tailscale mesh VPN state
        "/var/lib/tailscale"

        # Cockpit settings
        "/var/lib/cockpit"
      ];
      files = [
        # Machine ID must be stable for journald, Cockpit auth, etc.
        { file = "/etc/machine-id"; inInitrd = true; }

        # SSH host keys — prevents "host key changed" warnings on every reboot
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };

  services.journald.storage = "persistent";
}
