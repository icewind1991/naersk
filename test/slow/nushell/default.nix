{ sources, pkgs, ... }:
let
  fenix = import sources.fenix { };

  toolchain = fenix.fromToolchainFile {
    file = "${sources.nushell}/rust-toolchain.toml";
    sha256 = "sha256-S4dA7ne2IpFHG+EnjXfogmqwGyDFSRWFnJ8cy4KZr1k=";
  };

  naersk = pkgs.callPackage ../../../default.nix {
    cargo = toolchain;
    rustc = toolchain;
  };

  app = naersk.buildPackage {
    src = sources.nushell;

    nativeBuildInputs = with pkgs; [ pkg-config ]
      ++ lib.optional stdenv.isDarwin [ rustPlatform.bindgenHook ];

    buildInputs = with pkgs; [ openssl ]
      ++ lib.optionals stdenv.isDarwin [ zlib libiconv darwin.Libsystem darwin.Security darwin.apple_sdk.frameworks.Foundation ];
  };

in
pkgs.runCommand "nushell-test"
{
  buildInputs = [ app ];
} "nu -c 'echo yes!' && touch $out"
