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
          backend = "wpa_supplicant";
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
      # host keys survive the ephemeral root wipe so reboots don't re-key the box
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
        # rebiz already has full passwordless sudo, so a second privileged
        # SSH entry point (root) and a password-guessable one both just add
        # attack surface without adding capability.
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
      };
    };

    # The Wi-Fi dongle boots into a factory CD-ROM mode (0bda:1a2b) instead
    # of NIC mode (0bda:c820). usb-modeswitch-data's bundled config for this
    # ID targets a different device, so override the target below. Don't
    # switch this udev rule to call usb_modeswitch directly (RUN+=) instead
    # of the async dispatcher: a direct call blocks udev for several seconds
    # and has previously hard-reset the box by missing the boot watchdog.
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

    # NM autoconnect doesn't reliably bring "ReBiz" up on its own: a known
    # upstream race between ensure-profiles and NM's init (nixpkgs#296450).
    # Automate the documented workaround (`nmcli connection up`).
    systemd.services.wifi-autoconnect = {
      description = "Ensure the wifi connection comes up (NM autoconnect workaround)";
      after = ["NetworkManager.service"];
      serviceConfig = {
        Type = "oneshot";
        # bash builtins only, no awk/grep/cut: systemd services get a minimal PATH
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
