{ pkgs, ... }:

{
  # Fail2ban intrusion prevention for OpenSSH
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    ignoreIP = [
      "127.0.0.1/8"
      "10.42.0.0/24"
    ];
  };

  # Kernel network security sysctl tweaks
  boot.kernel.sysctl = {
    # Protection against SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;
    # Reverse path filtering for spoofing protection
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    # Ignore ICMP ping broadcast requests
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Do not accept IP source route packets
    "net.ipv4.conf.all.accept_source_route" = 0;
  };
}
