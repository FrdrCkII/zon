## allPkgs

The system-specific config for each of systems\.



*Type:*
attribute set of unspecified value *(read only)*



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## allSystems



The system-specific config for each of systems\.



*Type:*
lazy attribute set of unspecified value *(read only)*



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/perSystem\.nix](../top-level/perSystem.nix)



## evalSystems



The system-specific evaluation for each of systems\.



*Type:*
lazy attribute set of unspecified value *(read only)*



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/perSystem\.nix](../top-level/perSystem.nix)



## nixpkgs\.config



The configuration for nixpkgs\.



*Type:*
attribute set of unspecified value



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## nixpkgs\.overlays



Nixpkgs overlays



*Type:*
list of (nixpkgs overlay)



*Default:*

```nix
[ ]
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## nixpkgs\.src



Path to nixpkgs



*Type:*
absolute path



*Default:*

```nix
/run/current-system/inputs/nixpkgs
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## out



The ` outputs ` option after removing duplicates



*Type:*
attribute set *(read only)*



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/outputs\.nix](../top-level/outputs.nix)



## outputs



Raw flake output attributes\. Any attribute can be set here, but some
attributes are represented by options, to provide appropriate
configuration merging\.



*Type:*
open submodule of lazy attribute set of raw value



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/outputs\.nix](../top-level/outputs.nix)



## outputs\.packages



See ` perSystem.packages ` for description and examples\.



*Type:*
lazy attribute set of lazy attribute set of package



*Default:*

```nix
{ }
```

*Declared by:*
 - [perSystem/packages\.nix](../perSystem/packages.nix)



## outputs\.apps



See ` perSystem.apps ` for description and examples\.



*Type:*
lazy attribute set of lazy attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [perSystem/apps\.nix](../perSystem/apps.nix)



## outputs\.apps\.\<system>\.\<name>\.meta



Metadata information about the app\.
Standardized in Nix at [https://github\.com/NixOS/nix/pull/11297](https://github\.com/NixOS/nix/pull/11297)\.

Note: ` nix flake check ` is only aware of the ` description ` attribute in ` meta `\.



*Type:*
lazy attribute set of raw value



*Default:*

```nix
{ }
```

*Declared by:*
 - [perSystem/apps\.nix](../perSystem/apps.nix)



## outputs\.apps\.\<system>\.\<name>\.program



A path to an executable or a derivation with ` meta.mainProgram `\.



*Type:*
string or package convertible to it

*Declared by:*
 - [perSystem/apps\.nix](../perSystem/apps.nix)



## outputs\.apps\.\<system>\.\<name>\.type



A type tag for ` apps ` consumers\.



*Type:*
value “app” (singular enum)



*Default:*

```nix
"app"
```

*Declared by:*
 - [perSystem/apps\.nix](../perSystem/apps.nix)



## outputs\.checks



See ` perSystem.checks ` for description and examples\.



*Type:*
lazy attribute set of lazy attribute set of package



*Default:*

```nix
{ }
```

*Declared by:*
 - [perSystem/checks\.nix](../perSystem/checks.nix)



## outputs\.devShells



See ` perSystem.devShells ` for description and examples\.



*Type:*
lazy attribute set of lazy attribute set of package



*Default:*

```nix
{ }
```

*Declared by:*
 - [perSystem/devShells\.nix](../perSystem/devShells.nix)



## outputs\.formatter



See ` perSystem.formatter ` for description and examples\.



*Type:*
lazy attribute set of (null or package)



*Default:*

```nix
{ }
```

*Declared by:*
 - [perSystem/formatter\.nix](../perSystem/formatter.nix)



## outputs\.legacyPackages



See ` perSystem.legacyPackages ` for description and examples\.



*Type:*
lazy attribute set of lazy attribute set of raw value



*Default:*

```nix
{ }
```

*Declared by:*
 - [perSystem/legacyPackages\.nix](../perSystem/legacyPackages.nix)



## outputs\.nixosConfigurations



Instantiated NixOS configurations\. Used by ` nixos-rebuild `\.

` nixosConfigurations ` is for specific machines\. If you want to expose
reusable configurations, add them to [` nixosModules `](\#opt-flake\.nixosModules)
in the form of modules (no ` lib.nixosSystem `), so that you can reference
them in this or another flake’s ` nixosConfigurations `\.



*Type:*
lazy attribute set of raw value



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  my-machine = inputs.nixpkgs.lib.nixosSystem {
    # system is not needed with freshly generated hardware-configuration.nix
    # system = "x86_64-linux";  # or set nixpkgs.hostPlatform in a module.
    modules = [
      ./my-machine/nixos-configuration.nix
      config.nixosModules.my-module
    ];
  };
}

```

*Declared by:*
 - [outputs/nixosConfigurations\.nix](../outputs/nixosConfigurations.nix)



## outputs\.nixosModules



NixOS modules\.

You may use this for reusable pieces of configuration, service modules, etc\.



*Type:*
lazy attribute set of module



*Default:*

```nix
{ }
```

*Declared by:*
 - [outputs/nixosModules\.nix](../outputs/nixosModules.nix)



## outputs\.overlays



An attribute set of [overlays](https://nixos\.org/manual/nixpkgs/stable/\#chap-overlays)\.

Note that the overlays themselves are not mergeable\. While overlays
can be composed, the order of composition is significant, but the
module system does not guarantee sufficiently deterministic
definition ordering, across versions and when changing ` imports `\.



*Type:*
lazy attribute set of function that evaluates to a(n) function that evaluates to a(n) lazy attribute set of unspecified value



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  default = final: prev: {};
}

```

*Declared by:*
 - [outputs/overlays\.nix](../outputs/overlays.nix)



## perSystem



A function from system to flake-like attributes omitting the ` <system> ` attribute\.



*Type:*
module



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/perSystem\.nix](../top-level/perSystem.nix)



## subModules\.outputs



Extra subModule list for ` outputs `\.



*Type:*
list of module



*Default:*

```nix
[ ]
```

*Declared by:*
 - [top-level/outputs\.nix](../top-level/outputs.nix)



## systems



All the system types to enumerate in the flake output subattributes\.



*Type:*
attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## systems\.\<name>\.config



The configuration for nixpkgs\.



*Type:*
attribute set of anything



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/subSystem\.nix](../top-level/subSystem.nix)



## systems\.\<name>\.crossSystem



The cross system for nixpkgs\.



*Type:*
null or string



*Default:*

```nix
"‹name›"
```

*Declared by:*
 - [top-level/subSystem\.nix](../top-level/subSystem.nix)



## systems\.\<name>\.localSystem



The local system for nixpkgs\.



*Type:*
string



*Default:*

```nix
"‹name›"
```

*Declared by:*
 - [top-level/subSystem\.nix](../top-level/subSystem.nix)



## systems\.\<name>\.name



The names used in functions like ` perSystem ` and ` withSystem `



*Type:*
string



*Default:*

```nix
"‹name›"
```

*Declared by:*
 - [top-level/subSystem\.nix](../top-level/subSystem.nix)



## systems\.\<name>\.overlays



Nixpkgs overlays



*Type:*
list of (nixpkgs overlay)



*Default:*

```nix
[ ]
```

*Declared by:*
 - [top-level/subSystem\.nix](../top-level/subSystem.nix)


