{ osConfig, ... }: {
  files = {
    ".ssh/id_rsa".source = osConfig.age.secrets."ssh/id_rsa".path;
    ".ssh/id_rsa.pub".source = osConfig.age.secrets."ssh/id_rsa.pub".path;
    ".cargo/config.toml".text = ''
      [source.crates-io]
      replace-with = "mirror"

      [source.mirror]
      registry = "sparse+https://mirrors.bfsu.edu.cn/crates.io-index/"
    '';
  };
}
