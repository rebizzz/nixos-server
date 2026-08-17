{
  description = "NixOS Flake configuration for nixos-server (Btrfs SSD + Ephemeral Root + ZFS storage array)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    preservation = {
      url = "github:nix-community/preservation";
    };
  };

  outputs = {
    nixpkgs,
    disko,
    preservation,
    ...
  } @ inputs: {
    nixosConfigurations.nixos-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        disko.nixosModules.disko
        preservation.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
