{
  pkgs,
  lib,
  ...
}:
{
  environment = {
    variables = {
      CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
    };
    systemPackages = [
      pkgs.inshellisense
      pkgs.carapace
      pkgs.zoxide
      pkgs.bat
      pkgs.eza
      pkgs.fzf
      pkgs.fd
    ];
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -a";
      lt = "eza --tree";
      lla = "eza -la";
    };
  };
  programs = {
    bash = {
      enable = true;
      enableLsColors = true;
      interactiveShellInit = lib.mkBefore ''
        mkdir --parents $XDG_CONFIG_HOME/bash
        touch $XDG_CONFIG_HOME/bash/history

        export HISTFILE=$XDG_CONFIG_HOME/bash/history
        export HISTCONTROL=ignoreboth:erasedups
        export _ZO_DOCTOR=0

        source <(carapace _carapace bash)

        function y() {
        	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        	command yazi "$@" --cwd-file="$tmp"
        	IFS= read -r -d ${"''"} cwd < "$tmp"
        	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
        	command rm -f -- "$tmp"
        }
      '';
    };
    zsh.interactiveShellInit = ''
      function y() {
        	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        	command yazi "$@" --cwd-file="$tmp"
        	IFS= read -r -d ${"''"} cwd < "$tmp"
        	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
        	command rm -f -- "$tmp"
      }
    '';
    starship = {
      enable = true;
      settings = lib.importTOML ./starship.toml;
    };
    yazi = {
      enable = true;
      settings = {
        yazi.mgr = {
          sort_sensitive = true;
          sort_dir_first = true;
          show_hidden = true;
        };
      };
    };
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = false;
    };
  };
}
