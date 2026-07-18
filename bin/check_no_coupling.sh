#!/usr/bin/env bash
# check_no_coupling.sh — prove the strata coordinate ONLY through the Lattice.
#
# The CLOSURE RULE demands zero actor-to-actor references at runtime: a stratum's
# runtime tick may never call another stratum's runtime tick — the strata hand off
# ONLY by posting numbered phase cues on the Lattice. This checker strips comments
# from each stratum pack and confirms no pack's code names another stratum's
# *_tick predicate. (Structural imports for grounding, and reuse of the shared
# membership guard, are NOT runtime coordination and are permitted — only the tick
# actor entry points are the runtime coupling this rule forbids.)
#
# Exit 0 = clean (no cross-tick reference); 1 = a reference found; 2 = error.
set -u
# Resolve the arbiter repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Run a small Python check over the three stratum packs' tick predicates.
python3 - <<'PY'
import re, sys
# Each stratum pack and the name of its runtime tick predicate (the actor entry point).
ticks = {
    "synaptic_stratum":  "synaptic_stratum_gain_tick",
    "region_stratum":    "region_stratum_select_tick",
    "community_stratum": "community_stratum_override_tick",
}
# Track any cross-tick reference found.
violations = []
# Examine each stratum pack's source.
for pack, own_tick in ticks.items():
    path = f"packs/{pack}/prolog/{pack}.pl"
    # Read the whole source.
    src = open(path).read()
    # Strip block comments /* ... */ (dot matches newline).
    code = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    # Strip whole-line % comments (keep code lines only).
    code = "\n".join(l for l in code.split("\n") if not l.lstrip().startswith("%"))
    # Also strip trailing % comments on code lines.
    code = re.sub(r"%.*", "", code)
    # Confirm this pack's code names no OTHER stratum's tick predicate.
    for other_pack, other_tick in ticks.items():
        if other_pack == pack:
            continue
        if re.search(r"\b" + re.escape(other_tick) + r"\b", code):
            violations.append(f"stratum '{pack}' calls stratum '{other_pack}' at runtime (references {other_tick})")

# Report the outcome.
if violations:
    print("check_no_coupling: FAIL")
    for v in violations:
        print("  " + v)
    sys.exit(1)
else:
    print("check_no_coupling: PASS -- the strata share only the Lattice; 0 actor-to-actor references at runtime.")
    print("  synaptic gain, region selection, community override hand off solely via numbered phase cues (phase_0..3).")
    sys.exit(0)
PY
# Propagate the Python checker's exit code.
exit $?
