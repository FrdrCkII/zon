{ pkgs, ... }:
let
  locked = bool: {
    Value = bool;
    Status = "locked";
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
      GenerativeAI.Enabled = false;
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
      TranslateEnabled = false;
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
      ExtensionSettings = {
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
