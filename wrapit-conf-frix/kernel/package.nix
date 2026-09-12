{
  linuxManualConfig,
  linuxPackagesFor,
  stdenvAdapters,
  llvmPackages,
  llvm,
  lld,
  kernelPackage ? linux_latest,
  linux_latest,
  march ? "arrowlake-s",
}:
linuxPackagesFor (linuxManualConfig {
  pname = "linux-clang";
  inherit (kernelPackage)
    src
    version
    modDirVersion
    features
    ;

  stdenv = stdenvAdapters.overrideInStdenv llvmPackages.stdenv [
    llvm
    lld
  ];

  configfile = ./kernel.config;
  allowImportFromDerivation = true;
  kernelPatches = [ ];

  extraMakeFlags = [
    "KCFLAGS+=-march=${march}"
    "KCFLAGS+=-mtune=${march}"
    "KCFLAGS+=-O3"
    "KCFLAGS+=-Wno-unused-command-line-argument"
    "CC=${llvmPackages.clang-unwrapped}/bin/clang"
    "AR=${llvm}/bin/llvm-ar"
    "NM=${llvm}/bin/llvm-nm"
    "LD=${lld}/bin/ld.lld"
    "LLVM=1"
  ];
})
