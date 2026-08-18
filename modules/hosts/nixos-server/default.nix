{inputs, ...}: {
  flake.nixosConfigurations.nixos-server = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules = [
      inputs.self.modules.nixos.base
      ./_disko.nix
      ./_hardware.nix
      # Jellyfin is opt-in: uncomment to enable media serving on this host.
      # inputs.self.modules.nixos.media
    ];
  };
}
