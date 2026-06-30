_: {
  config = {
    services = {
      journald = {
        storage = "volatile";
        forwardToSyslog = true;
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
