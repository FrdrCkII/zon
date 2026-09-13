{
  lib,
  buildLinux,
  stdenv,
  applyPatches,
  kernelPatches,
  impureUseNativeOptimizations,
  overrideCC,
  pkgsBuildBuild,
  pkgsBuildHost,
  patchelf,
  linux,
  wLinuxPackages,
  kernel ? linux,
}:
let
  cachyosPatchesSrc = wLinuxPackages.cachyPatches;

  version = lib.getVersion kernel;
  fullVersion = lib.versions.pad 3 version;
  mojarVersion = lib.versions.pad 2 version;

  patchedSrc = applyPatches {
    name = "linux-src-patched";
    src = kernel.src;
    patches = [
      kernelPatches.bridge_stp_helper.patch
      kernelPatches.request_key_helper.patch
    ]
    ++ builtins.map (p: "${cachyosPatchesSrc}/${mojarVersion}/${p}") [
      "sched/0001-bore-cachy.patch"
      # "sched/0001-prjc-cachy.patch"
      "misc/0001-rt-i915.patch"
      "misc/dkms-clang.patch"
    ];
  };

  noBintools = {
    bootBintools = null;
    bootBintoolsNoLibc = null;
  };
  hostLLVM = pkgsBuildHost.llvmPackages.override noBintools;
  buildLLVM = pkgsBuildBuild.llvmPackages.override noBintools;

  ltoMakeflags = [
    "LLVM=1"
    "LLVM_IAS=1"
    "CC=${buildLLVM.clangUseLLVM}/bin/clang"
    "LD=${buildLLVM.lld}/bin/ld.lld"
    "HOSTLD=${hostLLVM.lld}/bin/ld.lld"
    "AR=${buildLLVM.llvm}/bin/llvm-ar"
    "HOSTAR=${hostLLVM.llvm}/bin/llvm-ar"
    "NM=${buildLLVM.llvm}/bin/llvm-nm"
    "STRIP=${buildLLVM.llvm}/bin/llvm-strip"
    "OBJCOPY=${buildLLVM.llvm}/bin/llvm-objcopy"
    "OBJDUMP=${buildLLVM.llvm}/bin/llvm-objdump"
    "READELF=${buildLLVM.llvm}/bin/llvm-readelf"
    "HOSTCC=${hostLLVM.clangUseLLVM}/bin/clang"
    "HOSTCXX=${hostLLVM.clangUseLLVM}/bin/clang++"

    # Mute nixpkgs CC wrapper warnings for Clang+LTO
    "NIX_CC_WRAPPER_SUPPRESS_TARGET_WARNING=1"
  ];

  stdenvLLVM =
    let
      mkLLVMPlatform =
        platform:
        platform
        // {
          linux-kernel = (platform.linux-kernel or { }) // {
            makeFlags = (platform.linux-kernel.makeFlags or [ ]) ++ ltoMakeflags;
          };
        };

      stdenv' = overrideCC hostLLVM.stdenv hostLLVM.clangUseLLVM;
    in
    stdenv'.override (old: {
      hostPlatform = mkLLVMPlatform stdenv'.hostPlatform;
      buildPlatform = mkLLVMPlatform stdenv'.buildPlatform;
      extraNativeBuildInputs = [
        hostLLVM.lld
        patchelf
      ];
    });
in
buildLinux {
  name = "linux-cachyos-bore-flix";
  inherit version;
  src = patchedSrc;

  stdenv = impureUseNativeOptimizations stdenvLLVM;

  extraMakeFlags = ltoMakeflags;

  modDirVersion = "${fullVersion}-clang-lto";

  ignoreConfigErrors = true;

  extraMeta = {
    description = "Linux CachyOS Kernel with Clang+ThinLTO";
    broken = !stdenv.hostPlatform.isx86_64;
  };
}
