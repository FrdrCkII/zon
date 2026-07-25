{
  lib,
  wrapit,
  emacs-pgtk,
  curl,
  rust-analyzer,
  clang-tools,
  nixd,
  nil,
}:
wrapit.emacs.override {
  package = emacs-pgtk;
  initDirectory = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./early-init.el
      ./init.el
    ];
  };
  emacsPackages = epkgs: [
    epkgs.org
    epkgs.htmlize
    epkgs.neotree
    epkgs.diff-hl
    epkgs.treesit-auto
    epkgs.treesit-grammars.with-all-grammars
    epkgs.nix-ts-mode
    epkgs.just-ts-mode
    epkgs.apheleia
    epkgs.corfu
  ];
  extraPrograms = [
    curl
    rust-analyzer
    clang-tools
    nixd
    nil
  ];
}
