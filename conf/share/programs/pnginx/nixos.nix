{
  config,
  pkgs,
  lib,
  ...
}:
let
  pnginx = ./nginx;
  smartdns = ./smartdns;
  inherit (lib) getExe;
  nginxPackage = pkgs.caddy;
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
            meta skuid ${toString config.users.users.pnginx.uid} ip protocol { tcp, udp } th dport 53 accept
            meta skuid ${toString config.users.users.smartdns.uid} ip protocol { tcp, udp } th dport 53 accept
            meta skuid ${toString config.users.users.adghome.uid} ip protocol { tcp, udp } th dport 53 accept
            ip protocol { tcp, udp } th dport 53 redirect to :53
          }
        '';
      };
    };
  };

  environment = {
    systemPackages = [
      nginxPackage
      pkgs.openssl
      pkgs.netcat
      pkgs.bind
    ];
  };

  security = {
    pki.certificateFiles = [ "${pnginx}/ca/rootCA.crt" ];
  };

  users = {
    groups.pnginx = { };
    users = {
      pnginx = {
        isSystemUser = true;
        group = "pnginx";
        uid = 530;
      };
      smartdns = {
        isSystemUser = true;
        group = "pnginx";
        uid = 531;
      };
      adghome = {
        isSystemUser = true;
        group = "pnginx";
        uid = 532;
      };
    };
  };

  systemd.services = {
    adguardhome = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "adghome";
        Group = "pnginx";
      };
    };

    pnginx = {
      description = "Nginx Web Server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${getExe nginxPackage} run --config ${
          (import ./nginx/trans.nix { inherit pkgs lib; }).caddyJSON
        }/caddy.json";
        Restart = "always";
        RestartSec = 2;
        TimeoutStopSec = 15;
        UMask = "0027";
        User = "pnginx";
        Group = "pnginx";
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
        ExecStart = "${getExe pkgs.smartdns} -p - -c ${smartdns}/default.conf";
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
        Group = "pnginx";
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
