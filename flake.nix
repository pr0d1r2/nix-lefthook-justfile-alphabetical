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
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      lib = set-and-setting.lib // {
        # nixpkgs' sourceByRegex now requires a list of regexes, while the
        # pinned actionlint helper still supplies one scalar regex.
        mkActionlintCheck =
          args:
          set-and-setting.lib.mkLefthookCheck {
            inherit (args) pkgs;
            src = args.pkgs.lib.sources.sourceByRegex args.src [ "^\\.github/workflows/.*" ];
            wrapper = args.pkgs.writeShellApplication {
              name = "actionlint-check";
              runtimeInputs = [ args.pkgs.actionlint ];
              text = ''
                actionlint "$@"
              '';
            };
            name = args.name or "actionlint";
            suffices = [
              ".yml"
              ".yaml"
            ];
            checkFlag = "";
          };
        checksFor =
          {
            pkgs,
            src,
            fragments,
          }:
          import "${set-and-setting}/lib/checks-for.nix" {
            inherit pkgs src fragments;
            inherit (set-and-setting.lib)
              mkNixfmtCheck
              mkShfmtCheck
              mkTrailingWhitespaceCheck
              mkMissingFinalNewlineCheck
              mkEditorconfigCheckerCheck
              mkShellcheckCheck
              mkNoShellFunctionsCheck
              mkAsciiOnlyCheck
              mkTyposCheck
              mkStatixCheck
              mkDeadnixCheck
              mkNixNoEmbeddedShellCheck
              mkFlakeManifestCheck
              mkGitleaksCheck
              mkGitConflictMarkersCheck
              mkGitNoLocalPathsCheck
              mkExecutePermissionsCheck
              mkFileSizeCheckCheck
              mkLinterCoverageCheck
              ;
            mkActionlintCheck =
              args:
              set-and-setting.lib.mkLefthookCheck {
                inherit (args) pkgs;
                src = args.pkgs.lib.sources.sourceByRegex args.src [ "^\\.github/workflows/.*" ];
                wrapper = args.pkgs.writeShellApplication {
                  name = "actionlint-check";
                  runtimeInputs = [ args.pkgs.actionlint ];
                  text = ''
                    actionlint "$@"
                  '';
                };
                name = args.name or "actionlint";
                suffices = [
                  ".yml"
                  ".yaml"
                ];
                checkFlag = "";
              };
          };
      };
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
    // {
      # The unit tests call the wrapper by name, and mkConsumerFlake does
      # not add consumer packages to the shell, so every devShell must put
      # the packaged wrapper on PATH. The pinned standard's
      # lefthook-actionlint wrapper lacks actionlint in its runtimeInputs
      # (fixed upstream), so the pre-push actionlint hook needs it here
      # until the set-and-setting pin moves past that fix.
      devShells =
        builtins.mapAttrs
          (
            system: shells:
            builtins.mapAttrs (
              _name: shell:
              shell.overrideAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  self.packages.${system}.default
                  nixpkgs.legacyPackages.${system}.actionlint
                ];
              })
            ) shells
          )
          (set-and-setting.lib.mkConsumerFlake {
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
          }).devShells;
    };
}
