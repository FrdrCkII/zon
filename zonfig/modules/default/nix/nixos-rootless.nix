{
  users.groups.nix-daemon = { };
  users.users.nix-daemon = {
    isSystemUser = true;
    group = "nix-daemon";
  };

  nix = {
    daemonUser = "nix-daemon";
    daemonGroup = "nix-daemon";
    settings.experimental-features = [
      "local-overlay-store"
      "auto-allocate-uids"
    ];
  };
}
