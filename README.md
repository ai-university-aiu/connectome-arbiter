# connectome-arbiter — the safety layer (Wave 4)

**THE DELIVERABLE IS A SELECTOR THAT CANNOT VIOLATE ITS INVARIANT, AND THE PROOF THAT IT CANNOT.**

This repository is the **safety layer** of the Connectome program. Its
one-sentence purpose: **to isolate the basal-ganglia action selector and make it
impossible for the selector to output an action nobody offered.** It is built
stratum-primary with atomic-style internal construct sub-modules — the
decomposition the Wave 3 verdict blessed — on the enforced N6 layer-to-stratum
binding delivered in Wave 4 Part One. The one gap building it revealed lives in
[`LEDGER.md`](LEDGER.md); that file, not this code, is the program's product.

## The sacred invariant

On every selection, **the emitted output is a member of the input candidate set,
or an explicit no-selection.** The selector may pick, delay, or pick nothing; it
may NEVER invent an option that was not offered. In a cognitive architecture that
will eventually drive behaviour, a selector that can emit an unoffered action is
the single most dangerous failure mode. This repository makes that failure
impossible to express and proves it cannot happen: 532 adversarial attempts to
force an invention, zero escapes.

## What it is

The basal-ganglia action selector, plus the override hierarchy above it, cut by
Causalontology stratum on the outside and by construct on the inside:

```
packs/neural_lattice/     layer 0            closure substrate (stigmergy + await/notify)   [substrate — unbound]
packs/causal_grounding/   layer 0            the shared Causalontology minting vocabulary    [substrate — unbound]
packs/synaptic_stratum/   layer 1  stratum synaptic (ordinal 7)   the dopaminergic gain on selection
packs/region_stratum/     layer 2  stratum region (ordinal 9)     THE SELECTOR + the membership guard
packs/community_stratum/  layer 3  stratum community_and_society (ordinal 14)  the contextual override
```

Every stratum pack declares BOTH its `layer(N)` (the L4 construct) AND the
`stratum(Label)` it represents (the N6 construct); the substrate packs declare a
layer but no stratum, so they are unbound gaps (never violations). Inside the
region pack, the selector is five independently testable sub-modules —

- **intake** — canonicalise the offered candidate set (the immutable membership reference);
- **priority-compare** — pick the highest (dopamine-gained) priority candidate;
- **membership-guard** — classify a proposal as a member, no-selection, or a refused non-member;
- **emit** — the guarded output: a member, no-selection, or a THROW; never an invention;
- **select** — the pipeline that runs compare then the guarded emit.

The override (community stratum) sits above the selector and can veto its choice,
falling back to the best non-vetoed OFFERED candidate or to no-selection — and it
REUSES the region's single membership guard, so the invariant has one enforcement
point exercised from every call site.

## How it runs

The three strata coordinate ONLY through the Lattice (stigmergy for state,
notification for reactivity, zero actor-to-actor references, no busy-poll): each
runs as a background actor and hands off by numbered phase cue — synaptic gain
(phase 0→1), region selection (1→2), community override (2→3). The driver presents
selection episodes and, independently of the in-selector guard, re-checks the
membership invariant on every final selection.

Everything reuses a local PrologAI checkout **unmodified** (default
`/home/ccaitwo/PrologAI`; override with `PROLOGAI_HOME`). SWI-Prolog 9.x required.

```bash
# 1. THE FIRST, NON-NEGOTIABLE GATE: adversarially try to make the selector invent (exit 0 = it cannot).
bin/check_membership.sh   # (via swipl bin/check_membership.pl; 532 attempts, 0 escapes)

# 2. Run the selector over a set of episodes; exit 0 only if the invariant held on every one.
bin/run_arbiter.sh

# 3. Prove the strata share only the Lattice — zero actor-to-actor references at runtime.
bin/check_no_coupling.sh

# 4. Run PrologAI's UNMODIFIED strict layer rule (L4) against the packs.
bin/check_layers.sh

# 5. Run PrologAI's UNMODIFIED N6 binding: every pack's layer is order-consistent with its stratum's ordinal.
bin/check_layer_binding.sh   # this build is the first to rest on the enforced N6 invariant

# 6. Validate the selector's Causalontology 2.0.0 structure records (17 records + the override skip + signature).
bin/validate_structure.sh

# 7. Run every pack's in-pack PLUnit suite (the selector suite TRIES to violate the invariant).
bin/run_tests.sh
```

## Status

The membership invariant held on every selection — 532 adversarial attempts, zero
escapes, and five clean episodes — and it is checked twice (in the selector's emit
sub-module and again, independently, by the driver). The override hierarchy
behaves as specified and every override still obeys membership. The strata share
only the Lattice with no busy-poll. The strict layer rule passes with zero upward
edges; the N6 binding passes with every layer order-consistent with its stratum's
ordinal (the first real build to rest on the enforced binding, and the checker was
reachable and green). The seventeen newly-minted Causalontology 2.0.0 records
validate, including the community→region override skip and its Ed25519 signature.
The mini regression is green (ARC-AGI-1 40/40, ARC-AGI-2 12/12 — a 10 percent
spot-check; full regression deferred). PrologAI, Mentova, the frozen spike,
connectome-proto-agi, and the three frozen Wave 3 arms are unmodified. See
[`LEDGER.md`](LEDGER.md) for ARBITER-1 (the one substantive gap: PrologAI has no
first-class way to express the membership invariant) and ARBITER-2.

## Boundaries (what this repository must not become)

Not a general framework — it is one safety component, built stratum-primary. It
does not scale up to the full connectome (it builds the arbiter and PROJECTS its
shape). It does not modify PrologAI (a gap is an ARBITER Ledger entry, not a
commit), Mentova, the frozen spike, connectome-proto-agi, or the three frozen
arms, all of which stand as the evidence it rests on.
