{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "oxidns";
  version = "1.5.2";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "SvenShi";
    repo = "oxidns";
    tag = "v${finalAttrs.version}";
    hash = "sha256-v3hkIPmwpBYa//I1R87FRgOVjdH9KQraunIsm/keTv4=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A high-performance, programmable DNS engine in Rust with flexible pipeline-based routing";
    homepage = "https://github.com/SvenShi/oxidns";
    changelog = "https://github.com/SvenShi/oxidns/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Only;
    mainProgram = "oxidns";
  };
})
