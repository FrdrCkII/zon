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
      pkgs.bluetui
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
        autoSubUidGidRange = true;
        name = "main";
        description = "Frederick Bana";
        home = "/home/main";
        createHome = true;
        hashedPassword = "$y$j9T$1QReWL3Eat8fKCOJXdjoH0$sQ8sCWsHvZm0E6jevhYRXhLZ8gqzU.qWdAkKBVWjDo7";
        extraGroups = [
          "wheel"
          "audio"
          "video"
          "render"
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
