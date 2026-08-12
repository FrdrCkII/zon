meta:
if meta ? flake then
  if builtins.isBool meta.flake then
    {
      enable = meta.flake;
      path = "flake.nix";
    }
  else if builtins.isString meta.flake then
    {
      enable = true;
      path = meta.flake;
    }
  else if builtins.isAttrs meta.flake then
    {
      enable = meta.flake.enable or true;
      path = meta.flake.path or "flake.nix";
    }
  else
    {
      enable = true;
      path = "flake.nix";
    }
else
  {
    enable = true;
    path = "flake.nix";
  }
