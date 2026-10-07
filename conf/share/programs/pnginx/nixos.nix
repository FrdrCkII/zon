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
  sni = ./sni;
  proxyPackage = pkgs.caddy;
  proxyConfig = (import proxy { inherit pkgs lib; }).file;

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
        pkgs.sni-gate
        pkgs.openssl
        pkgs.netcat
        pkgs.bind
      ];

      etc = {
        "pproxy/ca".source = ca;
      };
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
          WorkingDirectory = "/var/lib/pproxy";
          StateDirectory = "pproxy";
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
          WorkingDirectory = "/var/lib/smartdns";
          StateDirectory = "smartdns";
          CacheDirectory = "smartdns";
          LogsDirectory = "smartdns";
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

      oxidns = {
        description = "Oxidns Server";
        wantedBy = lib.optional (cfg.dns == "oxidns") "multi-user.target";
        wants = lib.singleton "nss-lookup.target";
        after = lib.singleton "network.target";
        before = [
          "network-online.target"
          "nss-lookup.target"
        ];
        environment = {
          WORKDIR = "/var/cache/oxidns";
          CA_CERT = "${ca}/server.crt";
          CA_KEY = "${ca}/server.key";
        };
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.oxidns} start -c ${dns}/oxidns.yaml -d /var/lib/oxidns";
          Restart = "always";
          RestartSec = 2;
          TimeoutStopSec = 15;
          WorkingDirectory = "/var/lib/oxidns";
          StateDirectory = "oxidns";
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

      sni-gate = {
        enable = false;
        description = "SNI Gate";
        wantedBy = lib.singleton "multi-user.target";
        wants = lib.singleton "nss-lookup.target";
        after = lib.singleton "network.target";
        before = [
          "network-online.target"
          "nss-lookup.target"
        ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.sni-gate} --config ${sni}/sni-gate.toml";
          Restart = "always";
          RestartSec = 2;
          TimeoutStopSec = 15;
          UMask = "0077";
          WorkingDirectory = "/var/lib/sni-gate";
          StateDirectory = "sni-gate";
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

    services = {
      dnsmasq.settings = {
        server = [
          "::1#5360"
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

      # dae = {
      #   enable = true;
      #   configFile = "${sni}/dae.dae";
      #   assets = [
      #     pkgs.v2ray-geoip
      #     pkgs.v2ray-domain-list-community
      #   ];
      # };
    };
  };
}
