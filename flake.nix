{
  inputs = {
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = {
    self,
    systems,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    eachSystem = f:
      lib.genAttrs (import systems) (
        system:
          f nixpkgs.legacyPackages.${system}
      );
  in {
    packages = eachSystem (pkgs @ {ocamlPackages, ...}: let
      makePkg = attrs:
        ocamlPackages.buildDunePackage ({
            version = "n/a";
            src = self.outPath;
            duneVersion = "3";
            doCheck = true;
          }
          // attrs);
    in rec {
      inotify = makePkg {
        pname = "inotify";
        buildInputs = [pkgs.inotify-tools];
        propagatedBuildInputs = with ocamlPackages; [
          base
          lwt
        ];
        checkInputs = with ocamlPackages; [
          fileutils
          ounit2
        ];
      };
      inotify-eio = makePkg {
        pname = "inotify-eio";
        buildInputs = [pkgs.inotify-tools];
        propagatedBuildInputs = with ocamlPackages; [
          inotify
          eio
          iomux
        ];
        checkInputs = with ocamlPackages; [
          fileutils
          ounit2
        ];
      };
    });

    devShells = eachSystem (pkgs @ {ocamlPackages, ...}: {
      default = pkgs.mkShell {
        inputsFrom = with self.packages.${pkgs.system}; [inotify];
        buildInputs = with ocamlPackages; [
          ocaml-lsp
          ocamlformat
          ocp-indent
          odoc
          odig
        ];
      };
      eio = pkgs.mkShell {
        inputsFrom = with self.packages.${pkgs.system}; [inotify-eio];
        buildInputs = with ocamlPackages; [
          ocaml-lsp
          ocamlformat
          ocp-indent
          odoc
          odig
        ];
      };
    });
  };
}
