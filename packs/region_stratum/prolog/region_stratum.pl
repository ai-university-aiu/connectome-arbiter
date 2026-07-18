/*  connectome-arbiter — region_stratum (ordinal 9 -> pack layer 2): THE SELECTOR.

    This pack is the safety layer's heart: the BASAL-GANGLIA ACTION SELECTOR, at
    the region stratum (Causalontology ordinal 9). Under the Wave 3 verdict's rule
    it is one pack per stratum on the OUTSIDE, and one construct per module on the
    INSIDE: the selector's machinery is FIVE independently testable internal
    sub-modules, not one monolithic predicate —
      - INTAKE            (region_stratum_intake/2): receive and canonicalise the
                          candidate set; this canonical set is the IMMUTABLE
                          reference the membership invariant is checked against.
      - PRIORITY COMPARE  (region_stratum_priority_compare/2): pick the highest
                          (dopamine-gained) priority candidate.
      - MEMBERSHIP GUARD  (region_stratum_membership_guard/3): THE SACRED
                          INVARIANT — classify a proposed action as a member of
                          the offered set, the explicit no-selection, or a REFUSED
                          non-member.
      - EMIT              (region_stratum_emit/3): the guarded output — it emits a
                          member, or no-selection, or THROWS; it is structurally
                          INCAPABLE of returning an action nobody offered.
      - SELECT            (region_stratum_select/3): the pipeline that runs
                          compare then the guarded emit.

    THE MEMBERSHIP INVARIANT IS SACRED: on every selection the output is a member
    of the input set (or an explicit no-selection). The selector may pick, delay,
    or pick nothing; it may NEVER invent an option that was not offered. That is
    not a comment here — it is enforced by construction in region_stratum_emit/3,
    and the community override (a higher stratum) reuses THIS same guard, so the
    invariant has a single enforcement point exercised from every call site.

    Its STRUCTURE is grounded: the region stratum, the basal-ganglia bearer, the
    intake/selection/emission occurrents, the selection disposition, the candidate
    and action ports, the selection causal_relation_object, and the computational
    selection conduit. The candidate-input port additionally accepts the synaptic
    dopaminergic gain (a downward reference to synaptic_stratum, ordinal 7).

    It coordinates ONLY through the Lattice (phase 1 -> phase 2), by numbered cue,
    never naming the strata up- or downstream. Imports are all downward, so its
    layer(2) — matching ordinal 9 — passes both the layer rule and the N6 binding.
*/

