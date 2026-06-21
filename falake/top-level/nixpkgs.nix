{ nixpkgs }:
{
  debug,
  options,
  config,
  lib,
  ...
}:
{
  _class = "falake";

  options = {
    debug = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Show debug info.
      '';
    };

    nixpkgs = {
      src = lib.mkOption {
        default = "${nixpkgs}";
        defaultText = "<nixpkgs>";
        readOnly = true;
        type = lib.types.path;
        description = ''
          Path to nixpkgs.

          By default, the value <nixpkgs> used is impure.
          If you want to do a pure evaluation, don't set this option directly; instead,
          set `nixpkgs` in the initialization function `mkFalake`.
        '';
      };

      config = lib.mkOption {
        default = { };
        example = lib.literalExpression ''
          { allowBroken = true; allowUnfree = true; }
        '';
        type =
          let
            optCall = f: x: if lib.isFunction f then f x else f;

            mergeConfig =
              lhs: rhs:
              lib.recursiveUpdate lhs rhs
              // lib.optionalAttrs (lhs ? allowUnfreePackages) {
                allowUnfreePackages = lhs.allowUnfreePackages ++ (lib.attrByPath [ "allowUnfreePackages" ] [ ] rhs);
              }
              // lib.optionalAttrs (lhs ? packageOverrides) {
                packageOverrides =
                  pkgs:
                  optCall lhs.packageOverrides pkgs // optCall (lib.attrByPath [ "packageOverrides" ] { } rhs) pkgs;
              }
              // lib.optionalAttrs (lhs ? perlPackageOverrides) {
                perlPackageOverrides =
                  pkgs:
                  optCall lhs.perlPackageOverrides pkgs
                  // optCall (lib.attrByPath [ "perlPackageOverrides" ] { } rhs) pkgs;
              };
          in
          lib.mkOptionType {
            name = "nixpkgs-config";
            description = "nixpkgs config";
            check = x: if builtins.isAttrs x then true else lib.traceSeqN 1 x false;
            merge = args: lib.foldr (def: mergeConfig def.value) { };
          };
        description = ''
          Global configuration for Nixpkgs.
          The complete list of [Nixpkgs configuration options](https://nixos.org/manual/nixpkgs/unstable/#sec-config-options-reference) is in the [Nixpkgs manual section on global configuration](https://nixos.org/manual/nixpkgs/unstable/#chap-packageconfig).
        '';
      };

      overlays = lib.mkOption {
        default = [ ];
        type = lib.types.listOf (
          lib.mkOptionType {
            name = "nixpkgs-overlay";
            description = "nixpkgs overlay";
            check = lib.isFunction;
            merge = lib.mergeOneOption;
          }
        );
        description = ''
          List of overlays to apply to Nixpkgs.
          This option allows modifying the Nixpkgs package set accessed through the `pkgs` module argument.

          For details, see the [Overlays chapter in the Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/#chap-overlays).

          If the {option}`nixpkgs.pkgs` option is set, overlays specified using `nixpkgs.overlays` will be applied after the overlays that were already included in `nixpkgs.pkgs`.
        '';
      };
    };

    allSystems = lib.mkOption {
      default = { };
      type = lib.types.lazyAttrsOf (
        lib.types.submoduleWith {
          class = "systems";
          specialArgs = {
            topOptions = options;
            topConfig = config;
          };
          modules = lib.singleton (
            {
              name,
              topOptions,
              topConfig,
              config,
              lib,
              ...
            }:
            {
              options = {
                name = lib.mkOption {
                  default = name;
                  type = lib.types.str;
                  description = "The names used in functions like `perSystem` and `withSystem`";
                };

                hostPlatform = lib.mkOption {
                  default = name;
                  example = {
                    system = "aarch64-linux";
                  };
                  # Make sure that the final value has all fields for sake of other modules
                  # referring to this. TODO make `lib.systems` itself use the module system.
                  apply = lib.systems.elaborate;
                  description = ''
                    Specifies the platform where the NixOS configuration will run.

                    To cross-compile, set also `nixpkgs.buildPlatform`.
                  '';
                };

                buildPlatform = lib.mkOption {
                  default = config.hostPlatform;
                  type = lib.types.either lib.types.str lib.types.attrs;
                  example = {
                    system = "x86_64-linux";
                  };
                  apply =
                    inputBuildPlatform:
                    let
                      elaborated = lib.systems.elaborate inputBuildPlatform;
                    in
                    if lib.systems.equals elaborated config.hostPlatform then
                      config.hostPlatform # make identical, so that `==` equality works; see https://github.com/NixOS/nixpkgs/issues/278001
                    else
                      elaborated;
                  defaultText = lib.literalExpression "config.nixpkgs.hostPlatform";
                  description = ''
                    Specifies the platform on which NixOS should be built.
                    By default, NixOS is built on the system where it runs, but you can
                    change where it's built. Setting this option will cause NixOS to be
                    cross-compiled.

                    For instance, if you're doing distributed multi-platform deployment,
                    or if you're building machines, you can set this to match your
                    development system and/or build farm.
                  '';
                };

                inheritTop = lib.mkOption {
                  default = true;
                  type = lib.types.bool;
                  description = "Whether to inherit `overlays` and `config` from the top";
                };

                overlays = topOptions.nixpkgs.overlays;
                config = topOptions.nixpkgs.config;
              };

              config = lib.mkIf config.inheritTop {
                overlays = lib.mkOrder 200 topConfig.nixpkgs.overlays;
                config = topConfig.nixpkgs.config;
              };
            }
          );
        }
      );
      apply = lib.mapAttrs (
        n: v:
        let
          isCross = !(v.buildPlatform == v.hostPlatform);

          systemArgs =
            if isCross then
              {
                localSystem = v.buildPlatform;
                crossSystem = v.hostPlatform;
              }
            else
              {
                localSystem = v.hostPlatform;
              };

          pkgs = debug {
            info = ''
              Falake: Evaluate a nixpkgs instance! System: "${v.name}"
            '';
            return = import "${config.nixpkgs.src}/pkgs/top-level" (
              systemArgs
              // {
                inherit (v)
                  overlays
                  config
                  ;
              }
            );
          };
        in
        v
        // {
          __toString = v.name;
          inherit pkgs;
        }
      );
      description = ''
        All the system types to enumerate in the flake output subattributes.
      '';
    };
  };

  config = {
    _module.args = {
      debug =
        {
          info,
          return,
          ...
        }:
        if config.debug then builtins.trace info return else return;
    };
  };
}
