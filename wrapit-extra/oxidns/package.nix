{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  sqlite,
  zstd,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "oxidns";
  version = "1.6.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "svenshi";
    repo = "oxidns";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BiB+dn+8eVTf31VV2M6bvhcklfvWh7r2NtOhxqk2l9s=";
  };

  cargoHash = "sha256-pssXDMTRaUwyAqC07cSMuQFs/KKei3M0eu0tuDJa5lY=";

  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A high-performance, programmable DNS engine in Rust with flexible pipeline-based routing";
    homepage = "https://github.com/svenshi/oxidns";
    license = lib.licenses.gpl3Only;
    # maintainers = with lib.maintainers; [ ];
    mainProgram = "oxidns";
  };
})
