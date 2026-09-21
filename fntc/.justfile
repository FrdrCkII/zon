fmt:
    @treefmt .
    @cargo fmt

gc:
    @jj op abandon ..@-
    @jj util gc
