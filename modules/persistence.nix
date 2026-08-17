{ pkgs, ... }:

{
  # Preservation module for ephemeral root & opt-in persistence at /persistent
  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      commonMountOptions = [ "x-gvfs-hide" ];
      directories = [
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/var/lib/systemd/timers"
        "/var/lib/bluetooth"
        "/var/lib/smartmontools"
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"
        "/var/log/journal"
        "/var/lib/docker"
        "/var/lib/tailscale"
        "/var/lib/cockpit"
      ];
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };

  # Systemd persistent logging
  services.journald.storage = "persistent";
}
