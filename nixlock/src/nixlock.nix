{
  __mode,
  __update,
  config ? { },
  extraTypes ? _: { },
  inputs ? { },
  locked ? { },
  ...
}:
let
  pkgs = config.pkgs or import <nixpkgs> { };
  lib = config.lib or import <nixpkgs/lib>;
  defaultHashType = config.defaultHashType or "sha256";
  extraEvalTypes = config.extraEvalTypes or [ ];
in
assert
  lib.elem __mode [
    "lock"
    "update"
  ]
  && lib.isList __update
  && lib.isAttrs config
  && lib.isFunction extraTypes
  && lib.isAttrs inputs
  && lib.isAttrs locked
  && lib.elem defaultHashType [
    "blake3"
    "md5"
    "sha1"
    "sha256"
    "sha512"
  ]
  && lib.isList extraEvalTypes;
let
  nixToString =
    value:
    assert
      lib.isAttrs value
      || lib.isBool value
      || lib.isFloat value
      || lib.isFunction value
      || lib.isInt value
      || lib.isList value
      || lib.isPath value
      || lib.isString value
      || isNull value;
    if lib.isAttrs value && value ? __raw then
      "${value.__raw}"
    else if lib.isAttrs value then
      "{ ${
        lib.concatMapAttrsStringSep " " (
          name: value: "${nixToString { __raw = name; }} = ${nixToString value};"
        ) value
      } }"
    else if lib.isBool value then
      if value then "true" else "false"
    else if lib.isFloat value || lib.isInt value then
      toString value
    else if lib.isFunction value then
      ''"<function>"''
    else if lib.isList value then
      "[ ${lib.concatStringsSep " " (map nixToString value)} ]"
    else if isNull value then
      "null"
    else if lib.isPath value || lib.isString value then
      ''"${builtins.replaceStrings [ "\\" "\n" "\r" "\t" ] [ ''\\'' ''\n'' ''\r'' ''\t'' ] value}"''
    else
      "null";

  writeBashBin =
    packages: scripts:
    assert lib.isList packages && lib.isString scripts;
    pkgs.writers.writeBashBin "nixlock"
      {
        makeWrapperArgs = [
          ''--prefix PATH : "${
            lib.makeBinPath (
              packages
              ++ [
                pkgs.coreutils-full
                pkgs.gnused
                pkgs.gawk
                pkgs.jq
              ]
            )
          }"''
        ];
      }
      ''
        set -euo pipefail
        ${scripts}
      '';

  autoRef =
    ref:
    if isNull ref then
      "HEAD"
    else if builtins.isString ref && lib.hasInfix "/" ref then
      "${ref}"
    else if builtins.isString ref && !lib.hasInfix "/" ref then
      "refs/heads/${ref}"
    else
      "";

  matchType = input: types.${inputs.${input}.type};

  matchLen' = input: lib.length (matchType input);
  matchLen = input: nixToString (matchLen' input);

  matchPhase' = input: leng: lib.elemAt (matchType input) leng;
  matchPhase = input: leng: nixToString (matchPhase' input leng);

  matchPhaseName' = input: leng: (matchPhase' input leng).name;
  matchPhaseName = input: leng: nixToString (matchPhaseName' input leng);

  makeInput =
    input: args:
    inputs.${input}
    // args
    // {
      name = input;
      input = inputs.${input};
      locked = locked.${input} or { };
    };

  matchPhaseAction =
    input: leng: args:
    (matchPhase' input leng).action (makeInput input args);

  matchPhaseIsEval' =
    input: leng: args:
    lib.elem (matchPhaseAction input leng args) ([ "eval" ] ++ extraEvalTypes);
  matchPhaseIsEval =
    input: leng: args:
    nixToString (matchPhaseIsEval' input leng args);

  matchEval' =
    input: leng: args:
    (matchPhase' input leng).${matchPhaseAction input leng args} (makeInput input args);
  matchEval =
    input: leng: args:
    nixToString (matchEval' input leng args);

  matchRun =
    input: leng: args:
    (matchPhase' input leng).${matchPhaseAction input leng args} (makeInput input args);

  attrNames = list: nixToString (lib.attrNames list);

  nllib = {
    inherit
      nixToString
      writeBashBin
      autoRef
      matchType
      matchLen
      matchPhase
      matchPhaseName
      matchPhaseAction
      matchPhaseIsEval
      matchEval
      matchRun
      attrNames
      ;
  };

  raw = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        { type, ... }:
        nixToString {
          inherit type;
        };
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          expr ? { },
          ...
        }:
        nixToString expr;
    }
  ];

  file = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        {
          url,
          type,
          hashType ? defaultHashType,
          ...
        }:
        nixToString {
          inherit url type hashType;
        };
    }
    {
      name = "prefetch";
      action =
        {
          name,
          meta,
          locked,
          ...
        }:
        if
          (__mode == "update" && __update != [ ] && !(lib.elem name __update) || __mode == "lock")
          && locked.meta or { } == meta
          && locked ? prefetch
        then
          "eval"
        else
          "run";

      eval = { locked, ... }: nixToString locked.prefetch;

      run =
        { meta, ... }:
        writeBashBin [ ] ''
          NIX_HASH=$(nix store prefetch-file \
              --json \
              --name source \
              --hash-type '${meta.hashType}' \
              '${meta.url}' \
              | jq -r .hash)
          echo '${
            nixToString {
              inherit (meta) url;
              hash = "'$NIX_HASH'";
            }
          }'
        '';
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          meta,
          prefetch,
          ...
        }:
        ''builtins.fetchurl { url = "${prefetch.url}"; ${meta.hashType} = "${prefetch.hash}"; }'';
    }
  ];

  tarball = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        {
          url,
          type,
          hashType ? defaultHashType,
          ...
        }:
        nixToString {
          inherit url type hashType;
        };
    }
    {
      name = "prefetch";
      action =
        {
          meta,
          locked,
          ...
        }:
        if locked.meta or { } == meta && locked ? prefetch then "eval" else "run";

      eval = { locked, ... }: nixToString locked.prefetch;

      run =
        { meta, ... }:
        writeBashBin [ ] ''
          NIX_HASH=$(nix store prefetch-file \
              --json --unpack \
              --name source \
              --hash-type '${meta.hashType}' \
              '${meta.url}' \
              | jq -r .hash)
          echo '${
            nixToString {
              inherit (meta) url;
              hash = "'$NIX_HASH'";
            }
          }'
        '';
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          meta,
          prefetch,
          ...
        }:
        ''builtins.fetchTarball { url = "${prefetch.url}"; ${meta.hashType} = "${prefetch.hash}"; }'';
    }
  ];

  git = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        {
          url,
          ref ? null,
          rev ? null,
          type,
          hashType ? defaultHashType,
          ...
        }:
        nixToString {
          inherit
            url
            rev
            type
            hashType
            ;
          ref = autoRef ref;
        };
    }
    {
      name = "prefetch";
      action =
        {
          name,
          meta,
          locked,
          ...
        }:
        if
          (__mode == "update" && __update != [ ] && !(lib.elem name __update) || __mode == "lock")
          && locked.meta or { } == meta
          && locked ? prefetch
        then
          "eval"
        else
          "run";

      eval = { locked, ... }: nixToString locked.prefetch;

      run =
        { meta, ... }:
        writeBashBin [ pkgs.nix-prefetch-git ] ''
          NIX_PREFETCH=$(nix-prefetch-git \
              --url '${meta.url}' \
              --rev '${if isNull meta.rev then meta.ref else meta.rev}' \
              --hash '${meta.hashType}')
          NIX_GIT_REV=$(echo $PREFETCH | jq -r '.rev')
          NIX_HASH=$(echo $PREFETCH | jq -r '.hash')
          echo '${
            nixToString {
              inherit (meta) url;
              rev = "'$NIX_GIT_REV'";
              hash = "'$NIX_HASH'";
            }
          }'
        '';
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          meta,
          prefetch,
          ...
        }:
        ''builtins.fetchTarball { url = "${prefetch.url}"; rev = "${prefetch.rev}"; ${meta.hashType} = "${prefetch.hash}"; }'';
    }
  ];

  gitArchive = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        {
          url,
          ref ? null,
          rev ? null,
          fetchUrl ? "${url}/archive/'$NIX_GIT_REV'.tar.gz",
          type,
          hashType ? defaultHashType,
          ...
        }:
        nixToString {
          inherit
            url
            rev
            fetchUrl
            type
            hashType
            ;
          ref = autoRef ref;
        };
    }
    {
      name = "lock";
      action =
        {
          name,
          meta,
          locked,
          ...
        }:
        if
          (__mode == "update" && __update != [ ] && !(lib.elem name __update) || __mode == "lock")
          && locked.meta or { } == meta
          && locked ? lock
        then
          "eval"
        else
          "run";

      eval = { locked, ... }: nixToString locked.lock;

      run =
        { meta, ... }:
        writeBashBin [ pkgs.git ] ''
          NIX_GIT_REV=${
            if isNull meta.rev then "$(git ls-remote ${meta.url} --refs ${meta.ref} | cut -f1)" else meta.rev
          }
          NIX_FETCH_URL='${meta.fetchUrl}'
          echo '${
            nixToString {
              rev = "'$NIX_GIT_REV'";
              url = "'$NIX_FETCH_URL'";
            }
          }'
        '';
    }
    {
      name = "prefetch";
      action =
        {
          lock,
          locked,
          ...
        }:
        if locked.lock or { } == lock && locked ? prefetch then "eval" else "run";

      eval = { locked, ... }: nixToString locked.prefetch;

      run =
        {
          meta,
          lock,
          ...
        }:
        writeBashBin [ ] ''
          NIX_HASH=$(nix store prefetch-file \
              --json --unpack \
              --name source \
              --hash-type '${meta.hashType}' \
              '${lock.url}' \
              | jq -r .hash)
          echo '${
            nixToString {
              inherit (lock) url;
              hash = "'$NIX_HASH'";
            }
          }'
        '';
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          meta,
          prefetch,
          ...
        }:
        ''builtins.fetchTarball { url = "${prefetch.url}"; ${meta.hashType} = "${prefetch.hash}"; }'';
    }
  ];

  channel = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        {
          url,
          type,
          hashType ? defaultHashType,
          ...
        }:
        nixToString {
          inherit
            url
            type
            hashType
            ;
        };
    }
    {
      name = "lock";
      action =
        {
          name,
          meta,
          locked,
          ...
        }:
        if
          (__mode == "update" && __update != [ ] && !(lib.elem name __update) || __mode == "lock")
          && locked.meta or { } == meta
          && locked ? lock
        then
          "eval"
        else
          "run";

      eval = { locked, ... }: nixToString locked.lock;

      run =
        { meta, ... }:
        writeBashBin [ pkgs.git ] ''
          NIX_IMMUTABLE_URL=$(curl -I ${meta.url} | grep "immutable" | sed -n 's/.*<\([^>]*\)>.*/\1/p')
          echo '${
            nixToString {
              url = "'$NIX_IMMUTABLE_URL'";
            }
          }'
        '';
    }
    {
      name = "prefetch";
      action =
        {
          lock,
          locked,
          ...
        }:
        if locked.lock or { } == lock && locked ? prefetch then "eval" else "run";

      eval = { locked, ... }: nixToString locked.prefetch;

      run =
        {
          meta,
          lock,
          ...
        }:
        writeBashBin [ ] ''
          NIX_HASH=$(nix store prefetch-file \
              --json --unpack \
              --name source \
              --hash-type '${meta.hashType}' \
              '${lock.url}' \
              | jq -r .hash)
          echo '${
            nixToString {
              inherit (lock) url;
              hash = "'$NIX_HASH'";
            }
          }'
        '';
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          meta,
          prefetch,
          ...
        }:
        ''builtins.fetchTarball { url = "${prefetch.url}"; ${meta.hashType} = "${prefetch.hash}"; }'';
    }
  ];

  # Chinese University Mirror for nix-channels
  # (If you can't read this, you don't need this)
  # 可以接受以下镜像站：
  # https://mirror.nju.edu.cn/nix-channels
  # https://mirrors.ustc.edu.cn/nix-channels
  # https://mirror.tuna.tsinghua.edu.cn/nix-channels
  # 更多的镜像站尚未经过测试，理论可用
  channel-mirror-cu = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        {
          url,
          type,
          hashType ? defaultHashType,
          channel ? "nixos-unstable",
          ...
        }:
        nixToString {
          inherit
            url
            type
            hashType
            channel
            ;
        };
    }
    {
      name = "lock";
      action =
        {
          name,
          meta,
          locked,
          ...
        }:
        if
          (__mode == "update" && __update != [ ] && !(lib.elem name __update) || __mode == "lock")
          && locked.meta or { } == meta
          && locked ? lock
        then
          "eval"
        else
          "run";

      eval = { locked, ... }: nixToString locked.lock;

      run =
        { meta, ... }:
        writeBashBin [ pkgs.git ] ''
          NIX_CHANNEL_REV=$(curl -Ls '${meta.url}/releases/' | \
            grep '${meta.channel}' | \
            sed -n 's/.*title="\([^"]*\).*date">\([^<]*\).*/\2 \1/p' | \
            sort -r | head -n1 | awk '{print $3}')
          echo '${
            nixToString {
              url = "${meta.url}/releases/'$NIX_CHANNEL_REV'/nixexprs.tar.xz";
            }
          }'
        '';
    }
    {
      name = "prefetch";
      action =
        {
          lock,
          locked,
          ...
        }:
        if locked.lock or { } == lock && locked ? prefetch then "eval" else "run";

      eval = { locked, ... }: nixToString locked.prefetch;

      run =
        {
          meta,
          lock,
          ...
        }:
        writeBashBin [ ] ''
          NIX_HASH=$(nix store prefetch-file \
              --json --unpack \
              --name source \
              --hash-type '${meta.hashType}' \
              '${lock.url}' \
              | jq -r .hash)
          echo '${
            nixToString {
              inherit (lock) url;
              hash = "'$NIX_HASH'";
            }
          }'
        '';
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          meta,
          prefetch,
          ...
        }:
        ''builtins.fetchTarball { url = "${prefetch.url}"; ${meta.hashType} = "${prefetch.hash}"; }'';
    }
  ];

  release = [
    {
      name = "meta";
      action = _: "eval";
      eval =
        {
          url,
          grep,
          type,
          hashType ? defaultHashType,
          ...
        }:
        nixToString {
          inherit
            url
            grep
            type
            hashType
            ;
        };
    }
    {
      name = "lock";
      action =
        {
          name,
          meta,
          locked,
          ...
        }:
        if
          (__mode == "update" && __update != [ ] && !(lib.elem name __update) || __mode == "lock")
          && locked.meta or { } == meta
          && locked ? lock
        then
          "eval"
        else
          "run";

      eval = { locked, ... }: nixToString locked.lock;

      run =
        { meta, ... }:
        writeBashBin [ ] ''
          NIX_URL=$(curl -s '${meta.url}' | \
            grep '${meta.grep}' | \
            head -n1)
          echo '${
            nixToString {
              url = "'$NIX_URL'";
            }
          }'
        '';
    }
    {
      name = "prefetch";
      action =
        {
          lock,
          locked,
          ...
        }:
        if locked.lock or { } == lock && locked ? prefetch then "eval" else "run";

      eval = { locked, ... }: nixToString locked.prefetch;

      run =
        {
          meta,
          lock,
          ...
        }:
        writeBashBin [ ] ''
          NIX_HASH=$(nix store prefetch-file \
              --json --unpack \
              --name source \
              --hash-type '${meta.hashType}' \
              '${lock.url}' \
              | jq -r .hash)
          echo '${
            nixToString {
              inherit (lock) url;
              hash = "'$NIX_HASH'";
            }
          }'
        '';
    }
    {
      name = "expr";
      action = _: "eval";
      eval =
        {
          meta,
          prefetch,
          ...
        }:
        ''builtins.fetchTarball { url = "${prefetch.url}"; ${meta.hashType} = "${prefetch.hash}"; }'';
    }
  ];

  defaultTypes = {
    inherit
      raw
      file
      tarball
      git
      gitArchive
      channel
      channel-mirror-cu
      release
      ;
  };

  types = defaultTypes // extraTypes { inherit pkgs lib nllib; };
in
{
  inherit
    pkgs
    lib
    inputs
    locked
    nllib
    defaultTypes
    types
    ;
}
