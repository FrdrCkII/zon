{
  pkgs,
  lib,
  ...
}:
let
  locked = bool: {
    Value = bool;
    Status = "locked";
  };

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
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    languagePacks = [ "zh-CN" ];

    policies = {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisablePrivateBrowsing = true;
      DisableProfileImport = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
        SuspectedFingerprinting = true;
        Category = "strict";
        BaselineExceptions = true;
        ConvenienceExceptions = true;
      };

      FirefoxSuggest.WebSuggestions = false;
      HttpsOnlyMode = "enabled";

      InstallAddonsPermission = {
        Default = false;
        Allow = [
          "http://addons.mozilla.org/"
          "http://github.com/"
        ];
      };

      NoDefaultBookmarks = true;
      SkipTermsOfUse = true;

      SearchEngines = {
        Default = "CnBing";
        PreventInstalls = true;
        Add = [
          {
            "Name" = "CnBing";
            "URLTemplate" = "https://cn.bing.com/search?q={searchTerms}";
            "Method" = "POST";
            "IconURL" = "file://${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            "Alias" = "@b";
            "Description" = "Chinese Bing";
            "PostData" = "name=value&q={searchTerms}";
            "SuggestURLTemplate" = "https://cn.bing.com/suggestions/q={searchTerms}";
          }
        ];

        Remove = [
          "Bing"
          "DuckDuckGo"
          "Google"
          "Perplexity"
          "Baidu"
          "baidu"
          "百度"
          "Wikipedia(en)"
          "wikipedia-zh-CN"
          "维基百科"
        ];
      };

      ExtensionSettings =
        builtins.listToAttrs [
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
        ]
        // {
          "*".installation_mode = "blocked";
        };

      Preferences = {
        "privacy.clearOnShutdown_v2.cache" = locked true;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = locked true;
        "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = locked true;
        "privacy.clearOnShutdown_v2.downloads" = locked true;
        "privacy.clearOnShutdown_v2.formdata" = locked true;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = locked true;
        "dom.security.https_only_mode" = locked true;
      };
    };
  };
}
