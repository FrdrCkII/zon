let
  source = (import ./channels.nix).locked.kernel-patches;
in
{ fetchzip }:
fetchzip {
  inherit (source) url hash;
}
