_: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      name = "nixos-server-devshell";
      packages = with pkgs; [
        alejandra
        nh
        nix-output-monitor
        nvd
        sops
        age
        ssh-to-age
        git
      ];
      shellHook = ''
        export NH_FLAKE="$(pwd)"
      '';
    };
  };
}
