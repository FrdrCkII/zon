{
  fileSystems = {
    "/" = {
      label = "ROOT";
      fsType = "btrfs";
      options = [
        "subvol=+root"
        "compress-force=zstd:1"
        "autodefrag"
        "noatime"
      ];
    };
    "/home" = {
      label = "ROOT";
      fsType = "btrfs";
      options = [
        "subvol=+home"
        "compress-force=zstd:1"
        "autodefrag"
        "noatime"
      ];
    };
    "/nix" = {
      label = "ROOT";
      fsType = "btrfs";
      options = [
        "subvol=+nix-store"
        "compress-force=zstd:1"
        "autodefrag"
        "noatime"
      ];
    };
    "/boot" = {
      label = "EFI";
      fsType = "vfat";
    };
  };
  swapDevices = [
    {
      label = "SWAP";
      priority = 50;
    }
  ];
  services = {
    fstrim.enable = true;
  };
}
