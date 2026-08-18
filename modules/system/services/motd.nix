_: {
  flake.modules.nixos.motd = {pkgs, ...}: {
    environment.interactiveShellInit = ''
      ${pkgs.writeShellScript "motd-check" ''
              #!/bin/sh
              issues=""

              failed=$(systemctl --failed --no-legend --plain 2>/dev/null | wc -l)
              if [ "$failed" -gt 0 ]; then
                issues="$issues
        - $failed failed systemd unit(s) (systemctl --failed)"
              fi

              pool_health=$(sudo -n zpool list -H -o health data 2>/dev/null)
              if [ -n "$pool_health" ] && [ "$pool_health" != "ONLINE" ]; then
                issues="$issues
        - ZFS pool 'data' is $pool_health (zpool status data)"
              fi

              for disk in /dev/disk/by-id/ata-ST500DM002-1BD142_Z6E0EBEW /dev/disk/by-id/ata-ST3500414CS_6VVEHZ3V; do
                result=$(sudo -n smartctl -H "$disk" 2>/dev/null)
                case "$result" in
                  *PASSED*) ;;
                  "") ;;
                  *) issues="$issues
        - SMART health check failed on $disk (smartctl -a $disk)";;
                esac
              done

              last_upgrade=$(systemctl show nixos-upgrade.service -p Result --value 2>/dev/null)
              if [ -n "$last_upgrade" ] && [ "$last_upgrade" != "success" ]; then
                issues="$issues
        - last nixos-upgrade.service run did not succeed: $last_upgrade (journalctl -u nixos-upgrade)"
              fi

              if [ -n "$issues" ]; then
                printf 'system health warnings:%s\n\n' "$issues"
              fi
      ''}
    '';
  };
}