% Declare the module: the selector's runtime tick, its five sub-modules, and the structure accessors.
:- module(region_stratum, [
    % region_stratum_select_tick/1: the runtime step — select from the gained candidates.
    region_stratum_select_tick/1,
    % region_stratum_intake/2: canonicalise the offered candidate set.
    region_stratum_intake/2,
    % region_stratum_priority_compare/2: the highest-priority candidate of a gained set.
    region_stratum_priority_compare/2,
    % region_stratum_membership_guard/3: THE INVARIANT — classify a proposed action against the set.
    region_stratum_membership_guard/3,
    % region_stratum_emit/3: the guarded emit — a member, no-selection, or a throw.
    region_stratum_emit/3,
    % region_stratum_select/3: the full region selection pipeline (compare then guarded emit).
    region_stratum_select/3,
    % region_stratum_action_occurrent/1: the action-selection occurrent (referenced by the override CRO).
    region_stratum_action_occurrent/1,
    % region_stratum_stratum/1: the region stratum record (needed by the override's skip classification).
    region_stratum_stratum/1,
    % region_stratum_records/1: the labelled list of this stratum's ten structure records.
    region_stratum_records/1
]).

% Import the shared minting vocabulary (Layer 0).
:- use_module(library(causal_grounding)).
% Import the Lattice substrate (Layer 0) for the runtime cue await/post and narration.
:- use_module(library(neural_lattice)).
% Import the synaptic stratum (Layer 1) for the dopaminergic-gain occurrent id the input port accepts.
:- use_module(library(synaptic_stratum)).
% Import list utilities for the candidate-set operations.
:- use_module(library(lists)).

% ---------------------------------------------------------------------------
% THE SELECTOR — five internal sub-modules, each exercisable in isolation.
% ---------------------------------------------------------------------------

% -- region_stratum_intake(+Raw, -Candidates): canonicalise the offered candidate set.
% Deduplicate by action (a set, not a bag) so the membership reference is well defined.
region_stratum_intake(Raw, Candidates) :-
    % Sort the candidates by action, keeping the first priority seen for each action.
    region_stratum_dedup_actions(Raw, [], Candidates).

% -- region_stratum_dedup_actions(+In, +SeenActions, -Out): keep one candidate per action.
region_stratum_dedup_actions([], _Seen, []).
region_stratum_dedup_actions([cand(A, P)|T], Seen, Out) :-
    % When the action was already seen, drop this duplicate.
    ( memberchk(A, Seen)
    ->  region_stratum_dedup_actions(T, Seen, Out)
    % Otherwise keep it and mark the action seen.
    ;   Out = [cand(A, P)|Rest],
        region_stratum_dedup_actions(T, [A|Seen], Rest) ).

% -- region_stratum_actions_of(+Candidates, -Actions): the set of offered actions.
region_stratum_actions_of(Candidates, Actions) :-
    % Project each candidate to its action.
    findall(A, member(cand(A, _), Candidates), Actions).

% -- region_stratum_priority_compare(+Gained, -Winner): the highest-priority gained candidate.
region_stratum_priority_compare(Gained, Winner) :-
    % Fold the candidates, keeping the one with the greatest priority.
    Gained = [First|Rest],
    foldl(region_stratum_keep_higher, Rest, First, Winner).

% -- region_stratum_keep_higher(+Cand, +Best, -NewBest): keep whichever priority is greater.
region_stratum_keep_higher(cand(A, P), cand(_, BP), cand(A, P)) :-
    % This candidate strictly wins on priority.
    P > BP, !.
region_stratum_keep_higher(_Cand, Best, Best).
    % Otherwise the incumbent best is retained (ties keep the earlier candidate).

% -- region_stratum_membership_guard(+Candidates, +Proposed, -Result): THE INVARIANT.
% Classify the proposed action: a member of the offered set, the explicit
% no-selection, or a REFUSED non-member. This predicate NEVER endorses an action
% that was not offered — refusing is the only outcome for a non-member.
region_stratum_membership_guard(_Candidates, no_selection, no_selection) :-
    % The explicit no-selection is always permitted (the selector may pick nothing).
    !.
region_stratum_membership_guard(Candidates, Proposed, selected(Proposed)) :-
    % A proposed action that is a member of the offered set is endorsed.
    region_stratum_actions_of(Candidates, Actions),
    memberchk(Proposed, Actions),
    !.
region_stratum_membership_guard(_Candidates, Proposed, refused(Proposed)).
    % Anything else — an action nobody offered — is REFUSED, never endorsed.

% -- region_stratum_emit(+Candidates, +Proposed, -Emitted): the guarded output.
% Emit a member, or no-selection, or THROW. It is structurally impossible for this
% predicate to return an action that is not a member of Candidates.
region_stratum_emit(Candidates, Proposed, Emitted) :-
    % Classify the proposed action against the offered set.
    region_stratum_membership_guard(Candidates, Proposed, Result),
    % Enforce the invariant on the classification.
    ( Result = selected(A)
    % An endorsed member is emitted.
    ->  Emitted = A
    ; Result = no_selection
    % The explicit no-selection is emitted.
    ->  Emitted = no_selection
    % A refused non-member is REFUSED loudly: the selector cannot emit an invented action.
    ;   Result = refused(Bad),
        throw(error(membership_violation(Bad, Candidates), region_stratum_emit/3)) ).

% -- region_stratum_select(+Candidates, +Gained, -Emitted): the full region selection.
% Compare priorities, then emit the winner THROUGH the membership guard against the
% ORIGINAL offered set — so even if the gained set were tampered with, an action not
% in Candidates could never be emitted.
region_stratum_select(Candidates, Gained, Emitted) :-
    % Pick the highest-priority gained candidate.
    region_stratum_priority_compare(Gained, cand(WinnerAction, _)),
    % Emit it only if it is a member of the ORIGINAL offered set (the guard is the gate).
    region_stratum_emit(Candidates, WinnerAction, Emitted).

% ---------------------------------------------------------------------------
% The runtime tick — Lattice-coordinated, phase 1 -> phase 2.
% ---------------------------------------------------------------------------

% -- region_stratum_select_tick(+Nexus): await the gained candidates, select, hand on.
region_stratum_select_tick(Nexus) :-
    % Block with no busy-poll until phase 1 (gained candidates) is cued, then take it.
    neural_lattice_await_cue(Nexus, 1, State0),
    % Read the ORIGINAL offered candidate set (the immutable membership reference).
    get_dict(candidates, State0, Candidates),
    % Read the dopamine-gained candidates from the synaptic stratum.
    get_dict(gained, State0, Gained),
    % Read the running token counter.
    get_dict(token, State0, Token0),
    % Run the selection pipeline THROUGH the membership guard.
    region_stratum_select(Candidates, Gained, Tentative),
    % Advance the token by one for this hop.
    Token is Token0 + 1,
    % Record and print the region hop; the beat arrived VIA the Lattice.
    neural_lattice_hop(lattice, region_select, Token),
    % Narrate the tentative selection (guaranteed a member or no_selection).
    format(string(Line), "region: basal-ganglia selection = ~w (a member of the offered set, membership guard held)", [Tentative]),
    % Print the narration line.
    neural_lattice_narrate('      ', Line),
    % Add the tentative selection to the state for the override stratum above.
    State1 = State0.put(_{tentative: Tentative, token: Token}),
    % Post the phase-2 cue: hand the beat to the next slot by NUMBER, naming no stratum.
    neural_lattice_post_cue(Nexus, 2, State1).

% ---------------------------------------------------------------------------
% The structure records (co-located with the runtime, the verdict's stratum-primary stance).
% ---------------------------------------------------------------------------

% -- region_stratum_stratum(-Out): the brain-region stratum record (ordinal 9).
region_stratum_stratum(Out) :-
    % Mint the region stratum with the anatomy's fields (the shared neuroendocrine ladder).
    cm_stratum("region", "neuroendocrine", 9, "brain_region", ["systems_neuroscience"], Out).

% -- region_stratum_basal_ganglia_continuant(-Out): the basal-ganglia selector bearer.
region_stratum_basal_ganglia_continuant(Out) :-
    % Mint the basal-ganglia continuant (the selector's physical bearer).
    cm_cnt("basal_ganglia", "object", Out).

% -- region_stratum_intake_occurrent(-Out): the candidate-intake process, at the region stratum.
region_stratum_intake_occurrent(Out) :-
    % Read this pack's own stratum id.
    region_stratum_stratum(SRegion),
    % Mint the candidate-intake occurrent.
    cm_occ("candidate_intake", "process", SRegion.id, Out).

% -- region_stratum_action_occurrent(-Out): the action-selection process (what the override suppresses).
region_stratum_action_occurrent(Out) :-
    % Read this pack's own stratum id.
    region_stratum_stratum(SRegion),
    % Mint the action-selection occurrent.
    cm_occ("action_selection", "process", SRegion.id, Out).

% -- region_stratum_emission_occurrent(-Out): the action-emission event, at the region stratum.
region_stratum_emission_occurrent(Out) :-
    % Read this pack's own stratum id.
    region_stratum_stratum(SRegion),
    % Mint the action-emission occurrent.
    cm_occ("action_emission", "event", SRegion.id, Out).

% -- region_stratum_selection_realizable(-Out): the action-selection disposition of the basal ganglia.
region_stratum_selection_realizable(Out) :-
    % Read the basal-ganglia bearer id.
    region_stratum_basal_ganglia_continuant(CBG),
    % Mint the selection disposition it bears.
    cm_rlz(CBG.id, "disposition", "action_selection", Out).

% -- region_stratum_candidate_input_port(-Out): the candidate input, gated by the dopaminergic gain.
region_stratum_candidate_input_port(Out) :-
    % The bearer is the basal ganglia.
    region_stratum_basal_ganglia_continuant(CBG),
    % The port accepts the candidate-intake occurrent.
    region_stratum_intake_occurrent(OIntake),
    % It also accepts the synaptic dopaminergic gain (a downward reference to synaptic_stratum).
    synaptic_stratum_gain_occurrent(OGain),
    % Mint the input port accepting both the intake and the gain (dopamine gates selection).
    cm_port(CBG.id, "candidate_input", "in", [OIntake.id, OGain.id], Out).

% -- region_stratum_action_output_port(-Out): the emitted-action output port.
region_stratum_action_output_port(Out) :-
    % The bearer is the basal ganglia.
    region_stratum_basal_ganglia_continuant(CBG),
    % The port emits the action-emission occurrent.
    region_stratum_emission_occurrent(OEmit),
    % Mint the output port.
    cm_port(CBG.id, "action_output", "out", [OEmit.id], Out).

% -- region_stratum_selection_cro(-Out): the selection causal_relation_object (intake -> selection).
region_stratum_selection_cro(Out) :-
    % The cause is the candidate-intake occurrent.
    region_stratum_intake_occurrent(OIntake),
    % The effect is the action-selection occurrent (both at the region stratum — no cross-stratal span).
    region_stratum_action_occurrent(OSelect),
    % Mint the selection CRO with its modality and temporal window.
    cm_cro([OIntake.id], [OSelect.id],
           [modality-"sufficient", temporal-_{minimum_delay:0, maximum_delay:1, unit:"seconds"}],
           Out).

% -- region_stratum_selection_conduit(-Out): the COMPUTATIONAL selection pathway (transform = the CRO).
region_stratum_selection_conduit(Out) :-
    % The from-port is the candidate input.
    region_stratum_candidate_input_port(PIn),
    % The to-port is the action output.
    region_stratum_action_output_port(POut),
    % The carried occurrent is the action selection.
    region_stratum_action_occurrent(OSelect),
    % The transform is the selection CRO — asserting the conduit computes (it selects, a wire cannot).
    region_stratum_selection_cro(CroSelect),
    % Mint the computational conduit.
    cm_conduit(PIn.id, POut.id, [OSelect.id], "selection_pathway", CroSelect.id, Out).

% -- region_stratum_records(-Records): this stratum's ten structure records.
region_stratum_records(Records) :-
    % Mint the stratum, the bearer, and the three occurrents.
    region_stratum_stratum(SRegion),
    region_stratum_basal_ganglia_continuant(CBG),
    region_stratum_intake_occurrent(OIntake),
    region_stratum_action_occurrent(OSelect),
    region_stratum_emission_occurrent(OEmit),
    % Mint the realizable, the two ports, the selection CRO, and the selection conduit.
    region_stratum_selection_realizable(RSel),
    region_stratum_candidate_input_port(PIn),
    region_stratum_action_output_port(POut),
    region_stratum_selection_cro(CroSelect),
    region_stratum_selection_conduit(KSelect),
    % Assemble the labelled record list.
    Records = [
        record(stratum_region,            stratum,     SRegion),
        record(continuant_basal_ganglia,  continuant,  CBG),
        record(occurrent_candidate_intake, occurrent,  OIntake),
        record(occurrent_action_selection, occurrent,  OSelect),
        record(occurrent_action_emission,  occurrent,  OEmit),
        record(realizable_action_selection, realizable, RSel),
        record(port_candidate_input,       port,       PIn),
        record(port_action_output,         port,       POut),
        record(cro_action_selection,       causal_relation_object, CroSelect),
        record(conduit_selection,          conduit,    KSelect)
    ].
