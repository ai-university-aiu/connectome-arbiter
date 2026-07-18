#!/usr/bin/env bash
# check_layer_binding.sh — run PrologAI's N6 LAYER-TO-STRATUM BINDING against the arbiter.
#
# This is the first real build to rest on the enforced N6 invariant (delivered in
# Wave 4 Part One). It loads PrologAI's UNMODIFIED library(layer) and runs its
# binding check over the arbiter's packs against the arbiter's own structure
# records (the authoritative source of each stratum's ordinal): every stratum
# pack's declared layer must be order-preserving-consistent with its declared
# stratum's ordinal. Exit 0 = every layer honours its stratum's ordinal; the
# substrate packs (no stratum) are unbound gaps, never violations.
set -u
# Resolve the arbiter repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Resolve the PrologAI checkout (honour PROLOGAI_HOME, else the local default).
PROLOGAI_HOME="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}"
# Confirm PrologAI's layer pack (which carries the N6 binding) is reachable.
if [ ! -f "$PROLOGAI_HOME/packs/layer/prolog/layer.pl" ]; then
  echo "check_layer_binding.sh: cannot find PrologAI's library(layer) (N6) at $PROLOGAI_HOME — the arbiter must rest on it (set PROLOGAI_HOME)" >&2
  exit 2
fi
# The arbiter's packs and its structure records (the strata source for the ordinals).
ARB_PACKS="$PWD/packs"
ARB_STRATA="$PWD/structure"
# Load PrologAI's N6 binding and run its directory-scoped report + check over the arbiter.
swipl -q -p library="$PROLOGAI_HOME/packs/layer/prolog" \
  -g "use_module(library(layer)), layer_bind_report_dir('$ARB_PACKS', '$ARB_STRATA'), layer_bind_check_dir('$ARB_PACKS', '$ARB_STRATA', V), (V==[] -> halt(0) ; halt(1))" \
  -t "halt(2)" 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
