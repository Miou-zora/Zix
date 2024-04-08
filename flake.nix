{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };
  outputs = { self, nixpkgs, flake-utils, zig-overlay }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        zigPackage = zig-overlay.packages.${system}.master;
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            zigPackage
          ];
        };
        packages.default = pkgs.stdenv.mkDerivation {
          name = "Zix";
          src = ./.;

          XDG_CACHE_HOME = "${placeholder "out"}";
          buildPhase = ''
            ${pkgs.zig}/bin/zig build
          '';

          installPhase = ''
            ${pkgs.zig}/bin/zig build install --prefix $out
            rm -rf $out/zig
          '';
        };
      });
}
