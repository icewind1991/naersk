{ cargo
, darwin
, fetchurl
, jq
, lib
, lndir
, remarshal
, rsync
, runCommandLocal
, rustc
, stdenv
, writeText
, zstd
}@defaultBuildAttrs:

let
  libb = import ./lib.nix { inherit lib writeText runCommandLocal remarshal; };

  builtinz = builtins // import ./builtins
    { inherit lib writeText remarshal runCommandLocal; };

  mkConfig = arg:
    import ./config.nix { inherit lib arg libb builtinz; };

  buildPackage = arg:
    let
      config = mkConfig arg;
      gitDependencies =
        libb.findGitDependencies { inherit (config) cargolock gitAllRefs gitSubmodules; };
      cargoconfig =
        if builtinz.pathExists (toString config.root + "/.cargo/config")
        then builtins.readFile (config.root + "/.cargo/config")
        else null;
      build = args: import ./build.nix (
        {
          inherit gitDependencies;
          version = config.packageVersion;
        } // config.buildConfig // defaultBuildAttrs // args
      );

      # the dependencies from crates.io
      buildDeps =
        build
          {
            pname = "${config.packageName}-deps";
            src = libb.dummySrc {
              inherit cargoconfig;
              inherit (config) cargolock cargotomls copySources copySourcesFrom;
            };
            inherit (config) userAttrs;
            # TODO: custom cargoTestCommands should not be needed here
            cargoTestCommands = map (cmd: "${cmd} || true") config.buildConfig.cargoTestCommands;
            copyTarget = true;
            copyBins = false;
            copyBinsFilter = ".";
            copyDocsToSeparateOutput = false;
            postInstall = false;
            builtDependencies = [];
          };

      # the top-level build
      buildTopLevel =
        let
          drv' =
            build
              {
                pname = config.packageName;
                inherit (config) userAttrs src;
                builtDependencies = lib.optional (! config.isSingleStep) buildDeps;
              };

          # If the project we're building uses CMake, let's proactively get rid
          # of `CMakeCache.txt`.
          #
          # That's because this file contains a dump of environmental variables
          # from the deps-only derivation and it could happen that the main
          # derivation uses different env-vars - when this happens, CMake will
          # fail, saying:
          #
          # ```
          # CMake Error: The current CMakeCache.txt directory ... is different than the directory ... where CMakeCache.txt was created.
          # ```
          drv = drv'.overrideAttrs (attrs: attrs // {
            preBuild = (attrs.preBuild or "") + ''
              find \
                  -name CMakeCache.txt \
                  -exec rm {} \;
            '';
          });

        in
          drv.overrideAttrs config.overrideMain;
    in
      buildTopLevel;
in
{ inherit buildPackage; }
