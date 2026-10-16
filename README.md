# t3code-nix

A Nix flake for [T3 Code](https://t3.codes), built from source at upstream's
nightly tags, on `x86_64-linux` and `aarch64-linux`.

A GitHub Action checks `pingdotgg/t3code` for new `v*-nightly.*` tags every
hour. When one is out, it bumps `sources.json`, builds and runs the new
version on both architectures, pushes the build to
[cramt.cachix.org](https://cramt.cachix.org), and commits only if both pass.

## Usage

Run it once:

```sh
nix run github:cramt/t3code-nix
```

Install it from a flake with the overlay:

```nix
{
  inputs.t3code-nix = {
    url = "github:cramt/t3code-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # In your NixOS or Home Manager config:
  nixpkgs.overlays = [ inputs.t3code-nix.overlays.default ];
  home.packages = [ pkgs.t3code-desktop ];
}
```

The overlay adds two packages:

- `t3code`: the `t3` server and CLI.
- `t3code-desktop`: the electron app, `t3code-desktop`.

Neither puts any agent CLIs on `PATH`. T3 Code runs the `claude`, `codex`,
and other agents it finds on your own `PATH`.

To get cache hits with `inputs.nixpkgs.follows`, your nixpkgs must match the
one this flake was built with. Otherwise Nix builds T3 Code locally.

## Differences from upstream

The package started as the one in
[numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix), which
tracks stable tags only. This flake also patches the server so that
`T3CODE_DEV_AUTH_TOKEN` works without `--dev-url`. You can then use it as a
fixed pairing secret for a headless `t3 serve`. The token is still off unless
you set it. See `package.nix` for the reason and the removal condition.

To update by hand, run `nix run .#update`.
