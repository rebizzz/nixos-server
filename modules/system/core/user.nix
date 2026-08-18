_: {
  flake.modules.nixos.user = {
    config,
    pkgs,
    ...
  }: {
    users.mutableUsers = false;

    users.users.rebiz = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.user_password.path;
      extraGroups = ["wheel" "networkmanager" "docker" "storage" "video" "render" "audio"];
      shell = pkgs.bashInteractive;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9CvwTALuQuiHJlkXTs2U5SKMhiu/lag3jQsbBIyHCl guardiansofspartax@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVKdJ2d/APmJOYmjZtggs39BmS1sF96wJnwoEc0ErQQ guardiansofspartax@gmail.com"
      ];
    };

    users.users.root.hashedPasswordFile = config.sops.secrets.user_password.path;

    security.sudo = {
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
  };
}
