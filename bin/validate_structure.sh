#!/usr/bin/env bash
# validate_structure.sh — validate the arbiter's Causalontology 2.0.0 structure records.
#
# Assembles the library path over the arbiter packs plus the PrologAI grounding
# engine and conformance harness. Because the region stratum co-locates its
# structure records WITH its runtime, importing it pulls in library(lattice), so
# that pack must be on the path too. Exit 0 iff every record is valid and the skip
# and signature checks pass.
set -u
# Resolve the arbiter repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Resolve the PrologAI checkout (honour PROLOGAI_HOME, else the local default).
PROLOGAI_HOME="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}"
# The conformance harness directory holding schema_check.pl, signing.pl, ed25519.pl, schema/.
HARNESS="$PROLOGAI_HOME/tests/causalontology_conformance"
# Confirm the harness exists before building the library path.
if [ ! -f "$HARNESS/schema_check.pl" ]; then
  echo "validate_structure.sh: cannot find the conformance harness at $HARNESS (set PROLOGAI_HOME)" >&2
  exit 2
fi
# Start the library path with every arbiter pack's prolog directory.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Add PrologAI's causal_core engine, the Lattice pack (region co-locates structure with runtime), and the harness.
LIB="$LIB -p library=$PROLOGAI_HOME/packs/causal_core/prolog"
LIB="$LIB -p library=$PROLOGAI_HOME/packs/lattice/prolog"
LIB="$LIB -p library=$HARNESS"
# Ensure the structure artifact directory exists.
mkdir -p structure
# Run the validator; its initialization goal validates every record and halts with the verdict code.
swipl -q $LIB bin/validate_structure.pl
# Propagate the validator's exit code (0 = all records valid).
exit $?
