{ pkgs, lib, ... }: {
  virtualisation = {
    incus = {
      enable = true;
      preseed = {
        networks = [
          {
            name = "incusbr0";
            type = "bridge";
            config = {
              "ipv4.address" = "10.0.100.1/24";
              "ipv4.nat" = "true";
            };
          }
        ];
        storage_pools = [
          {
            name = "default";
            driver = "dir";
            config.source = "/var/lib/incus/storage-pools/default";
          }
        ];
        profiles = [
          {
            name = "default";
            devices = {
              eth0 = {
                type = "nic";
                name = "eth0";
                network = "incusbr0";
              };
              root = {
                type = "disk";
                path = "/";
                pool = "default";
                size = "35GiB";
              };
            };
          }
        ];
      };
    };
  };

  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  programs.captive-browser = {
    enable = true;
    interface = "wlan0";
  };

  users.users.main.packages = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rustfmt
    pkgs.frix.emacs
    pkgs.zed-editor
    pkgs.libreoffice
    pkgs.wechat-uos
    pkgs.wemeet
  ];

  nixpkgs = {
    allowUnfreePredicate = [
      "wechat-uos"
      "libwemeetwrap"
      "wemeet"
    ];

    overlays = lib.singleton (
      final: prev:
      let
        ghProxy = "https://v6.gh-proxy.org/https://github.com";

        patchedFetchgit =
          args:
          let
            # 构建一个临时的 Git 配置文件，包含所有 URL 重写规则
            gitConfigContent = ''
              [url "${ghProxy}/"]
                  insteadOf = https://github.com/
                  insteadOf = git@github.com:
            '';

            # 将配置文件写入 store，供 fetchgit 使用
            gitConfigFile = prev.writeText "wemeet-gitconfig" gitConfigContent;

            # 覆盖 fetchgit，强制使用我们的配置文件和环境变量
            originalFetchgit = prev.fetchgit;
            patched = originalFetchgit (
              args
              // {
                # 通过 gitConfigFile 参数注入配置（这是 nixpkgs 的新特性）
                gitConfigFile = gitConfigFile;
              }
            );
          in
          patched.overrideAttrs (old: {
            # 同时通过环境变量传递，双重保险
            GIT_CONFIG_GLOBAL = "${gitConfigFile}";
            GIT_CONFIG_SYSTEM = "${gitConfigFile}";

            # 确保子模块能通过代理访问，并信任代理证书
            GIT_SSL_CAINFO = "${prev.cacert}/etc/ssl/certs/ca-bundle.crt";
            NIX_SSL_CERT_FILE = "${prev.cacert}/etc/ssl/certs/ca-bundle.crt";

            # 允许使用 https 协议进行子模块克隆
            GIT_ALLOW_PROTOCOL = "https:http:file:git";
          });

        # 对 fetchFromGitHub 也做类似处理
        patchedFetchFromGitHub =
          args:
          let
            owner = args.owner or (throw "fetchFromGitHub: owner required");
            repo = args.repo or (throw "fetchFromGitHub: repo required");
            rev = args.rev or (args.tag or (throw "fetchFromGitHub: rev or tag required"));
            fetchSubmodules = args.fetchSubmodules or false;

            extraArgs = builtins.removeAttrs args [
              "owner"
              "repo"
              "rev"
              "tag"
              "fetchSubmodules"
              "private"
            ];
          in
          if fetchSubmodules then
            patchedFetchgit (
              extraArgs
              // {
                url = "${ghProxy}/${owner}/${repo}.git";
                inherit rev fetchSubmodules;
              }
            )
          else
            prev.fetchzip (extraArgs // { url = "${ghProxy}/${owner}/${repo}/archive/${rev}.tar.gz"; });
      in
      {
        # 将补丁应用到 wemeet 包的覆盖上
        wemeet = prev.wemeet.override {
          fetchFromGitHub = patchedFetchFromGitHub;
          fetchgit = patchedFetchgit;
        };
      }
    );
  };

  services = {
    flatpak.enable = true;

    scx = {
      enable = true;
      package = pkgs.scx.rustscheds;
      scheduler = "scx_rustland";
    };
  };
}
