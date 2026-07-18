#!/usr/bin/env bash
# check_layers.sh — run PrologAI's UNMODIFIED strict-layer-rule construct (L4)
# against the arbiter's packs. Exit 0 = no upward edge among declared packs.
set -u
# Resolve the arbiter repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Resolve the PrologAI checkout (honour PROLOGAI_HOME, else the local default).
PROLOGAI_HOME="${PROLOGAI_HOME:-/home/ccaitwo/PrologAI}"
# Confirm PrologAI's layer pack exists before trying to load it.
if [ ! -f "$PROLOGAI_HOME/packs/layer/prolog/layer.pl" ]; then
  echo "check_layers.sh: cannot find PrologAI's library(layer) at $PROLOGAI_HOME (set PROLOGAI_HOME)" >&2
  exit 2
fi
# The arbiter's packs directory (absolute) that the construct will check.
ARB_PACKS="$PWD/packs"
# Load PrologAI's layer construct and run its directory-scoped report + check over the arbiter.
swipl -q -p library="$PROLOGAI_HOME/packs/layer/prolog" \
  -g "use_module(library(layer)), layer_report_dir('$ARB_PACKS'), layer_check_dir('$ARB_PACKS', V), (V==[] -> halt(0) ; halt(1))" \
  -t "halt(2)" 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
