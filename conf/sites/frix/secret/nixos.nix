{
  inputs,
  pkgs,
  ...
}:
let
  secrets = import ./secrets.nix;
in
{
  imports = [
    "${inputs.agenix}/modules/age.nix"
  ];

  environment.systemPackages = [
    (pkgs.callPackage "${inputs.agenix}/pkgs/agenix.nix" { })
  ];

  age = {
    identityPaths = [
      "/var/lib/agenix/key"
    ];

    secrets = builtins.mapAttrs (name: attrs: {
      file = ./${name};
      owner = attrs.owner or "root";
      group = attrs.group or "keys";
      mode = attrs.mode or "0440";
    }) secrets;
  };
}
