{
  config ? { },
  inputs,
  ...
}:
let
  defaultHashType = config.defaultHashType or "sha256";

  autoRef =
    ref:
    if builtins.isString ref && ref != "HEAD" then
      if isNull (builtins.match ".*/.*" ref) then "refs/heads/${ref}" else ref
    else
      "HEAD";

  commonHash =
    {
      unpack ? true,
      url ? "{url}",
      ...
    }:
    {
      Commands = {
        update = false;
        packages = [
          "jq"
        ];
        commands = [
          (
            [
              "nix"
              "store"
              "prefetch-file"
              "--extra-experimental-features"
              "nix-command"
              "--name"
              "source"
              "--hash-type"
              "{hashType}"
            ]
            ++ (if unpack then [ "--unpack" ] else [ ])
            ++ [
              "--json"
              "--no-pretty"
              "--log-format"
              "bar"
              url
            ]
          )
          [
            "jq"
            "-r"
            ".hash"
          ]
        ];
      };
    };

  commonRev.Commands = {
    update = true;
    packages = [
      "git"
      "coreutils"
    ];
    commands = [
      [
        "git"
        "ls-remote"
        "{repo}"
        "--refs"
        "{ref}"
      ]
      [
        "cut"
        "-f1"
      ]
    ];
  };

  types = {
    tarball =
      {
        url,
        hashType ? defaultHashType,
        unpack ? true,
        ...
      }:
      {
        url.String = url;
        hashType.String = hashType;
        hash = commonHash { inherit unpack; };
      };

    gitArchive =
      {
        url,
        ref ? null,
        rev ? null,
        hashType ? defaultHashType,
        ...
      }:
      {
        repo.String = url;
        hashType.String = hashType;
        ref.String = autoRef ref;
        rev = if isNull rev then commonRev else { String = rev; };
        url.String = "{repo}/archive/{rev}.tar.gz";
        hash = commonHash { };
      };

    lockable =
      {
        url,
        hashType ? defaultHashType,
        ...
      }:
      {
        raw.String = url;
        hashType.String = hashType;
        url.Commands = {
          update = true;
          packages = [
            "curl"
            "coreutils"
            "gnugrep"
          ];
          commands = [
            [
              "curl"
              "-sI"
              "{raw}"
            ]
            [
              "tr"
              "-d"
              "\r"
            ]
            [
              "grep"
              "-i"
              ''^link:.*rel="immutable"''
            ]
            [
              "sed"
              "-n"
              ''s/.*<\([^>]*\)>.*/\1/p''
            ]
            [
              "head"
              "-n1"
            ]
          ];
        };
        hash = commonHash { };
      };

    nixpkgsCn =
      {
        url,
        channel,
        hashType ? defaultHashType,
        ...
      }:
      {
        mirror.String = url;
        channel.String = channel;
        hashType.String = hashType;
        rev.Commands = {
          update = true;
          packages = [
            "curl"
            "coreutils"
            "gnugrep"
            "gnused"
          ];
          commands = [
            [
              "curl"
              "-Ls"
              "{mirror}"
            ]
            [
              "grep"
              "{channel}"
            ]
            [
              "sed"
              "-n"
              ''s/.*title="\([^"]*\).*date">\([^<]*\).*/\2 \1/p''
            ]
            [
              "sort"
              "-r"
            ]
            [
              "head"
              "-n1"
            ]
            [
              "cut"
              "-d "
              "-f3"
            ]
          ];
        };
        url.String = "{mirror}/{rev}/nixexprs.tar.xz";
        hash = commonHash { };
      };

    forgejoRelease =
      {
        domain,
        repo,
        grep,
        hashType ? defaultHashType,
        ...
      }:
      {
        domain.String = domain;
        repo.String = repo;
        grep.String = grep;
        hashType.String = "sha256";
        url.Commands = {
          update = true;
          packages = [
            "curl"
            "coreutils"
            "gnused"
            "jq"
          ];
          commands = [
            [
              "curl"
              "-s"
              "https://{domain}/api/v1/repos/{repo}/releases/latest"
            ]
            [
              "jq"
              "-r"
              ".assets[] | .browser_download_url"
            ]
            [
              "grep"
              "{grep}"
            ]
            [
              "head"
              "-n1"
            ]
          ];
        };
        hash = commonHash { };
      };
  };
in
builtins.mapAttrs (
  name: value: if value ? type && types ? ${value.type} then types.${value.type} value else value
) inputs
