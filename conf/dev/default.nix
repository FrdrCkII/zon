{
  perSystem = { pkgs, ... }: {
    devShells = {
      default = pkgs.mkShell {
        packages = [
          pkgs.git
          pkgs.frix.jujutsu
          pkgs.nixos-facter
          pkgs.yazi
          pkgs.just
          pkgs.age
        ];
      };
    };
  };
}
