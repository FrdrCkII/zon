{ lib, ... }: {
  config = {
    networking = {
      wireless.enable = lib.mkForce false;
      wireless.iwd = {
        enable = true;
        settings = {
          Network = {
            EnableIPv6 = lib.mkDefault true;
            RoutePriorityOffset = lib.mkDefault 300;
          };
          Settings = {
            AutoConnect = lib.mkDefault true;
            AddressRandomization = lib.mkDefault "once";
            AddressRandomizationRange = lib.mkDefault "nic";
          };
        };
      };

      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
      };
    };
  };
}
