{
  config,
  lib,
  ...
}:
{
  config = {
    networking = {
      resolvconf = {
        enable = lib.mkDefault true;
      };

      dhcpcd = {
        enable = lib.mkDefault true;
        persistent = true;
        wait = "background";

        extraConfig = ''
          duid
          noarp

          option domain_name_servers, domain_name, domain_search
          option classless_static_routes
          option interface_mtu
          option host_name

          option rapid_commit
          require dhcp_server_identifier

          slaac private
          # noipv4ll

          interface wlan0

          interface enp3s0
        '';
      };

      nftables = {
        enable = lib.mkDefault true;
      };

      firewall = {
        enable = lib.mkDefault true;
        allowedTCPPorts = [
          80
          443
        ];
      };
    };

    services = {
      dnsmasq = {
        enable = true;
        settings = {
          port = 53;
          listen-address = "127.0.0.1";
          bind-interfaces = true;

          strict-order = true;
          server = lib.remove "127.0.0.1" config.networking.nameservers;
        };
      };
    };
  };
}
