_:
{ lib, ... }:
let
  overlayType = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };
in
{
  options = {
    nixpkgs = {
      config = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = { };
        description = "The configuration for nixpkgs.";
      };
      overlays = lib.mkOption {
        type = lib.types.listOf overlayType;
        default = [ ];
        description = "Nixpkgs overlays";
      };
    };
  };
}
