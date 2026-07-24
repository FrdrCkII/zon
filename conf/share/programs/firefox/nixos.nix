{ lib, ... }:
let
  moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
  gh = repo: down: "https://v6.gh-proxy.org/https://github.com/${repo}/releases/download/${down}.xpi";
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
        (ext (gh "gorhill/uBlock" "1.71.0/uBlock0_1.71.0.firefox.signed") "uBlock0@raymondhill.net")
        (ext (moz "ublacklist") "@ublacklist")
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
