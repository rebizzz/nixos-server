{ pkgs, ... }:

{
  users.mutableUsers = false;

  users.users.rebiz = {
    isNormalUser = true;
    hashedPassword = "$6$9Ff3D.TpYGvU6kBi$4xo1PNdGEw73Jhxd5ZeWXuAFracabCiLWlSGwP1gQf.Uz1JA4hRDW0wgJvBvF7my7aZn5CiIg8p9.F37yvRGR1";
    extraGroups = [ "wheel" "networkmanager" "docker" "storage" "video" "render" "audio" ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CvwTALuQuiHJlkXTs2U5SKMhiu/lag3jQsbBIyHCl guardiansofspartax@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVKdJ2d/APmJOYmjZtggs39BmS1sF96wJnwoEc0ErQQ guardiansofspartax@gmail.com"
    ];
  };

  users.users.root = {
    hashedPassword = "$6$9Ff3D.TpYGvU6kBi$4xo1PNdGEw73Jhxd5ZeWXuAFracabCiLWlSGwP1gQf.Uz1JA4hRDW0wgJvBvF7my7aZn5CiIg8p9.F37yvRGR1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CvwTALuQuiHJlkXTs2U5SKMhiu/lag3jQsbBIyHCl guardiansofspartax@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVKdJ2d/APmJOYmjZtggs39BmS1sF96wJnwoEc0ErQQ guardiansofspartax@gmail.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
