{ pkgs, ... }: {
  config = {
    services.displayManager.lemurs = {
      enable = true;
      settings = {
        tty = 1;
        system_shell = "${pkgs.bash}/bin/sh";
        do_log = false;
        pam_service = "lemurs";
        background.show_background = false;
        environment_switcher = {
          left_mover = "<-";
          right_mover = "->";
          max_display_length = 16;
        };
      };
    };
  };
}
