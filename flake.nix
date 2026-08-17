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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    disko,
    preservation,
    sops-nix,
    ...
  } @ inputs: {
    nixosConfigurations.nixos-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        disko.nixosModules.disko
        preservation.nixosModules.default
        sops-nix.nixosModules.sops
        ./configuration.nix
      ];
    };
  };
}
