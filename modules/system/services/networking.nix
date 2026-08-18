_: {
  flake.modules.nixos.networking = {
    config,
    pkgs,
    ...
  }: {
    networking = {
      hostName = "nixos-server";
      networkmanager = {
        enable = true;
        wifi = {
          powersave = false;
          backend = "iwd";
        };
        ensureProfiles = {
          environmentFiles = [config.sops.templates."network-manager.env".path];
          profiles.ReBiz = {
            connection = {
              id = "ReBiz";
              type = "wifi";
              autoconnect = true;
              autoconnect-priority = 100;
            };
            wifi = {
              mode = "infrastructure";
              ssid = "ReBiz";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PSK";
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };
        };
      };
      firewall = {
        enable = true;
        allowedTCPPorts = [22 9090];
        allowedUDPPorts = [5353];
        trustedInterfaces = ["tailscale0"];
        checkReversePath = "loose";
      };
    };

    # NM's iwd wifi.backend talks to the system iwd daemon over D-Bus instead
    # of spawning wpa_supplicant per-device; iwd must actually be running.
    networking.wireless.iwd.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
      };
      openFirewall = true;
    };

    services.openssh = {
      enable = true;
      # Host keys must survive the ephemeral root wipe, or every reboot re-keys
      # the box and every client sees a "man in the middle" warning.
      hostKeys = [
        {
          path = "/persistent/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persistent/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
      };
    };

    # The Wi-Fi dongle (Realtek, idVendor=0bda) boots into its factory CD-ROM
    # install-driver mode (idProduct=1a2b) instead of the real NIC mode
    # (idProduct=c820), previously requiring a manual `usb-modeswitch -KW`.
    #
    # usb-modeswitch-data ships a udev rule for this exact ID, but its bundled
    # config targets a different device (a D-Link dongle that shares the same
    # generic Realtek CD-mode ID) — override it with the real target here.
    # The udev rule dispatches asynchronously via `systemctl --no-block start
    # usb_modeswitch@.service`; do NOT replace this with a udev RUN+= that
    # calls usb_modeswitch directly — that blocks the udev worker for the
    # several seconds the eject/re-enumeration takes, which on this box's
    # already-busy boot (ZFS import + docker + sops) is long enough to miss
    # the 30s hardware watchdog ping and hard-reset the machine mid-boot.
    services.udev.packages = with pkgs; [usb-modeswitch-data usb-modeswitch];
    systemd.packages = [pkgs.usb-modeswitch];
    environment.etc."usb_modeswitch.d/0bda:1a2b".text = ''
      DefaultVendor=0x0bda
      DefaultProduct=0x1a2b
      TargetVendor=0x0bda
      TargetProduct=0xc820
      StandardEject=1
    '';

    environment.systemPackages = with pkgs; [
      iw
      ethtool
      usb-modeswitch
    ];

    # NetworkManager's own autoconnect policy reliably fails to bring the
    # declarative "ReBiz" profile up after boot/restart (confirmed via debug
    # logs: it scans successfully every cycle but never proceeds past
    # 'autoactivate' — only an explicit `nmcli connection up` clears it).
    # This is a known, still-open upstream race between
    # NetworkManager-ensure-profiles.service and NM's own init/autoconnect
    # pass (NixOS/nixpkgs#296450) — the documented workaround is exactly
    # `nmcli connection reload`/`up` after boot, so automate that instead of
    # waiting on an upstream fix.
    systemd.services.wifi-autoconnect = {
      description = "Ensure the wifi connection comes up (NM autoconnect workaround)";
      after = ["NetworkManager.service"];
      serviceConfig = {
        Type = "oneshot";
        # systemd services get a minimal PATH, so stick to bash builtins —
        # no awk/grep/cut — plus nmcli's absolute store path.
        #
        # Retries every 1s for up to 30s instead of waiting out a single
        # fixed delay: NM/iwd aren't ready the instant the timer fires, so a
        # tight retry loop converges as fast as the hardware actually allows
        # instead of just moving the fixed wait earlier.
        ExecStart = pkgs.writeShellScript "wifi-autoconnect" ''
          is_connected() {
            connected=0
            while IFS=: read -r type state _; do
              if [ "$type" = wifi ] && [ "$state" = connected ]; then
                connected=1
              fi
            done < <(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE device status)
            [ "$connected" = 1 ]
          }
          for _ in $(seq 1 30); do
            is_connected && exit 0
            ${pkgs.networkmanager}/bin/nmcli connection up ReBiz >/dev/null 2>&1 || true
            is_connected && exit 0
            sleep 1
          done
        '';
      };
    };

    systemd.timers.wifi-autoconnect = {
      description = "Periodically ensure the wifi connection is up";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1s";
        OnUnitActiveSec = "1min";
        Unit = "wifi-autoconnect.service";
      };
    };
  };
}
