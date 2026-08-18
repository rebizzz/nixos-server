_: {
  flake.modules.nixos.motd = {pkgs, ...}: let
    motdScript = pkgs.writeShellScript "motd-dashboard" ''
      #!/bin/sh
      [ -n "$PS1" ] || [ -n "$FISH_VERSION" ] || exit 0

      c_reset="\033[0m"
      c_bold="\033[1m"
      c_cyan="\033[36m"
      c_blue="\033[34m"
      c_green="\033[32m"
      c_yellow="\033[33m"
      c_red="\033[31m"
      c_gray="\033[90m"

      pad() {
        str="$1"
        target_len=58
        clean_str=$(printf "%b" "$str" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
        visible_len=$(printf "%s" "$clean_str" | wc -m)
        pad_len=$(( target_len - visible_len ))
        if [ "$pad_len" -gt 0 ]; then
          printf "%b%*s" "$str" "$pad_len" ""
        else
          printf "%b" "$str"
        fi
      }

      draw_bar() {
        pct=$1
        filled=$(( (pct * 16) / 100 ))
        [ "$filled" -gt 16 ] && filled=16
        unfilled=$(( 16 - filled ))
        
        color="$c_green"
        [ "$pct" -ge 70 ] && color="$c_yellow"
        [ "$pct" -ge 85 ] && color="$c_red"
        
        f_str=""
        u_str=""
        for i in $(seq 1 $filled 2>/dev/null); do f_str="█$f_str"; done
        for i in $(seq 1 $unfilled 2>/dev/null); do u_str="░$u_str"; done
        printf "%b%s%b%s%b" "$color" "$f_str" "$c_gray" "$u_str" "$c_reset"
      }

      hostname="$(hostname)"
      uptime_str="$(uptime -p 2>/dev/null | sed 's/^up //')"
      [ -n "$uptime_str" ] || uptime_str="just booted"
      load_avg="$(awk '{print $1 ", " $2 ", " $3}' /proc/loadavg 2>/dev/null)"
      
      lan_ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')"
      [ -n "$lan_ip" ] || lan_ip="offline"
      
      ts_ip="$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null)"
      [ -n "$ts_ip" ] || ts_ip="disconnected"

      read -r mem_total mem_free mem_avail < <(awk '/MemTotal/{t=$2}/MemFree/{f=$2}/MemAvailable/{a=$2}END{print t,f,a}' /proc/meminfo)
      mem_used=$(( (mem_total - mem_avail) / 1024 ))
      mem_total_mb=$(( mem_total / 1024 ))
      mem_pct=0
      if [ "$mem_total_mb" -gt 0 ]; then
        mem_pct=$(( (mem_used * 100) / mem_total_mb ))
      fi

      read -r swap_total swap_free < <(awk '/SwapTotal/{t=$2}/SwapFree/{f=$2}END{print t,f}' /proc/meminfo)
      swap_used=$(( (swap_total - swap_free) / 1024 ))
      swap_total_mb=$(( swap_total / 1024 ))
      swap_pct=0
      if [ "$swap_total_mb" -gt 0 ]; then
        swap_pct=$(( (swap_used * 100) / swap_total_mb ))
      fi

      disk_root_pct=$(df / 2>/dev/null | awk 'NR==2{sub(/%/,"",$5); print $5}')
      disk_root_used=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
      disk_root_size=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')

      disk_data_pct=$(df /mnt/data 2>/dev/null | awk 'NR==2{sub(/%/,"",$5); print $5}')
      disk_data_used=$(df -h /mnt/data 2>/dev/null | awk 'NR==2{print $3}')
      disk_data_size=$(df -h /mnt/data 2>/dev/null | awk 'NR==2{print $2}')
      [ -n "$disk_data_pct" ] || disk_data_pct=0

      docker_count=0
      if command -v docker >/dev/null 2>&1; then
        docker_count=$(docker ps -q 2>/dev/null | wc -l)
      fi

      issues=""
      failed=$(systemctl --failed --no-legend --plain 2>/dev/null | wc -l)
      if [ "$failed" -gt 0 ]; then
        issues="$issues\n  $c_red✗ $failed failed systemd unit(s) (systemctl --failed)$c_reset"
      fi

      pool_health=$(zpool list -H -o health data 2>/dev/null)
      if [ -n "$pool_health" ] && [ "$pool_health" != "ONLINE" ]; then
        issues="$issues\n  $c_red✗ ZFS pool 'data' is $pool_health (zpool status data)$c_reset"
      fi

      last_upgrade=$(systemctl show nixos-upgrade.service -p Result --value 2>/dev/null)
      if [ -n "$last_upgrade" ] && [ "$last_upgrade" != "success" ] && [ "$last_upgrade" != "" ]; then
        issues="$issues\n  $c_yellow! Last auto-upgrade: $last_upgrade (journalctl -u nixos-upgrade)$c_reset"
      fi

      printf "\n"
      printf "%b╭──────────────────────────────────────────────────────────╮%b\n" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bSystem:%b      %b%b%s%b %b(NixOS 26.05 x86_64)%b" "$c_gray" "$c_reset" "$c_bold" "$c_cyan" "$hostname" "$c_reset" "$c_gray" "$c_reset")")" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bUptime:%b      %s" "$c_gray" "$c_reset" "$uptime_str")")" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bLoad:%b        %s" "$c_gray" "$c_reset" "$load_avg")")" "$c_blue" "$c_reset"
      printf "%b├──────────────────────────────────────────────────────────┤%b\n" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bLAN IP:%b      %b%s%b" "$c_gray" "$c_reset" "$c_green" "$lan_ip" "$c_reset")")" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bTailscale:%b   %b%s%b" "$c_gray" "$c_reset" "$c_yellow" "$ts_ip" "$c_reset")")" "$c_blue" "$c_reset"
      printf "%b├──────────────────────────────────────────────────────────┤%b\n" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bRAM:%b         [%b] %4dM / %-4dM (%2d%%)" "$c_gray" "$c_reset" "$(draw_bar "$mem_pct")" "$mem_used" "$mem_total_mb" "$mem_pct")")" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bSwap:%b        [%b] %4dM / %-4dM (%2d%%)" "$c_gray" "$c_reset" "$(draw_bar "$swap_pct")" "$swap_used" "$swap_total_mb" "$swap_pct")")" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bSSD (/):%b     [%b] %5s / %-5s (%2d%%)" "$c_gray" "$c_reset" "$(draw_bar "$disk_root_pct")" "$disk_root_used" "$disk_root_size" "$disk_root_pct")")" "$c_blue" "$c_reset"
      if [ -n "$disk_data_used" ]; then
        printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bZFS (data):%b  [%b] %5s / %-5s (%2d%%)" "$c_gray" "$c_reset" "$(draw_bar "$disk_data_pct")" "$disk_data_used" "$disk_data_size" "$disk_data_pct")")" "$c_blue" "$c_reset"
      fi
      printf "%b├──────────────────────────────────────────────────────────┤%b\n" "$c_blue" "$c_reset"
      printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%bDocker:%b      %d container(s) running" "$c_gray" "$c_reset" "$docker_count")")" "$c_blue" "$c_reset"
      if [ -z "$issues" ]; then
        printf "%b│%b  %s  %b│%b\n" "$c_blue" "$c_reset" "$(pad "$(printf "%b✓ System, drives & ZFS pools healthy%b" "$c_green" "$c_reset")")" "$c_blue" "$c_reset"
      fi
      printf "%b╰──────────────────────────────────────────────────────────╯%b\n" "$c_blue" "$c_reset"

      if [ -n "$issues" ]; then
        printf "%b\n\n" "$issues"
      else
        printf "\n"
      fi
    '';
  in {
    environment.interactiveShellInit = "${motdScript}";
    programs.fish.interactiveShellInit = "${motdScript}";
  };
}
