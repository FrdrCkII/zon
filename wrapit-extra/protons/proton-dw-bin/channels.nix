let
  locked = builtins.fromJSON (builtins.readFile ./channels.lock);
in
{
  inputs = {
    dwproton = {
      type = "forgejoRelease";
      domain = "dawn.wine";
      repo = "dawn-winery/dwproton";
      grep = "x86_64.tar.xz";
    };
  };

  inherit locked;
}
