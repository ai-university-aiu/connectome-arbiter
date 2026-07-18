#!/usr/bin/env bash
# run_arbiter.sh — exercise the action selector and prove the membership invariant.
#
# Assembles the SWI-Prolog library path over the arbiter's packs plus the PrologAI
# packs reused UNMODIFIED (lattice = the stigmergy + await/notify substrate; actors
# = the cyclic_actor threads; causal_core + the signing harness = the grounding
# engine the stratum packs load, since each co-locates its structure records with
# its runtime). Exit 0 ONLY if the membership invariant held on every episode.
set -u
# Resolve the arbiter repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Resolve the PrologAI checkout (honour PROLOGAI_HOME, else the local default).
PROLOGAI_HOME="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}"
# Confirm the PrologAI checkout exists before building the library path.
if [ ! -d "$PROLOGAI_HOME/packs/lattice/prolog" ]; then
  echo "run_arbiter.sh: cannot find PrologAI at $PROLOGAI_HOME (set PROLOGAI_HOME)" >&2
  exit 2
fi
# Start the library path with every arbiter pack's prolog directory.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Add the reused PrologAI packs: the Lattice and the actors.
LIB="$LIB -p library=$PROLOGAI_HOME/packs/lattice/prolog"
LIB="$LIB -p library=$PROLOGAI_HOME/packs/actors/prolog"
# Add the grounding engine and signing harness (the stratum packs co-locate structure with runtime).
LIB="$LIB -p library=$PROLOGAI_HOME/packs/causal_core/prolog"
LIB="$LIB -p library=$PROLOGAI_HOME/tests/causalontology_conformance"
# Run the driver; its initialization goal runs the episodes and halts with the verdict code.
swipl -q $LIB bin/run_arbiter.pl
# Propagate the driver's exit code (0 = the invariant held on every episode).
exit $?
