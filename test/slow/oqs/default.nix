{ sources, pkgs, ... }:
let
  fenix = import sources.fenix { };

  toolchain = fenix.fromToolchainFile {
    file = ./app/rust-toolchain.toml;
    sha256 = "sha256-Y2DBRMR6w4fJu+jwplWInTBzNtbr0EW3yZ3CN9YTI/8=";
  };

  naersk = pkgs.callPackage ../../../default.nix {
    cargo = toolchain;
    rustc = toolchain;
  };

  attrs = {
    src = ./app;
    nativeBuildInputs = with pkgs; [ rustPlatform.bindgenHook cmake pkg-config ];
    buildInputs = with pkgs; [ openssl ];
  };

  app = naersk.buildPackage attrs;

  app-single-step = naersk.buildPackage (attrs // {
    singleStep = true;
  });

in
pkgs.runCommand "oqs-test" { } ''
  ${app}/bin/app
  ${app-single-step}/bin/app
  touch $out
''
