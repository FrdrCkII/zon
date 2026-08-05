{
  outputs = { mod, ... }: {
    wrapit = mod.loadDir (f: mod.load ({ mod, ... }: mod.load f)) ./wrapit;
    extra = mod.loadDir ./extra;
  };
}
