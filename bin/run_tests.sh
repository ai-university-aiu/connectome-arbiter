#!/usr/bin/env bash
# run_tests.sh — run every arbiter pack's in-pack PLUnit suite.
#
# Each pack ships packs/<name>/test/test_<name>.pl. The selector's suite TRIES to
# violate the membership invariant and confirms it cannot. Exit 0 iff all pass.
set -u
# Resolve the arbiter repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Resolve the PrologAI checkout (honour PROLOGAI_HOME, else the local default).
PROLOGAI_HOME="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}"
# Build the library path over every arbiter pack plus the reused PrologAI dirs.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# The strata runtime and neural_lattice need PrologAI's lattice and actors packs.
LIB="$LIB -p library=$PROLOGAI_HOME/packs/lattice/prolog"
LIB="$LIB -p library=$PROLOGAI_HOME/packs/actors/prolog"
# The grounded packs need the Causalontology engine and conformance harness.
LIB="$LIB -p library=$PROLOGAI_HOME/packs/causal_core/prolog"
LIB="$LIB -p library=$PROLOGAI_HOME/tests/causalontology_conformance"
# Track the overall result.
FAIL=0
# Run each pack's test suite in its own swipl process.
for t in packs/*/test/test_*.pl; do
  # Announce the suite.
  echo "== $t =="
  # Load the suite and run its tests; non-zero exit marks a failure.
  swipl -q $LIB -g "run_tests, halt(0)" -t "halt(1)" "$t" || FAIL=1
done
# Report and propagate the overall result.
if [ "$FAIL" -eq 0 ]; then echo "ALL PACK TESTS: PASS"; else echo "PACK TESTS: FAIL"; fi
exit $FAIL
