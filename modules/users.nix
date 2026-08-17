{ pkgs, ... }:

{
  # Define user account 'rebiz'
  users.users.rebiz = {
    isNormalUser = true;
    description = "rebiz";
    initialPassword = "reejitbiswas"; # Initial password for user rebiz
    extraGroups = [ "wheel" "networkmanager" "docker" "storage" "video" "audio" ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CvwTALuQuiHJlkXTs2U5SKMhiu/lag3jQsbBIyHCl guardiansofspartax@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVKdJ2d/APmJOYmjZtggs39BmS1sF96wJnwoEc0ErQQ guardiansofspartax@gmail.com"
    ];
  };

  # Root user initial password and SSH keys
  users.users.root = {
    initialPassword = "reejitbiswas"; # Initial password for root
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CvwTALuQuiHJlkXTs2U5SKMhiu/lag3jQsbBIyHCl guardiansofspartax@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVKdJ2d/APmJOYmjZtggs39BmS1sF96wJnwoEc0ErQQ guardiansofspartax@gmail.com"
    ];
  };

  # Passwordless sudo for wheel group users
  security.sudo.wheelNeedsPassword = false;
}
