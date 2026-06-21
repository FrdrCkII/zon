{ lib, ... }: {
  config = {
    networking = {
      resolvconf = {
        enable = lib.mkDefault true;
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
