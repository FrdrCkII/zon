let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  packages = [
    pkgs.openssl
  ];

  shellHook = ''
    rm -f {rootCA,server}.{key,crt,csr,srl}

    ls .

    openssl genrsa -out rootCA.key 2048
    openssl genrsa -out server.key 2048

    openssl req -new -x509 \
      -config rootCA.cnf \
      -key rootCA.key \
      -out rootCA.crt \
      -days 3650

    openssl req -new \
      -config server.cnf \
      -key server.key \
      -out server.csr

    openssl x509 -req \
      -in server.csr \
      -out server.crt \
      -CA rootCA.crt \
      -CAkey rootCA.key \
      -CAcreateserial \
      -days 3650 \
      -extensions v3_req \
      -extfile server.cnf

    exit
  '';
}
