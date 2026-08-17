{ ... }:

{
  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      commonMountOptions = [ "x-gvfs-hide" ];
      directories = [
        { directory = "/var/lib/nixos"; inInitrd = true; }
        "/var/lib/systemd/timers"
        "/var/log/journal"
        "/var/lib/NetworkManager"
        "/etc/NetworkManager/system-connections"
        "/var/lib/bluetooth"
        "/var/lib/smartmontools"
        "/var/lib/docker"
        "/var/lib/tailscale"
        "/var/lib/cockpit"
      ];
      files = [
        { file = "/etc/machine-id"; inInitrd = true; }
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };

  services.journald.storage = "persistent";
}
