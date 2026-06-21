{ ... }: {
  config = {
    security.sudo = {
      enable = true;
      execWheelOnly = true;
      extraRules = [
        {
          groups = [ "wheel" ];
          commands = [ "ALL" ];
        }
      ];
    };
  };
}
