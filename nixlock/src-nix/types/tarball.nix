{
  config,
  needUpdate,
  nixToString,
  prefetchCommand,
  writeExeclineBin,
  ...
}:
[
  {
    name = "meta";
    eval =
      {
        url,
        type,
        hashType ? config.defaultHashType,
        ...
      }:
      "@nixlock;@isString;"
      + (nixToString {
        inherit url type hashType;
      });
  }

  {
    name = "fetch";
    eval =
      {
        name,
        meta,
        locked,
        ...
      }:
      if needUpdate name || (locked.meta or { } == meta && locked ? fetch) then
        "@nixlock;@isString;" + (nixToString locked.fetch)
      else
        "@nixlock;@isJSON;"
        + (builtins.toJSON {
          type = "fetch";
          value = {
            url = meta.url;
            hash = meta.hashType;
            unpack = true;
          };
        });
  }

  {
    name = "expr";
    eval =
      {
        meta,
        fetch,
        ...
      }:
      "@nixlock;@isString;"
      + ''builtins.fetchTarball { url = "${fetch.url}"; ${meta.hashType} = "${fetch.hash}"; }'';
  }
]
