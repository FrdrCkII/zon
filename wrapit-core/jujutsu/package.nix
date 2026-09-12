{
  wrapit,
  jujutsu,
  configFile ? ./config.toml,
}:
wrapit.wrapthem.override {
  package = jujutsu;
  wrapArgs = {
    default.set = {
      JJ_CONFIG = configFile;
    };
  };
}
