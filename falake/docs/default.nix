let
  nixpkgs = <nixpkgs>;
  pkgs = import <nixpkgs> { };

  result = (import ../default.nix).lib.eval {
    inherit nixpkgs;
    module = { lib, ... }: {
      options = {
        _module.args = lib.mkOption {
          internal = true;
        };
      };
    };
  };

  docsOptRaw =
    builtins.readFile
      (pkgs.nixosOptionsDoc {
        options = result.options;
      }).optionsCommonMark;

  docsOpt =
    builtins.replaceStrings
      [
        "file://${toString ../.}/"
        "${toString ../.}/"
      ]
      [
        "../"
        ""
      ]
      docsOptRaw;

  docs = builtins.toFile "options.md" docsOpt;
in
pkgs.mkShellNoCC {
  shellHook = ''
    cp -f ${docs} ./options.md
    exit
  '';
}
