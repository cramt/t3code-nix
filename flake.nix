{
  description = "T3 Code, the control surface for coding agents, built from upstream nightlies";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    lib = nixpkgs.lib;
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    # The derivation has two outputs: `out` is the `t3` server/CLI, `desktop`
    # the electron app. t3code-desktop exposes the latter as its own package so
    # it can sit in home.packages with the right mainProgram.
    mkPackages = pkgs: rec {
      t3code = pkgs.callPackage ./package.nix {};
      t3code-desktop = pkgs.symlinkJoin {
        name = "t3code-desktop-${t3code.version}";
        paths = [t3code.desktop];
        meta = t3code.meta // {mainProgram = "t3code-desktop";};
      };
    };
  in {
    overlays.default = final: _prev: mkPackages final;

    packages = forAllSystems (pkgs:
      mkPackages pkgs
      // {default = self.packages.${pkgs.stdenv.hostPlatform.system}.t3code;});

    apps = forAllSystems (pkgs: {
      update = {
        type = "app";
        program = lib.getExe (pkgs.writeShellApplication {
          name = "update";
          runtimeInputs = [pkgs.curl pkgs.git pkgs.gnugrep pkgs.jq pkgs.nix];
          text = builtins.readFile ./update.sh;
        });
      };
    });

    # Bare `nix fmt` passes no paths, and alejandra then waits on stdin.
    formatter =
      forAllSystems (pkgs:
        pkgs.writeShellScriptBin "fmt" ''exec ${lib.getExe pkgs.alejandra} "''${@:-.}"'');
  };
}
