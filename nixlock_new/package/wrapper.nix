{
  lib,
  stdenvNoCC,
  makeBinaryWrapper,
  nixlock-unwrapped,
}:
let
  src-nix = ../src-nix;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit (nixlock-unwrapped) name version meta;

  allowSubstitute = false;
  allowSubstitutes = false;
  preferLocalBuild = true;
  enableParallelBuilding = true;
  outputs = [ "out" ];

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  buildInputs = [
    nixlock-unwrapped
  ];

  buildCommand = ''
    mkdir --parents $out/bin

    makeBinaryWrapper \
      ${lib.getExe nixlock-unwrapped} $out/bin/nixlock \
      --set-default NIXLOCK_NIX_PATH ${finalAttrs.passthru.src-nix} \
      --inherit-argv0
  '';

  passthru = {
    src-nix = src-nix;
  };
})
