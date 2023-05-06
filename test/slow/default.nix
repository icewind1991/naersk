args: {
  agent-rs = import ./agent-rs args;
  lorri = import ./lorri args;
  ripgrep-all = import ./ripgrep-all args;
  rustlings = import ./rustlings args;
  talent-plan = import ./talent-plan args;

  # Make sure we can compile projects with a complex workspace setup
  # (https://github.com/nix-community/naersk/issues/274)
  nushell = import ./nushell args;

  # Make sure we can compile projects that use CMake
  # (https://github.com/nix-community/naersk/issues/285)
  oqs = import ./oqs args;
}
