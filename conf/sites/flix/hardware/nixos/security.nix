{
  boot = {
    blacklistedKernelModules = [
      # 不需要的驱动
      "amdgpu"
      "radeon"
      # "nouveau"
      # "nvidia"
      # "nvidia_drm"
      # "nvidia_modeset"

      # 高危/老旧文件系统
      "adfs"
      "affs"
      "bfs"
      "befs"
      "cramfs"
      "efs"
      "exofs"
      "freevxfs"
      "f2fs"
      "hfs"
      "hpfs"
      "jfs"
      "minix"
      "nilfs2"
      "ntfs"
      "omfs"
      "qnx4"
      "qnx6"
      "sysv"
      "ufs"

      # 高危/过时网络协议
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "appletalk"
      "ipx"
      "psnap"
      "llc"
      "decnet"
      "ax25"
      "netrom"
      "rose"
      "x25"
      "lapb"
      "phonet"
      "af_key"

      # 硬件攻击面
      "firewire-core"
      "firewire-ohci"
      "ohci1394"

      # form Kicksecure
      # https://github.com/Kicksecure/security-misc/blob/master/etc/modprobe.d/30_security-misc_blacklist.conf%23security-misc-shared
      "cdrom"
      "sr_mod"
      "amd76x_edac"
      "ath_pci"
      "evbug"
      "pcspkr"
      "snd_aw2"
      "snd_intel8x0m"
      "snd_pcsp"
      "usbkbd"
      "usbmouse"
    ];
  };
}
