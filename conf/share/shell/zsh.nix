{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./bash.nix
  ];
  users = {
    defaultUserShell = pkgs.zsh;
  };
  environment = {
    variables = {
      ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    };
    systemPackages = [
      pkgs.zsh-completions
    ];
  };
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableGlobalCompInit = true;
      enableBashCompletion = false;
      enableLsColors = false;
      autosuggestions.enable = false; # source it later
      syntaxHighlighting.enable = false; # source it later
      histFile = "$ZDOTDIR/hist.zsh";
      interactiveShellInit = lib.mkOrder 200 ''
        autoload -Uz ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer
        autoload -Uz compinit

        zsh-defer compinit -C
        zsh-defer source <(carapace _carapace zsh)

        zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        zsh-defer source ${pkgs.zsh-history-substring-search}/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
        zsh-defer -t 0.05 source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        zsh-defer -t 0.10 source ${pkgs.zsh-nix-shell}/share/zsh/plugins/zsh-nix-shell/nix-shell.plugin.zsh
        zsh-defer -t 0.15 eval "$(zoxide init zsh)"

        zsh-defer -t 0.20 mkdir --parents $ZDOTDIR
        zsh-defer -t 0.20 touch $ZDOTDIR/hist.zsh
      '';
    };
  };
}
