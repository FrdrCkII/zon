[
  {
    domain = "steamcommunity.com";
    altNames = [ "*.steamcommunity.com" ];
    ips = [
      "23.51.204.175"
      "23.1.179.144"
      "96.7.99.225"
      "104.69.160.135"
      "104.71.154.102"
      "104.76.74.15"
      "104.91.87.202"
      "118.215.187.181"
      "173.222.146.99"
      "184.85.112.102"
      "184.87.103.42"
      "23.36.106.129"
      "23.41.142.46"
      "23.51.142.168"
    ];

    handle = ''
      @forum expression path_regexp('.*(discussions|comment|forum).*')
      handle @forum {
      	reverse_proxy {
      		to str001.steam302.xyz:443
      		to str002.steam302.xyz:443
      		to str003.steam302.xyz:443
      		to str004.steam302.xyz:443
      		header_up Host "steamcommunity.com"
      		max_fails 2
      		fail_duration 10s
      		unhealthy_status 500 502 503 504
      		unhealthy_latency 1s
      		lb_policy ip_hash
      		header_up @has_range Range {http.request.header.Range}
      		header_up @has_if_range If-Range {http.request.header.If-Range}
      		header_up User-Agent {http.request.header.User-Agent}
      		header_up X-Real-IP {http.request.remote.host}

      		header_up User-Agent "{http.request.header.User-Agent} Googlebot/2.1 (+http://www.google.com/bot.html)"
      		transport http {
      			tls_insecure_skip_verify
      			tls_server_name statuspage.akamaized.net
      		}
      	}
      }
    '';
  }
]
