#!/bin/bash
# Adapted from https://github.com/nvim-neotest/neotest/blob/master/scripts/test
tempfile=$(mktemp)

if [[ -n $1 ]]; then
  nvim --headless --noplugin -u tests/unit/minimal_init.vim -c "PlenaryBustedFile $1" | tee "${tempfile}"
else
  nvim --headless --noplugin -u tests/unit/minimal_init.vim -c "PlenaryBustedDirectory tests/unit {minimal_init = 'tests/unit/minimal_init.vim'}" | tee "${tempfile}"
fi

# Plenary doesn't emit exit code 1 when tests have errors during setup
errors=$(sed 's/\x1b\[[0-9;]*m//g' "${tempfile}" | awk '/(Errors|Failed) :/ {print $3}' | grep -v '0')

rm "${tempfile}"

if [[ -n $errors ]]; then
  echo "Tests failed"
  exit 1
fi

exit 0
