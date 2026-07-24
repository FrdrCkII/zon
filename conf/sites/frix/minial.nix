{
  pkgs,
  lib,
  ...
}:
{
  nix.settings = {
    use-cgroups = true;
    experimental-features = [
      "cgroups"
      "flakes"
    ];
  };
  nixpkgs = {
    allowUnfreePredicate = [
      "unrar"
      "uasm"
      "7zz"
    ];
  };

  environment = {
    systemPackages = [
      pkgs.nixlock
      pkgs._7zz-rar
      pkgs.unrar
      pkgs.cage
      pkgs.fastfetch
      pkgs.bottom
      pkgs.dust
      pkgs.age
    ];
    sessionVariables = {
      EDITOR = lib.mkForce "emacs";
      VISUAL = lib.mkForce "emacs -nw";
    };
    shellAliases = {
      c = "clear";
      du = "dust";
      ju = "just";
      ff = "fastfetch";
      yazi = "yi";
    };
  };

  users = {
    groups = {
      keys = { };
    };

    users = {
      main = {
        uid = 1000;
        isNormalUser = true;
        name = "main";
        home = "/home/main";
        createHome = true;
        hashedPassword = "$y$j9T$2zl6H25Dy9.Mx3UntXthF1$qRER0IrNchc.qZQR7iPi/pWvx3/L7oAvP9ElGe/PefB";
        extraGroups = [
          "wheel"
          "audio"
          "video"
          "keys"
        ];
        packages = [
          pkgs.frix.jujutsu
          pkgs.toml-sort
          pkgs.statix
        ];
      };
    };
  };
}
