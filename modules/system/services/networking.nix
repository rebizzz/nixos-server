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
    # (idProduct=c820). Auto-eject it on plug/boot instead of requiring a
    # manual `usb-modeswitch -KW`.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v 0x0bda -p 0x1a2b -V 0x0bda -P 0xc820 -K"
    '';

    environment.systemPackages = with pkgs; [
      iw
      ethtool
      usb-modeswitch
    ];
  };
}
