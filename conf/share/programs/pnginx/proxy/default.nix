{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  ...
}:
let
  serverCA = ../ca/server.crt;
  serverKey = ../ca/server.key;
  tlsInfo = "tls ${serverCA} ${serverKey}";

  commonMatchers = ''
    @has_range {
        header Range *
    }
    @has_if_range {
        header If-Range *
    }
  '';

  commonProxySettings = ''
    max_fails 2
    fail_duration 10s
    unhealthy_status 500 502 503 504
    unhealthy_latency 1s
    lb_policy ip_hash
    header_up @has_range Range {http.request.header.Range}
    header_up @has_if_range If-Range {http.request.header.If-Range}
    header_up User-Agent {http.request.header.User-Agent}
    header_up X-Real-IP {http.request.remote.host}
  '';

  mkDynamicResolvers = domain: ''
    dynamic multi {
        a ${domain} 443 {
            resolvers 127.0.0.1:5365
            refresh 10s
        }
        a ${domain} 443 {
            resolvers 127.0.0.1:5370
            refresh 10s
        }
    }
  '';

  mkStaticUpstreams = ips: lib.concatMapStringsSep "\n" (u: "to ${u}") (map (ip: "${ip}:443") ips);

  mkProxySite =
    {
      domain,
      altNames ? [ ],
      ips ? null,
      sni ? false,
      handle ? "",
    }:
    let
      siteNames = lib.concatStringsSep ", " ([ domain ] ++ altNames);
      upstreams = if ips == null then mkDynamicResolvers domain else mkStaticUpstreams ips;
      sniLine =
        if lib.isString sni then
          ''"${sni}"''
        else if sni then
          "{http.request.host}"
        else
          ''""'';
    in
    ''
      ${siteNames} {
        ${tlsInfo}
        ${commonMatchers}
        ${handle}
        reverse_proxy {
          ${upstreams}
          header_up Host {http.request.host}
          ${commonProxySettings}
          transport http {
            tls_insecure_skip_verify
            tls_server_name ${sniLine}
          }
        }
      }
    '';

  sites =
    (import ./sites/github.nix)
    ++ (import ./sites/greasyfork.nix)
    ++ (import ./sites/pixiv.nix)
    ++ (import ./sites/steam.nix);

  caddyFile = pkgs.writeText "caddyfile" ''
    {
    	default_bind 127.0.0.1
    	log {
    		level error
    		format console
    	}
    }
    ${lib.concatMapStringsSep "\n" mkProxySite sites}
  '';
in
{
  shell = pkgs.mkShell {
    shellHook = ''
      cat ${caddyFile} > ./caddyfile
      ${lib.getExe pkgs.caddy} fmt --overwrite ./caddyfile
      ${lib.getExe pkgs.caddy} adapt --config ./caddyfile --adapter caddyfile | ${lib.getExe pkgs.jq} -S > caddy.json
      exit
    '';
  };

  file = pkgs.runCommand "caddy-json" { } ''
    mkdir $out
    cat ${caddyFile} > $out/caddyfile
    ${lib.getExe pkgs.caddy} fmt --overwrite $out/caddyfile
    ${lib.getExe pkgs.caddy} adapt --config $out/caddyfile --adapter caddyfile > $out/caddy.json
  '';
}
