{ lib, ... }: {
  freeformType = lib.types.lazyAttrsOf (
    lib.types.unique {
      message = ''
        No option has been declared for this flake output attribute, so its definitions can't be merged automatically.
        Possible solutions:
          - Load a module that defines this flake output attribute
          - Declare an option for this flake output attribute
          - Make sure the output attribute is spelled correctly
          - Define the value only once, with a single definition in a single module
      '';
    } lib.types.raw
  );
}
