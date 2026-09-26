{
  description = "Lefthook-compatible justfile alphabetical check";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting = {
      url = "github:pr0d1r2/set-and-setting";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-lock.follows = "nixpkgs-lock";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    (
      consumer:
      consumer
      // {
        # The unit tests call the wrapper by name, and the standard's
        # pre-push bats-unit hook runs them inside the devShell.
        # mkConsumerFlake does not add consumer packages to the shell, so
        # put the packaged wrapper first on PATH.
        devShells = builtins.mapAttrs (
          system: shells:
          builtins.mapAttrs (
            _name: shell:
            shell.overrideAttrs (old: {
              nativeBuildInputs = [
                self.packages.${system}.default
              ]
              ++ (old.nativeBuildInputs or [ ]);
            })
          ) shells
        ) consumer.devShells;
      }
    )
      (
        set-and-setting.lib.mkConsumerFlake {
          inherit self nixpkgs set-and-setting;
          fragments = [
            "base"
            "actions"
            "nix"
            "shell"
            "ascii"
            "markdown"
            "yaml"
          ];
          src = ./.;
          extraPackages = pkgs: {
            default = pkgs.writeShellApplication {
              name = "lefthook-justfile-alphabetical";
              runtimeInputs = [
                pkgs.gawk
                pkgs.coreutils
              ];
              text = ''
                AWK_PROGRAM="${./justfile-alphabetical.awk}"
              ''
              + builtins.readFile ./lefthook-justfile-alphabetical.sh;
            };
          };
          extraChecks = pkgs: {
            package = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          };
        }
      );
}
