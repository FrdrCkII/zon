{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = [
        pkgs.fcitx5-rime
        pkgs.rime-zhwiki
      ];
      settings = {
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "rime";
        };
        globalOptions = {
          Hotkey = {
            EnumerateWithTriggerKeys = mkDefault "True";
            EnumerateSkipFirst = mkDefault "False";
            ModifierOnlyKeyTimeout = mkDefault "250";
          };
          "Hotkey/AltTriggerKeys" = mkDefault { "0" = "Shift_L"; };
          "Hotkey/PrevPage" = mkDefault { "0" = "Up"; };
          "Hotkey/NextPage" = mkDefault { "0" = "Down"; };
          Behavior = {
            ActiveByDefault = mkDefault "False";
            resetStateWhenFocusIn = mkDefault "No";
            ShareInputState = mkDefault "No";
            PreeditEnabledByDefault = mkDefault "True";
            ShowInputMethodInformation = mkDefault "True";
            showInputMethodInformationWhenFocusIn = mkDefault "False";
            CompactInputMethodInformation = mkDefault "True";
            ShowFirstInputMethodInformation = mkDefault "True";
            DefaultPageSize = mkDefault 5;
            OverrideXkbOption = mkDefault "False";
            PreloadInputMethod = mkDefault "True";
            AllowInputMethodForPassword = mkDefault "False";
            ShowPreeditForPassword = mkDefault "False";
            AutoSavePeriod = mkDefault 30;
          };
        };
        addons = {
          classicui.globalSection = {
            PreferTextIcon = mkDefault "True";
            Theme = mkDefault "default-dark";
            UseDarkTheme = mkDefault "False";
            UseAccentColor = mkDefault "False";
          };
          clipboard.globalSection = {
            TriggerKey = "";
          };
        };
      };
    };
  };
}
