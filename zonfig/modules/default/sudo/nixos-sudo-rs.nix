_: {
  config = {
    security.sudo-rs = {
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
