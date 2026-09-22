{
  lib,
  rustPlatform,
}:
let
  src-rust = ../.;
  cargo = lib.importTOML (src-rust + /Cargo.toml);
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = cargo.workspace.package.name;
  version = cargo.workspace.package.version;

  src = lib.fileset.toSource {
    root = src-rust;
    fileset = lib.fileset.unions [
      (src-rust + /crates)
      (src-rust + /main-bin)
      (src-rust + /Cargo.toml)
      (src-rust + /Cargo.lock)
    ];
  };

  cargoLock = {
    lockFile = src-rust + "/Cargo.lock";
  };

  meta = {
    mainProgram = cargo.workspace.package.name;
    description = "Frederick's nix project build tools collect";
    license = lib.licenses.eupl12;
    platforms = lib.platforms.unix;
  };
})
