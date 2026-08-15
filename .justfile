alias f := fmt
alias fc := fmt-chmod
alias c := clean
alias r := rebuild-flake
alias ri := rebuild-impure
alias rs := rebuild-stable
alias rf := rebuild-flake

fmt:
    @treefmt .
    @cd nixlock && cargo fmt

fmt-chmod:
    @find . -type d | xargs chmod 755
    @find . -type f | xargs chmod 644

gc:
    @jj op abandon ..@-
    @jj util gc

clean:
    @sudo nix profile wipe-history --profile /nix/var/nix/profiles/system
    @nix store gc

rebuild-flake target:
    @sudo nixos-rebuild switch --accept-flake-config --flake ./conf#{{ target }}
    
rebuild-impure target:
    @sudo nixos-rebuild switch --accept-flake-config --flake ./conf#{{ target }} --impure

rebuild-stable target:
    @cd $(nix store add-path --name source ./conf) && \
        sudo nixos-rebuild switch -f default.nix -A nixosConfigurations.{{ target }}
