{inputs, ...}: let
  hostVars = import ./_host.nix {};
in {
  flake.nixosConfigurations.${hostVars.hostName} = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs hostVars;};
    modules = [
      inputs.self.modules.nixos.base
      ./_disko.nix
      ./_hardware.nix
      # Jellyfin is opt-in: uncomment to enable media serving on this host.
      # inputs.self.modules.nixos.media
    ];
  };

  flake.deploy.nodes.${hostVars.hostName} = {
    hostname = "${hostVars.hostName}.local";
    sshUser = "rebiz";
    sshOpts = ["-o" "StrictHostKeyChecking=accept-new"];
    fastConnection = true;
    autoRollback = true;
    magicRollback = true;
    profiles.system = {
      user = "root";
      path =
        inputs.deploy-rs.lib.x86_64-linux.activate.nixos
        inputs.self.nixosConfigurations.${hostVars.hostName};
    };
  };
}
