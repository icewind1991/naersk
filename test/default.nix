{ system, fast, nixpkgs }:
let
  sources = import ../nix/sources.nix;

  pkgs =
    let
      pkgs' = import ../nix {
        inherit system nixpkgs;
      };

      older-pkgs = import ../nix {
        inherit system;

        nixpkgs = "nixpkgs-21.05";
      };

    in
    pkgs' // {
      # HACK Some of our tests here manually construct a Git repository which
      #      newer Git versions have a problem with, saying:
      #
      # > fatal: detected dubious ownership in repository at '/nix/store/...'
      # > To add an exception for this directory, call:
      # >
      # >     git config --global --add safe.directory /nix/store/...
      #
      # Unfortunately, adding an exception doesn't really seem to work and so
      # for the testing purposes here we default to the older Git.
      #
      # Another approach would be to patch Git (commenting out that warning),
      # but then `./script/test --nixpkgs ...` would stop working (since that
      # patch wouldn't be applicable to the older Git versions).
      git = older-pkgs.git;
    };

  naersk = pkgs.callPackage ../default.nix {
    inherit (pkgs.rustPackages) cargo rustc;
  };

  args = {
    inherit sources pkgs naersk;
  };

  fastTests = import ./fast args;
  slowTests = import ./slow args;

  # Because `nix-build` doesn't recurse into attribute sets, some of our more
  # nested tests (e.g. `fastTests.foo.bar`) normally wouldn't be executed.
  #
  # To avoid that, we're recursively flattening all tests into a list, which
  # `nix-build` then evaluates in its entirety.
  runTests = tests:
    pkgs.lib.collect pkgs.lib.isDerivation tests;

in
runTests (
  fastTests // pkgs.lib.optionalAttrs (!fast) slowTests
)
