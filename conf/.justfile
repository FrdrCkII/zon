alias c := clean
alias r := rebuild-flake
alias ri := rebuild-impure
alias rs := rebuild-stable
alias rf := rebuild-flake

clean:
    @sudo nix profile wipe-history --profile /nix/var/nix/profiles/system
    @nix store gc

rebuild-flake target:
    @sudo nixos-rebuild switch --accept-flake-config --flake .#{{ target }}
    
rebuild-impure target:
    @sudo nixos-rebuild switch --accept-flake-config --flake ./#{{ target }} --impure

rebuild-stable target:
    @cd $(nix store add-path --name source ./.) && \
        sudo nixos-rebuild switch -f default.nix -A nixosConfigurations.{{ target }}
