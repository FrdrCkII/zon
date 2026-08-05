{ pkgs, ... }:
let
  ca = ./ca;

  cacert =
    pkgs.runCommand "cacert"
      {
        buildInputs = [ pkgs.nssTools ];
      }
      ''
        mkdir --parents $out
        certutil -d sql:$out -A -t "C,," -n "Pnginx Local CA" -i ${ca}/rootCA.crt
      '';
in
{
  files = {
    ".pki/nssdb" = {
      type = "symlink";
      source = cacert.outPath;
    };
    ".ssh/config".text = ''
      Host github.com
        ProxyCommand sh -c "nc -v `dig @::1 -p 5365 +short github.com | head -1` 22"
    '';
  };
}
