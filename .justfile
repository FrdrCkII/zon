alias f := fmt
alias fc := fmt-chmod

fmt:
    @treefmt .

fmt-chmod:
    @find . -type d | xargs chmod 755
    @find . -type f | xargs chmod 644

gc:
    @jj op abandon ..@-
    @jj util gc
