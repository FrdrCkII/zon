{ modules, ... }: {
  imports = [
    modules.limine
  ];

  config = {
    programs.limine = {
      enable = true;
      settings.editor_enabled = true;
    };
  };
}
