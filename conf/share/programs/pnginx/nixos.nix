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
in
{
  networking = {
    dhcpcd.extraConfig = "nohook resolv.conf";
    wireless.iwd.settings.Network.NameResolvingService = "none";
    networkmanager.dns = "none";
    nftables.tables = {
      dns-hijack = {
        family = "inet";
        content = ''
          chain prerouting {
            type nat hook prerouting priority -190; policy accept;
            iif lo return
            ip protocol { tcp, udp } th dport 53 redirect to :53
          }
          chain output {
            type nat hook output priority -190; policy accept;
            oif lo return
            meta skuid ${toString config.users.users.pproxy.uid} ip protocol { tcp, udp } th dport 53 accept
            meta skuid ${toString config.users.users.smartdns.uid} ip protocol { tcp, udp } th dport 53 accept
            ip protocol { tcp, udp } th dport 53 redirect to :53
          }
        '';
      };
    };
  };

  environment = {
    systemPackages = [
      proxyPackage
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
        uid = 530;
      };
      smartdns = {
        isSystemUser = true;
        group = "pproxy";
        uid = 531;
      };
    };
  };

  systemd.services = {
    pproxy = {
      description = "Nginx Web Server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe proxyPackage} run --config '${proxyConfig}/caddy.json'";
        Restart = "always";
        RestartSec = 2;
        TimeoutStopSec = 15;
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
      wantedBy = [ "multi-user.target" ];
      wants = [ "nss-lookup.target" ];
      after = [ "network.target" ];
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
        RuntimeDirectory = "smartdns";
        RuntimeDirectoryMode = "0750";
        CacheDirectory = "smartdns";
        CacheDirectoryMode = "0750";
        LogsDirectory = "smartdns";
        LogsDirectoryMode = "0750";
        UMask = "0077";
        User = "smartdns";
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
}
