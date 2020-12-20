{
  description = "A basic flake to get a development environment going.";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gradle2nixSrc.url = "github:tadfisher/gradle2nix";
  inputs.gradle2nixSrc.flake = false;

  outputs = { self, nixpkgs, flake-utils, gradle2nixSrc }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib callPackage;

        gradle2nixTool = callPackage "${gradle2nixSrc}/default.nix" { };

        buildGradle = callPackage ./gradle-env.nix { };

        gradle2nix = buildGradle {
          envSpec = ./gradle-env.json;

          src = lib.cleanSourceWith {
            filter = lib.cleanSourceFilter;
            src = lib.cleanSourceWith {
              filter = path: type:
                let baseName = baseNameOf path;
                in !((type == "directory" && (baseName == "build" || baseName
                  == ".idea" || baseName == ".gradle"))
                  || (lib.hasSuffix ".iml" baseName));
              src = ./.;
            };
          };

          gradleFlags = [ "installDist" ];

          installPhase = ''
            mkdir -p $out
            cp -r app/build/install/gradle2nix/* $out/
          '';

          passthru = { plugin = "${gradle2nix}/share/plugin.jar"; };
        };

      in {
        devShell = import ./shell.nix { inherit pkgs; gradle2nix = gradle2nixTool; };
        packages.gradle2nix = gradle2nixTool;
        defaultPackage = gradle2nix;

      }
    );
}
