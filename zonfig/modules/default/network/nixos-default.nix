{ lib, ... }: {
  config = {
    networking = {
      resolvconf = {
        enable = lib.mkDefault true;
      };

      dhcpcd = {
        wait = "background";
        extraConfig = ''
          noarp
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
  };
}
