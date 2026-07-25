{ wrapit }:
wrapit.aria2.override {
  settings = {
    dir = "xdwn/";
    disk-cache = "64M";
    file-allocation = "none";
    no-file-allocation-limit = "64M";
    continue = true;
    always-resume = false;
    max-resume-failure-tries = 0;
    remote-time = true;
    max-file-not-found = 10;
    max-tries = 0;
    retry-wait = 10;
    connect-timeout = 10;
    timeout = 10;
    max-concurrent-downloads = 5;
    max-connection-per-server = 16;
    split = 128;
    min-split-size = 1048576;
    piece-length = 1048576;
    allow-piece-length-change = true;
    lowest-speed-limit = 0;
    max-overall-download-limit = 0;
    max-download-limit = 0;
    http-accept-gzip = true;
    content-disposition-default-utf8 = true;
    rpc-allow-origin-all = true;
    rpc-listen-all = true;
    rpc-listen-port = 16800;
    rpc-secret = "true";
    rpc-max-request-size = "10M";
  };
}
