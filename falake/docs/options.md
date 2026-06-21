## allSystems

All the system types to enumerate in the flake output subattributes\.



*Type:*
lazy attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## allSystems\.\<name>\.buildPlatform



Specifies the platform on which NixOS should be built\.
By default, NixOS is built on the system where it runs, but you can
change where it’s built\. Setting this option will cause NixOS to be
cross-compiled\.

For instance, if you’re doing distributed multi-platform deployment,
or if you’re building machines, you can set this to match your
development system and/or build farm\.



*Type:*
string or (attribute set)



*Default:*

```nix
config.nixpkgs.hostPlatform
```



*Example:*

```nix
{
  system = "x86_64-linux";
}
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## allSystems\.\<name>\.config



Global configuration for Nixpkgs\.
The complete list of [Nixpkgs configuration options](https://nixos\.org/manual/nixpkgs/unstable/\#sec-config-options-reference) is in the [Nixpkgs manual section on global configuration](https://nixos\.org/manual/nixpkgs/unstable/\#chap-packageconfig)\.



*Type:*
nixpkgs config



*Default:*

```nix
{ }
```



*Example:*

```nix
{ allowBroken = true; allowUnfree = true; }

```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## allSystems\.\<name>\.hostPlatform



Specifies the platform where the NixOS configuration will run\.

To cross-compile, set also ` nixpkgs.buildPlatform `\.



*Type:*
unspecified value



*Default:*

```nix
"‹name›"
```



*Example:*

```nix
{
  system = "aarch64-linux";
}
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## allSystems\.\<name>\.inheritTop



Whether to inherit ` overlays ` and ` config ` from the top



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## allSystems\.\<name>\.name



The names used in functions like ` perSystem ` and ` withSystem `



*Type:*
string



*Default:*

```nix
"‹name›"
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## allSystems\.\<name>\.overlays



List of overlays to apply to Nixpkgs\.
This option allows modifying the Nixpkgs package set accessed through the ` pkgs ` module argument\.

For details, see the [Overlays chapter in the Nixpkgs manual](https://nixos\.org/manual/nixpkgs/stable/\#chap-overlays)\.

If the ` nixpkgs.pkgs ` option is set, overlays specified using ` nixpkgs.overlays ` will be applied after the overlays that were already included in ` nixpkgs.pkgs `\.



*Type:*
list of (nixpkgs overlay)



*Default:*

```nix
[ ]
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## debug



Show debug info\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## nixpkgs\.config



Global configuration for Nixpkgs\.
The complete list of [Nixpkgs configuration options](https://nixos\.org/manual/nixpkgs/unstable/\#sec-config-options-reference) is in the [Nixpkgs manual section on global configuration](https://nixos\.org/manual/nixpkgs/unstable/\#chap-packageconfig)\.



*Type:*
nixpkgs config



*Default:*

```nix
{ }
```



*Example:*

```nix
{ allowBroken = true; allowUnfree = true; }

```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## nixpkgs\.overlays



List of overlays to apply to Nixpkgs\.
This option allows modifying the Nixpkgs package set accessed through the ` pkgs ` module argument\.

For details, see the [Overlays chapter in the Nixpkgs manual](https://nixos\.org/manual/nixpkgs/stable/\#chap-overlays)\.

If the ` nixpkgs.pkgs ` option is set, overlays specified using ` nixpkgs.overlays ` will be applied after the overlays that were already included in ` nixpkgs.pkgs `\.



*Type:*
list of (nixpkgs overlay)



*Default:*

```nix
[ ]
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## nixpkgs\.src



Path to nixpkgs\.

By default, the value \<nixpkgs> used is impure\.
If you want to do a pure evaluation, don’t set this option directly; instead,
set ` nixpkgs ` in the initialization function ` mkFalake `\.



*Type:*
absolute path *(read only)*



*Default:*

```nix
"<nixpkgs>"
```

*Declared by:*
 - [top-level/nixpkgs\.nix](../top-level/nixpkgs.nix)



## out



Usually, the ` outputs ` option generates some meaningless values (e\.g\. {}/\[]/null)
because an option has to have a default value\.

This option is used to clean up that noise\.



*Type:*
lazy attribute set of unspecified value *(read only)*



*Default:*

```nix
{
  apps = { };
  checks = { };
  devShells = { };
  formatter = { };
  legacyPackages = { };
  nixosConfigurations = { };
  nixosModules = { };
  overlays = { };
  packages = { };
}
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



## perSystem



A function from system to flake-like attributes omitting the ` <system> ` attribute\.



*Type:*
module



*Default:*

```nix
{ }
```

*Declared by:*
 - [top-level/systems\.nix](../top-level/systems.nix)


