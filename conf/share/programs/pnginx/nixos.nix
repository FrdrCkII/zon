{
  config,
  pkgs,
  lib,
  ...
}:
let
  ca = ./ca;
  dns = ./dns;
  proxy = ./proxy;
  proxyPackage = pkgs.caddy;
  proxyConfig = (import proxy { inherit pkgs lib; }).file;

  oxidnsConfig = pkgs.writeText "oxidns.yaml" (
    lib.replaceStrings
      [
        "/etc/oxidns/server"
      ]
      [
        "${ca}/server"
      ]
      (lib.readFile "${dns}/oxidns.yaml")
  );

  cfg = config.services.pproxy;
in
{
  options.services.pproxy = {
    dns = lib.mkOption {
      default = "smartdns";
      type = lib.types.enum [
        "smartdns"
        "oxidns"
      ];
    };
  };

  config = {
    environment = {
      systemPackages = [
        proxyPackage
        pkgs.oxidns
        pkgs.openssl
        pkgs.netcat
        pkgs.bind
      ];
    };

    security = {
      pki.certificateFiles = [ "${ca}/rootCA.crt" ];
    };

    users = {
      groups.pproxy = { };
      users = {
        pproxy = {
          isSystemUser = true;
          group = "pproxy";
        };
      };
    };

    systemd.services = {
      pproxy = {
        description = "Proxy Server";
        wantedBy = lib.singleton "multi-user.target";
        wants = lib.singleton "network-online.target";
        after = lib.singleton "network-online.target";
        serviceConfig = {
          ExecStart = "${lib.getExe proxyPackage} run --config '${proxyConfig}/caddy.json'";
          Restart = "always";
          RestartSec = 2;
          TimeoutStopSec = 15;
          StateDirectory = "pproxy";
          StateDirectoryMode = "0750";
          UMask = "0027";
          User = "pproxy";
          Group = "pproxy";
          AmbientCapabilities = [
            "CAP_NET_BIND_SERVICE"
            "CAP_SYS_RESOURCE"
          ];
          CapabilityBoundingSet = [
            "CAP_NET_BIND_SERVICE"
            "CAP_SYS_RESOURCE"
          ];
        };
        unitConfig = {
          StartLimitBurst = 5;
          StartLimitInterval = 30;
        };
      };

      smartdns = {
        description = "SmartDNS Server";
        wantedBy = lib.optional (cfg.dns == "smartdns") "multi-user.target";
        wants = lib.singleton "nss-lookup.target";
        after = lib.singleton "network.target";
        before = [
          "network-online.target"
          "nss-lookup.target"
        ];
        path = [
          pkgs.gzip
        ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.smartdns} -p - -c ${dns}/smartdns.conf";
          Restart = "always";
          RestartSec = 2;
          TimeoutStopSec = 15;
          CacheDirectory = "smartdns";
          CacheDirectoryMode = "0750";
          LogsDirectory = "smartdns";
          LogsDirectoryMode = "0750";
          UMask = "0077";
          User = "pproxy";
          Group = "pproxy";
          AmbientCapabilities = [
            "CAP_NET_BIND_SERVICE"
            "CAP_SYS_RESOURCE"
          ];
          CapabilityBoundingSet = [
            "CAP_NET_BIND_SERVICE"
            "CAP_SYS_RESOURCE"
          ];
        };
        unitConfig = {
          StartLimitBurst = 0;
          StartLimitIntervalSec = 60;
        };
      };
    }
    // lib.optionalAttrs (cfg.dns == "oxidns") {
      oxidns = {
        description = "Oxidns Server";
        wantedBy = lib.singleton "multi-user.target";
        wants = lib.singleton "nss-lookup.target";
        after = lib.singleton "network.target";
        before = [
          "network-online.target"
          "nss-lookup.target"
        ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.oxidns} start -c ${oxidnsConfig} -d /var/cache/oxidns";
          Restart = "always";
          RestartSec = 2;
          TimeoutStopSec = 15;
          CacheDirectory = "oxidns";
          CacheDirectoryMode = "0750";
          UMask = "0077";
          User = "pproxy";
          Group = "pproxy";
          AmbientCapabilities = [
            "CAP_NET_BIND_SERVICE"
            "CAP_SYS_RESOURCE"
          ];
          CapabilityBoundingSet = [
            "CAP_NET_BIND_SERVICE"
            "CAP_SYS_RESOURCE"
          ];
        };
        unitConfig = {
          StartLimitBurst = 0;
          StartLimitIntervalSec = 60;
        };
      };
    };

    services.dnsmasq.settings = {
      server = [
        "127.0.0.1#5360"
      ];
      address = [
        "/github.com/127.0.0.1"
        "/githubusercontent.com/127.0.0.1"
        "/githubassets.com/127.0.0.1"
        "/github.io/127.0.0.1"
        "/steamcommunity.com/127.0.0.1"
        "/pixiv.net/127.0.0.1"
        "/pixivsketch.net/127.0.0.1"
        "/pximg.net/127.0.0.1"
        "/greasyfork.org/127.0.0.1"
      ];
    };
  };
}
