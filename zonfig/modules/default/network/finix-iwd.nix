{ lib, ... }: {
  config = {
    services.iwd = {
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
  };
}
