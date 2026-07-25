{ lib, ... }:
let
  moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
  ext = url: uuid: {
    name = uuid;
    value = {
      install_url = lib.mkForce url;
      installation_mode = lib.mkForce "force_installed";
    };
  };
in
{
  imports = [
    ./module.nix
  ];

  programs.firefox = {
    languagePacks = [ "zh-CN" ];
    policies = {
      ExtensionSettings = builtins.listToAttrs [
        (ext (moz "privacy-badger17") "jid1-MnnxcxisBPnSXQ@jetpack")
        (ext (moz "javascript-restrictor") "jsr@javascriptrestrictor")
        (ext (moz "localcdn-fork-of-decentraleyes") "{b86e4813-687a-43e6-ab65-0bde4ab75758}")
        (ext "https://f2.crxsoso.com/firefox/downloads/latest/ublock-origin/platform:2/ublock-origin.xpi" "uBlock0@raymondhill.net")
        (ext (moz "clearurls") "{74145f27-f039-47ce-a470-a662b129930a}")
        (ext (moz "ublacklist") "@ublacklist")
        (ext (moz "privacy-pass") "{48748554-4c01-49e8-94af-79662bf34d50}")
        (ext (moz "chrome-mask") "chrome-mask@overengineer.dev")
        (ext (moz "kiss-translator") "{fb25c100-22ce-4d5a-be7e-75f3d6f0fc13}")
        (ext (moz "tampermonkey") "firefox@tampermonkey.net")
        (ext (moz "darkreader") "addon@darkreader.org")
        (ext (moz "markdown-reader-ext") "{f3ee08f8-d4d8-4095-8096-4bb784d082f9}")
        (ext (moz "aria2-extension") "baptistecdr@users.noreply.github.com")
        (ext (moz "pakkujs") "{646d57f4-d65c-4f0d-8e80-5800b92cfdaa}")
      ];
    };
  };
}
