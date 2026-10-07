{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sni-gate";
  version = "2.5.1";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "racpast";
    repo = "sni-gate";
    tag = "v${finalAttrs.version}";
    hash = "sha256-40TGh2ESf/fVQGcyZWFoxFaEDbUIs8CfB0uSWEry8xE=";
  };

  cargoHash = "sha256-BrHwaCiTCkDTSXy7ENObVOwDtTTTjTV26UKZ3CJ8In4=";

  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Multi-listener SNI/Host-routing TLS gateway: dynamic per-SNI certificate issuance on termination, with ECH / TLS / HTTP / raw upstreams";
    homepage = "https://github.com/racpast/sni-gate";
    changelog = "https://github.com/racpast/sni-gate/releases/tag/${finalAttrs.src.tag}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ ];
    mainProgram = "sni-gate";
  };
})
