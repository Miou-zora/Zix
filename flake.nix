{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            zig
            raylib
          ];
        };
        packages.default = pkgs.stdenv.mkDerivation {
          name = "main";
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
