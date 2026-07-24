let
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFpz62FIWS1RBhhPzGUBHJGx2uF6G7HJwazCHns6CBct NixOS Agenix"
  ];
in
{
  "ssh/id_rsa".publicKeys = keys;
  "ssh/id_rsa.pub".publicKeys = keys;
}
