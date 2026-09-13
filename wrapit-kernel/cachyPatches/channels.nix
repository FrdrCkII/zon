let
  locked = builtins.fromJSON (builtins.readFile ./channels.lock);
in
{
  inputs = {
    kernel-patches = {
      type = "gitArchive";
      url = "https://v6.gh-proxy.org/https://github.com/CachyOS/kernel-patches";
    };
  };

  inherit locked;
}
