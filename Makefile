.PHONY: test unit integration

MINIMAL_INIT = tests/unit/minimal_init.lua
PLENARY_OPTS = {minimal_init='${MINIMAL_INIT}', sequential=true}

test: unit integration ;

unit:
	nvim --headless -c "PlenaryBustedDirectory tests/unit ${PLENARY_OPTS}"

integration: build
	nvim --headless -c "PlenaryBustedDirectory tests/integration ${PLENARY_OPTS}"

build: tests/integration
	$(MAKE) -C tests/integration build

clean: tests/integration
	$(MAKE) -C tests/integration clean
