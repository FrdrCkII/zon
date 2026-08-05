{
  lib,
  wrapit,
  emacs-pgtk,
  emacsPackagesFor,
  package ? emacs-pgtk,
  emacsPackages ? _: [ ],
  extraLibs ? [ ],
  extraPrograms ? [ ],
  initDirectory ? null,
}:
wrapit.wrapthem.override {
  package = (emacsPackagesFor package).emacsWithPackages emacsPackages;
  inherit extraPrograms;
  passthru = {
    inherit initDirectory;
  };
  wrapArgs = {
    default = {
      inherit extraLibs;
      appendFlags = lib.optionals (initDirectory != null) [
        "--init-directory=${initDirectory}"
      ];
    };
  };
}
