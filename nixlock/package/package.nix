{
  lib,
  rustPlatform,
}:
let
  src-rust = ../src-rust;
  cargo = lib.importTOML (src-rust + "/Cargo.toml");
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = cargo.package.name;
  version = cargo.package.version;

  src = lib.fileset.toSource {
    root = src-rust;
    fileset = lib.fileset.unions (
      map (v: src-rust + v) [
        "/src"
        "/Cargo.lock"
        "/Cargo.toml"
      ]
    );
  };

  cargoLock = {
    lockFile = src-rust + "/Cargo.lock";
  };

  meta = {
    mainProgram = cargo.package.name;
    description = "Simple prefetech tool";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
  };
})
