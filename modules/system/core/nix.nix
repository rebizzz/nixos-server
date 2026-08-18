_: {
  flake.modules.nixos.nix = _: {
    nix = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        trusted-users = ["root" "@wheel"];
        allowed-users = ["*"];
        warn-dirty = false;
        min-free = 5 * 1024 * 1024 * 1024; # 5 GiB minimum free before GC kicks in
        max-free = 25 * 1024 * 1024 * 1024; # 25 GiB target after GC
      };
      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
    };
  };
}
