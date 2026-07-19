# LEDGER — what building the safety layer found PrologAI still lacks

**This Ledger is a product of the program, not a defect list.** connectome-arbiter
is the Wave 4 SAFETY LAYER: the basal-ganglia action selector, built
stratum-primary with atomic-style internal sub-modules (the Wave 3 verdict's
decomposition) on the enforced N6 layer-to-stratum binding. Its deliverable is a
selector that cannot violate its membership invariant, and the proof that it
cannot. Every entry below is a wall building that selector actually hit.

## Identifier scheme

Entries use a fresh **ARBITER-series (ARBITER-1, ARBITER-2, …)**, so a finding
here can never collide with the spike's **L1–L9**, PrologAI's **L-series and
N1–N7**, the slice's **P1–P10**, or the arms' **ATOMIC / LOOPS / STRATA** series.
Second sightings cite their parent by its own id. Severity `S` uses the spike's
H/M/L scale.

## Where the finding is (and where it is NOT)

The safety layer's most important question was blunt: can PrologAI express the
MEMBERSHIP INVARIANT — the selected output is always a member of the input set —
as a first-class, checked property, or did it have to be hand-rolled? It had to be
hand-rolled (ARBITER-1). That is the one substantive new gap. Everything else the
change order flagged as a risk turned out to HOLD: the override hierarchy fit the
layer rule and the N6 binding without strain, and the verdict's internal
sub-modules genuinely recovered construct-level isolation. A pointed Ledger, not a
thin one — the winning decomposition fit, and the one thing PrologAI lacks is the
safety contract itself.

---

### ARBITER-1 — PrologAI cannot express the membership invariant as a first-class checked property · S=H

- **Construct that forced it.** THE ACTION SELECTOR and its sacred invariant:
  every emitted selection is a member of the offered candidate set (or an explicit
  no-selection). In a system that will eventually drive behaviour, a selector that
  can output an action nobody offered is the single most dangerous failure mode.
- **What PrologAI could not express.** There is no PrologAI or Causalontology
  construct for "the output of this predicate MUST be a member of this input set",
  declared and enforced by the language the way L4 enforces the layer rule or N6
  the layer-to-stratum binding. So the invariant had to be HAND-ROLLED, three ways
  at once: (a) a guard predicate that classifies a proposed action as a member,
  the explicit no-selection, or a refused non-member
  (`region_stratum_membership_guard/3`); (b) a guarded emit that makes an
  invention structurally impossible to return — it emits a member, or
  no-selection, or THROWS (`region_stratum_emit/3`); and (c) a dedicated,
  adversarial checker that TRIES to make the selector invent and confirms it
  cannot (`bin/check_membership.sh`, 532 attempts, zero escapes). The invariant is
  as strong as it can be made in user code — but it is a CONVENTION enforced by a
  guard the programmer must remember to route every output through, not a property
  the language checks. A second selector, written without knowing to call the
  guard, would carry no protection at all.
- **Evidence.** `packs/region_stratum/prolog/region_stratum.pl`
  (`region_stratum_membership_guard/3`, `region_stratum_emit/3`); the adversarial
  gate `bin/check_membership.sh` (running the battery `bin/check_membership.pl`);
  the override reuses the SAME guard
  (`packs/community_stratum/prolog/community_stratum.pl`) precisely because there
  is no language-level way to attach the invariant to a type or a port.
- **Proposed remedy (minimum).** A first-class CONTRACT / INVARIANT construct — a
  declared postcondition (for example, a port or predicate annotated
  `output_member_of(InputSet)`) that PrologAI checks and refuses to violate, so
  the membership guarantee attaches to the selector by declaration rather than to
  each output by a remembered call. This is L4's and N6's pattern applied to a
  behavioural safety property rather than a structural one.
- **Parents.** New. The safety-layer analogue of the program's recurring theme —
  a load-bearing property (there: the layer rule; here: the membership invariant)
  honoured by convention until the language is taught to enforce it.

