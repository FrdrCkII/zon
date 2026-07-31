{
  pkgs ? import <nixpkgs> { },
  lib ? import <nixpkgs/lib>,
  ...
}:
let
  caddyConfig = config: ''
    {
      default_bind 127.0.0.1
      auto_https off
    }
    ${config}
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
    }'';

  mkCaddyProxyGithub =
    input:
    let
      argLength = builtins.length input;
      isNormal = builtins.isString input;

      arg0 = if !isNormal then builtins.head input else input;
      arg1 = if !isNormal && (argLength >= 2) then builtins.elemAt input 1 else null;
      arg2 = if !isNormal && (argLength >= 3) then builtins.elemAt input 2 else null;

      extra = if isNull arg1 then "" else ", " + (lib.concatMapStringsSep ", " (v: v) arg1);
      allIp =
        if isNull arg2 then
          mkDynamicResolvers arg0
        else
          lib.concatMapStringsSep "\n  " (v: "to ${v}:443") arg2;
    in
    ''
      ${arg0}${extra} {
        encode zstd
        tls ${./ca/pixiv.net.crt} ${./ca/pixiv.net.key}
        reverse_proxy {
          ${allIp}
          max_fails 2
          fail_duration 10s
          lb_policy random
          header_up Host {http.request.host}
          
          @has_range { header Range * }
          header_up @has_range Range {http.request.header.Range}
          @has_if_range { header If-Range * }
          header_up @has_if_range If-Range {http.request.header.If-Range}
          
          header_up User-Agent {http.request.header.User-Agent}
          header_up X-Real-IP {http.request.remote.host}
          transport http {
            tls
            tls_insecure_skip_verify
            tls_server_name {http.request.host}
          }
        }
      }
    '';

  mkCaddyProxyPixiv =
    input:
    let
      argLength = builtins.length input;
      isNormal = builtins.isString input;

      arg0 = if !isNormal then builtins.head input else input;
      arg1 = if !isNormal && (argLength >= 2) then builtins.elemAt input 1 else null;
      arg2 = if !isNormal && (argLength >= 3) then builtins.elemAt input 2 else null;

      extra = if isNull arg1 then "" else ", " + (lib.concatMapStringsSep ", " (v: v) arg1);
      allIp =
        if isNull arg2 then
          mkDynamicResolvers arg0
        else
          lib.concatMapStringsSep "\n  " (v: "to ${v}:443") arg2;
    in
    ''
      ${arg0}${extra} {
        encode zstd
        tls ${./ca/pixiv.net.crt} ${./ca/pixiv.net.key}
        reverse_proxy {
          ${allIp}
          max_fails 2
          fail_duration 10s
          lb_policy random
          header_up Host {http.request.host}
          
          @has_range { header Range * }
          header_up @has_range Range {http.request.header.Range}
          @has_if_range { header If-Range * }
          header_up @has_if_range If-Range {http.request.header.If-Range}
          
          header_up User-Agent {http.request.header.User-Agent}
          header_up X-Real-IP {http.request.remote.host}
          transport http {
            tls
            tls_insecure_skip_verify
          }
        }
      }
    '';

  caddyFile = pkgs.writeText "caddyfile" (
    caddyConfig (
      (lib.concatMapStrings mkCaddyProxyPixiv [
        "gist.github.com"
        "codeload.github.com"
        "api.github.com"
        "lfs.github.com"
        "redirect.github.com"
        "copilot.github.com"
        "services.github.com"
        "community.github.com"
        "education.github.com"
        "enterprise.github.com"
        "classroom.github.com"
        "central.github.com"
        "collector.github.com"
        "lab.github.com"
        "assets-cdn.github.com"
        "pages.github.com"
        "resources.github.com"
        "developer.github.com"
        "partner.github.com"
        "desktop.github.com"
        "guides.github.com"
        "support.github.com"
        "git-lfs.github.com"
        "docs.github.com"
        "analytics.githubassets.com"
        [
          "github.com"
          [ "*.github.com" ]
        ]
        [
          "www.github.io"
          [ "*.github.io" ]
        ]
        [
          "www.githubassets.com"
          [ "*.githubassets.com" ]
        ]
      ])

      + (lib.concatMapStrings mkCaddyProxyGithub [
        [
          "raw.githubusercontent.com"
          [ "*.githubusercontent.com" ]
        ]
      ])

      + (lib.concatMapStrings mkCaddyProxyPixiv [
        [
          "pixiv.net"
          [ "*.pixiv.net" ]
          [
            "210.140.139.152"
            "210.140.139.155"
            "210.140.139.158"
            "210.140.139.161"
          ]
        ]
        [
          "fanbox.cc"
          [ "*.fanbox.cc" ]
          [
            "210.140.139.152"
            "210.140.139.155"
            "210.140.139.158"
            "210.140.139.161"
          ]
        ]
        [
          "lc-event.pixiv.net"
          null
          [
            "210.140.139.185"
          ]
        ]
        [
          "i.pximg.net"
          null
          [
            "210.140.139.135"
            "210.140.139.132"
            "210.140.139.137"
            "210.140.139.134"
            "210.140.139.131"
            "210.140.139.130"
            "210.140.139.129"
            "210.140.139.136"
          ]
        ]
        [
          "pixiv.pximg.net"
          [ "*.pximg.net" ]
          [
            "210.140.139.135"
            "210.140.139.132"
            "210.140.139.137"
            "210.140.139.134"
            "210.140.139.131"
            "210.140.139.133"
            "210.140.139.130"
            "210.140.139.129"
            "210.140.139.136"
          ]
        ]
        [
          "a.pixiv.org"
          [ "*.pixiv.org" ]
          [
            "210.140.139.183"
            "210.140.139.184"
            "210.140.139.182"
          ]
        ]
        [
          "api.fanbox.cc"
          null
          [
            "104.18.41.140"
            "172.64.146.116"
          ]
        ]
      ])

      + ''
        steamcommunity.com, *.steamcommunity.com {
            encode zstd
            tls ${./ca/pixiv.net.crt} ${./ca/pixiv.net.key}
            @forum expression path_regexp('.*(discussions|comment|forum).*')
            handle @forum {
                reverse_proxy {
                    ${mkDynamicResolvers "str001.steam302.xyz"}
                    ${mkDynamicResolvers "str002.steam302.xyz"}
                    ${mkDynamicResolvers "str003.steam302.xyz"}
                    ${mkDynamicResolvers "str004.steam302.xyz"}
                    max_fails 2
                    fail_duration 10s
                    lb_policy random
                    header_up Host "steamcommunity.com"
                    
                    @has_range { header Range * }
                    header_up @has_range Range {http.request.header.Range}
                    @has_if_range { header If-Range * }
                    header_up @has_if_range If-Range {http.request.header.If-Range}

                    header_up User-Agent "{http.request.header.User-Agent} Googlebot/2.1 (+http://www.google.com/bot.html)"
                    header_up X-Real-IP {http.request.remote.host}
                    transport http {
                        tls
                        tls_insecure_skip_verify
                        tls_server_name statuspage.akamaized.net
                    }
                }
            }
            handle {
                reverse_proxy {
                    # 静态 IP 列表
                    to 23.51.204.175:443 23.1.179.144:443 96.7.99.225:443
                    to 104.69.160.135:443 104.71.154.102:443 104.76.74.15:443
                    to 104.91.87.202:443 118.215.187.181:443 173.222.146.99:443
                    to 184.85.112.102:443 184.87.103.42:443 23.36.106.129:443
                    to 23.41.142.46:443 23.51.142.168:443
                    max_fails 2
                    fail_duration 10s
                    lb_policy random
                    header_up Host {http.request.host}
                    
                    @has_range { header Range * }
                    header_up @has_range Range {http.request.header.Range}
                    @has_if_range { header If-Range * }
                    header_up @has_if_range If-Range {http.request.header.If-Range}
                    
                    header_up User-Agent {http.request.header.User-Agent}
                    header_up X-Real-IP {http.request.remote.host}
                    transport http {
                        tls
                        tls_insecure_skip_verify
                        tls_server_name ""
                    }
                }
            }
        }
      ''
    )
  );
in
{
  caddyJSON = pkgs.runCommand "caddy.json" { } ''
    mkdir $out
    cat ${caddyFile} > $out/caddyfile
    ${lib.getExe pkgs.caddy} fmt --overwrite $out/caddyfile
    ${lib.getExe pkgs.caddy} adapt --config $out/caddyfile --adapter caddyfile > $out/caddy.json
  '';
  run = pkgs.mkShell {
    shellHook = ''
      cat ${caddyFile} > ./caddyfile
      ${lib.getExe pkgs.caddy} fmt --overwrite ./caddyfile
      ${lib.getExe pkgs.caddy} adapt --config ./caddyfile --adapter caddyfile | jq -S > caddy.json
      exit
    '';
  };
}
