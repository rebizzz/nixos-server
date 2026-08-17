{ pkgs, ... }:

{
  # Enforce immutable users via NixOS declarative config
  users.mutableUsers = false;

  # User account 'rebiz'
  users.users.rebiz = {
    isNormalUser = true;
    description = "rebiz";
    hashedPassword = "$6$9Ff3D.TpYGvU6kBi$4xo1PNdGEw73Jhxd5ZeWXuAFracabCiLWlSGwP1gQf.Uz1JA4hRDW0wgJvBvF7my7aZn5CiIg8p9.F37yvRGR1"; # Password: reejitbiswas
    extraGroups = [ "wheel" "networkmanager" "docker" "storage" "video" "audio" ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CvwTALuQuiHJlkXTs2U5SKMhiu/lag3jQsbBIyHCl guardiansofspartax@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVKdJ2d/APmJOYmjZtggs39BmS1sF96wJnwoEc0ErQQ guardiansofspartax@gmail.com"
    ];
  };

  # Root user configuration
  users.users.root = {
    hashedPassword = "$6$9Ff3D.TpYGvU6kBi$4xo1PNdGEw73Jhxd5ZeWXuAFracabCiLWlSGwP1gQf.Uz1JA4hRDW0wgJvBvF7my7aZn5CiIg8p9.F37yvRGR1"; # Password: reejitbiswas
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CvwTALuQuiHJlkXTs2U5SKMhiu/lag3jQsbBIyHCl guardiansofspartax@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVKdJ2d/APmJOYmjZtggs39BmS1sF96wJnwoEc0ErQQ guardiansofspartax@gmail.com"
    ];
  };

  # Passwordless sudo for wheel group users
  security.sudo.wheelNeedsPassword = false;
}