### ARBITER-2 — a cross-stratal override carries skips:true because this cut does not model its mechanism (P2, second sighting) · S=M

- **Construct that forced it.** The contextual OVERRIDE: a community-stratum
  (ordinal 14) social signal that suppresses a region-stratum (ordinal 9) action.
- **What PrologAI could not express.** Biologically the override is mediated by a
  real mechanism (the cortical / hyperdirect pathway). But this thin safety cut
  models only the two endpoints, not the intervening strata, so the override
  causal_relation_object crosses five strata with no modeled mechanism and must
  carry `skips:true` to validate — exactly the Wave 2 slice's **P2** pattern ("the
  absence of a mechanism is a finding, not a gap"), now on a channel that DOES
  have a mechanism the cut simply does not draw. The Causalontology `skips` flag
  faithfully records "this cut jumps the strata", but there is still no way to say
  "a mechanism EXISTS and is deliberately unmodeled here" as distinct from "no
  mechanism exists" — the honest-ignorance distinction P2 first raised.
- **Evidence.** `packs/community_stratum/prolog/community_stratum.pl`
  (`community_stratum_override_cro/1`, minted with `skips-true`); it classifies as
  a clean skip (skipping, skip-gaps=[]) exactly as the slice's cortisol channel did.
- **Parents.** Confirms **P2** (Wave 2 slice; a runtime/mechanism facet of L5/N4).
  NOTE: the region stratum co-locates its structure records with its runtime, so —
  as in the atomic and strata arms (**ATOMIC-4**) — the runner and the validator
  each load the other half's engine; known, noted, not re-numbered.

---

## What did NOT become a finding (honesty — and it is the good news)

- **The membership invariant HELD, provably.** The dedicated adversarial gate made
  532 attempts to emit an action nobody offered — across every candidate subset,
  the selection pipeline, the override, and a TAMPERED gained set carrying a
  top-priority invention — and ZERO escaped. The guard refused 364 inventions
  outright; the rest resolved to a genuine member or an explicit no-selection. The
  runner independently re-checked the invariant on all five episodes and it held
  on every one. It cannot be violated in this build.
- **The override hierarchy fit the layer rule and the N6 binding WITHOUT strain.**
  The contextual override sits one stratum above the region selector (community 14
  over region 9); its dependency on the region action is a clean DOWNWARD edge, so
  the strict layer rule passed with zero upward edges AND the N6 binding passed
  with every pack's layer order-preserving-consistent with its stratum's ordinal
  (synaptic 7 -> layer 1, region 9 -> layer 2, community 14 -> layer 3). The
  override's priority logic strained neither construct. This is the FIRST real
  build to rest on the enforced N6 binding rather than a convention, and the
  binding checker was reachable from this repository and green.
- **The verdict's internal sub-modules DID recover construct-level isolation.** The
  Wave 3 verdict's one honest doubt was whether atomic-style sub-modules inside a
  stratum pack would recover the per-construct testability pure strata loses.
  Building the selector for real answers YES: its five sub-modules — intake,
  priority-compare, membership-guard, emit, and the select pipeline — are each
  exercised in isolation by the region suite (the guard classifies, emit throws on
  an invention, compare picks the highest, select always emits a member). The
  hybrid the verdict blessed works in anger.
- **The seventeen newly-minted structure records validated with no friction**
  (schema, semantics, the override skip, and the Ed25519 signature), grounding the
  selector's own anatomy the way the slice's twenty-eight were.

This Ledger is deliberately pointed: ONE substantive new gap (ARBITER-1, the
missing first-class safety contract) and one second sighting (ARBITER-2 -> P2),
against three explicit confirmations that the Wave 3 verdict's decomposition and
the Wave 4 Part One binding both did their jobs. The safety layer is safe, the
winning decomposition fit, and the one thing PrologAI still lacks for it is the
means to make the membership invariant a language guarantee rather than a
hand-routed guard.
