{
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
      };
    };
  };

  systemd.services = {
    pproxy = {
      description = "Proxy Server";
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
}
