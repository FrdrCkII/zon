{ ... }: {
  config = {
    services = {
      journald = {
        storage = "volatile";
        forwardToSyslog = true;
        extraConfig = ''
          SystemMaxUse=500M
          RuntimeMaxUse=200M
          SystemKeepFree=1G
          RuntimeKeepFree=500M
          MaxFileSec=1week
        '';
      };

      rsyslogd = {
        enable = true;
      };

      logrotate = {
        enable = true;
        settings = {
          header = {
            dateext = true;
            compress = true;
            delaycompress = true;
            frequency = "weekly";
            rotate = 4;
          };

          rsyslogd.files = [
            "/var/log/messages"
            "/var/log/warn"
          ];
        };
      };
    };
  };
}
