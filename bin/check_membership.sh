#!/usr/bin/env bash
# check_membership.sh — the safety layer's FLAGSHIP gate: run the membership battery.
#
# Thin wrapper (plumbing only) around bin/check_membership.pl, the dedicated
# adversarial battery that TRIES to make the selector emit an action nobody
# offered — across every candidate subset, the selection pipeline, the override,
# and a tampered gained set — and confirms it cannot. It assembles the same
# SWI-Prolog library path the sibling gates use (the arbiter packs plus the
# PrologAI grounding engine and signing harness the stratum packs load) and
# PROPAGATES the battery's exit code: exit 0 iff zero escapes, non-zero otherwise.
# This makes the flagship check runnable by its documented name and picked up by
# a bin/*.sh gate loop. It does NOT alter the battery.
set -u
# Resolve the arbiter repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Resolve the PrologAI checkout (honour PROLOGAI_HOME, else the local default) — same as the sibling gates.
PROLOGAI_HOME="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}"
# The conformance harness directory holding schema_check.pl, signing.pl, ed25519.pl, schema/.
HARNESS="$PROLOGAI_HOME/tests/causalontology_conformance"
# Confirm the harness exists before building the library path (the same guard the validator uses).
if [ ! -f "$HARNESS/schema_check.pl" ]; then
  # Report the missing dependency and stop.
  echo "check_membership.sh: cannot find the conformance harness at $HARNESS (set PROLOGAI_HOME)" >&2
  exit 2
fi
# Start the library path with every arbiter pack's prolog directory.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Add PrologAI's causal_core engine, the Lattice pack (region co-locates structure with runtime), and the harness.
LIB="$LIB -p library=$PROLOGAI_HOME/packs/causal_core/prolog"
LIB="$LIB -p library=$PROLOGAI_HOME/packs/lattice/prolog"
LIB="$LIB -p library=$HARNESS"
# Run the UNMODIFIED battery; its initialization goal runs 532 attempts and halts with the verdict code.
swipl -q $LIB bin/check_membership.pl
# Propagate the battery's exit code (0 = zero escapes; non-zero = an escape was found).
exit $?
