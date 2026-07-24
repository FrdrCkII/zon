{
  perSystem = { pkgs, ... }: {
    devShells = {
      default = pkgs.mkShell {
        packages = [
          pkgs.git
          pkgs.frix.jujutsu
          pkgs.yazi
          pkgs.just
          pkgs.age
        ];
      };
    };
  };
}
