.PHONY: setup test unit integration

SANDBOX?=.sandbox

export XDG_CACHE_HOME=${SANDBOX}/cache
export XDG_CONFIG_HOME=${SANDBOX}/config
export XDG_DATA_HOME=${SANDBOX}/data
export XDG_STATE_HOME=${SANDBOX}/state

MINIMAL_INIT = tests/unit/minimal_init.lua
PLENARY_OPTS = {minimal_init='${MINIMAL_INIT}', sequential=true}

setup:
	mkdir -p ${XDG_CACHE_HOME} ${XDG_CONFIG_HOME} ${XDG_DATA_HOME} ${XDG_STATE_HOME}
	nvim --headless -u ${MINIMAL_INIT} -c "TSInstallSync lua cpp c" -c q

test: unit integration ;

unit:
	nvim --headless -u ${MINIMAL_INIT} -c "PlenaryBustedDirectory tests/unit ${PLENARY_OPTS}"

integration: build
	nvim --headless -u ${MINIMAL_INIT} -c "PlenaryBustedDirectory tests/integration ${PLENARY_OPTS}"

build: tests/integration
	$(MAKE) -C tests/integration build

clean: tests/integration
	$(MAKE) -C tests/integration clean
