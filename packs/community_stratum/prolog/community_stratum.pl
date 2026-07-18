/*  connectome-arbiter — community_stratum (ordinal 14 -> pack layer 3): THE OVERRIDE.

    The highest tier of the OVERRIDE HIERARCHY, at the community-and-society
    stratum (Causalontology ordinal 14). A social or contextual signal can VETO
    the basal-ganglia selection from above — the cortical / contextual override
    over the direct/indirect/hyperdirect logic below it. Under the Wave 3 verdict
    this is one pack per stratum on the outside, one construct per module inside:
    the override is one sub-module, community_stratum_apply_override/5.

    THE OVERRIDE OBEYS THE SAME MEMBERSHIP INVARIANT. An override selects among
    OFFERED candidates or vetoes them; it never conjures a new one. It does not
    re-implement the guard — it REUSES region_stratum_emit/3, the single
    enforcement point, so every branch it can take yields a member of the offered
    set or an explicit no-selection. A vetoed top choice falls back to the
    highest-priority NON-vetoed offered candidate, or to no-selection if the
    context vetoes them all — never to an invented action.

    Its STRUCTURE is grounded: the community stratum, the contextual-override
    occurrent, the override causal_relation_object (community 14 -> region 9), and
    a signed provenance assertion. The override CRO crosses five strata; this thin
    cut does not model the intervening hyperdirect pathway, so it carries
    skips:true honestly (the absence of a modeled mechanism is a finding, not a
    gap — the Wave 2 slice's discipline), and classifies as a clean skip.

    It coordinates ONLY through the Lattice (phase 2 -> phase 3/done), by numbered
    cue. It imports region (Layer 2, for the action occurrent and stratum the
    override references, and the shared membership guard) — a DOWNWARD edge — plus
    the minting vocabulary and the Lattice. Its layer(3), matching ordinal 14 as
    the coarsest stratum, passes the layer rule and the N6 binding.
*/

% Declare the module: the override runtime tick, the override sub-module, and the structure accessors.
:- module(community_stratum, [
    % community_stratum_override_tick/1: the runtime step — apply the contextual override.
    community_stratum_override_tick/1,
    % community_stratum_apply_override/5: the override sub-module (membership-respecting veto).
    community_stratum_apply_override/5,
    % community_stratum_override_occurrent/1: the contextual-override occurrent record.
    community_stratum_override_occurrent/1,
    % community_stratum_override_cro/1: the override causal_relation_object (community -> region).
    community_stratum_override_cro/1,
    % community_stratum_skip_check/2: the skip classification of the override CRO.
    community_stratum_skip_check/2,
    % community_stratum_signed_assertion/1: the Ed25519-signed provenance over the override CRO.
    community_stratum_signed_assertion/1,
    % community_stratum_records/1: the labelled list of this stratum's four structure records.
    community_stratum_records/1
]).

% Import the shared minting vocabulary (Layer 0).
:- use_module(library(causal_grounding)).
% Import the Lattice substrate (Layer 0) for the runtime cue await/post and narration.
:- use_module(library(neural_lattice)).
% Import the region stratum (Layer 2) for the action occurrent, the region stratum record, and the SHARED membership guard.
:- use_module(library(region_stratum)).
% Import PrologAI's Causalontology engine (external) for the skip classification.
:- use_module(library(causal_core)).
% Import list utilities for the veto/fallback set operations.
:- use_module(library(lists)).

% ---------------------------------------------------------------------------
% THE OVERRIDE — membership-respecting, reusing the region's single guard.
% ---------------------------------------------------------------------------

% -- community_stratum_apply_override(+Context, +Candidates, +Gained, +Tentative, -Final):
% Apply the contextual veto to the region's tentative selection. Context is the list
% of vetoed actions. Every outcome is emitted THROUGH region_stratum_emit/3, so Final
% is always a member of Candidates or the explicit no_selection — never an invention.
community_stratum_apply_override(_Context, _Candidates, _Gained, no_selection, no_selection) :-
    % A tentative no-selection cannot be overridden into an action; it stays no-selection.
    !.
community_stratum_apply_override(Context, Candidates, _Gained, Tentative, Final) :-
    % When the tentative selection is NOT vetoed, it survives — re-guarded against the offered set.
    \+ memberchk(Tentative, Context),
    !,
    % Re-run the shared membership guard: an un-vetoed member passes straight through.
    region_stratum_emit(Candidates, Tentative, Final).
community_stratum_apply_override(Context, Candidates, Gained, _Tentative, Final) :-
    % The tentative selection was vetoed: fall back to the best NON-vetoed offered candidate.
    community_stratum_best_non_vetoed(Gained, Context, Candidates, Fallback),
    % Emit the fallback THROUGH the shared guard (a member, or no-selection if all were vetoed).
    region_stratum_emit(Candidates, Fallback, Final).

% -- community_stratum_best_non_vetoed(+Gained, +Context, +Candidates, -Fallback): the best allowed action.
community_stratum_best_non_vetoed(Gained, Context, Candidates, Fallback) :-
    % Keep the gained candidates whose action is neither vetoed nor absent from the offered set.
    findall(cand(A, P),
            ( member(cand(A, P), Gained),
              \+ memberchk(A, Context),
              community_stratum_is_offered(A, Candidates) ),
            Allowed),
    % When no allowed candidate remains, the honest fallback is no-selection.
    ( Allowed == []
    ->  Fallback = no_selection
    % Otherwise pick the highest-priority allowed candidate (reusing the region's compare).
    ;   region_stratum_priority_compare(Allowed, cand(Fallback, _)) ).

% -- community_stratum_is_offered(+Action, +Candidates): true when Action is in the offered set.
community_stratum_is_offered(Action, Candidates) :-
    % Succeed if some offered candidate carries this action.
    memberchk(cand(Action, _), Candidates).

% ---------------------------------------------------------------------------
% The runtime tick — Lattice-coordinated, phase 2 -> phase 3 (done).
% ---------------------------------------------------------------------------

% -- community_stratum_override_tick(+Nexus): await the tentative selection, override it, finish the episode.
community_stratum_override_tick(Nexus) :-
    % Block with no busy-poll until phase 2 (the region's tentative selection) is cued, then take it.
    neural_lattice_await_cue(Nexus, 2, State0),
    % Read the ORIGINAL offered candidate set (the immutable membership reference).
    get_dict(candidates, State0, Candidates),
    % Read the dopamine-gained candidates (for the fallback's priority order).
    get_dict(gained, State0, Gained),
    % Read the region's tentative selection.
    get_dict(tentative, State0, Tentative),
    % Read the social/contextual veto list.
    get_dict(context, State0, Context),
    % Read the running token counter.
    get_dict(token, State0, Token0),
    % Apply the contextual override THROUGH the shared membership guard.
    community_stratum_apply_override(Context, Candidates, Gained, Tentative, Final),
    % Advance the token by one for this hop.
    Token is Token0 + 1,
    % Record and print the community hop; the beat arrived VIA the Lattice.
    neural_lattice_hop(lattice, community_override, Token),
    % Narrate the override outcome (guaranteed a member or no_selection).
    format(string(Line), "community: context vetoes ~w; final selection = ~w (still a member or no_selection)", [Context, Final]),
    % Print the narration line.
    neural_lattice_narrate('      ', Line),
    % Record the final selection for the driver to read and check.
    State1 = State0.put(_{final: Final, token: Token}),
    % Post the phase-3 cue carrying this episode's final selection; the driver awaits it.
    neural_lattice_post_cue(Nexus, 3, State1).

% ---------------------------------------------------------------------------
% The structure records (co-located with the runtime, the verdict's stratum-primary stance).
% ---------------------------------------------------------------------------

% -- community_stratum_stratum(-Out): the community-and-society stratum record (ordinal 14).
community_stratum_stratum(Out) :-
    % Mint the community-and-society stratum with the anatomy's fields (the shared ladder).
    cm_stratum("community_and_society", "neuroendocrine", 14, "community", ["sociology"], Out).

% -- community_stratum_override_occurrent(-Out): the contextual-override process, at the community stratum.
community_stratum_override_occurrent(Out) :-
    % Read this pack's own stratum id.
    community_stratum_stratum(SCommunity),
    % Mint the contextual-override occurrent.
    cm_occ("contextual_override", "process", SCommunity.id, Out).

% -- community_stratum_override_cro(-Out): the override CRO (community context -> region action, skips:true).
community_stratum_override_cro(Out) :-
    % The cause is this pack's own contextual-override occurrent (community, ordinal 14).
    community_stratum_override_occurrent(OOverride),
    % The effect is the region action-selection occurrent it suppresses (region, ordinal 9).
    region_stratum_action_occurrent(OAction),
    % Mint the CRO flagged skips:true — this cut jumps community -> region without modeling the pathway.
    cm_cro([OOverride.id], [OAction.id], [skips-true], Out).

% -- community_stratum_signed_assertion(-Signed): an Ed25519-signed provenance over the override CRO.
community_stratum_signed_assertion(Signed) :-
    % Read the override CRO's content-addressed id.
    community_stratum_override_cro(CroOverride),
    % Mint and sign the provenance assertion over that id.
    cm_signed_assertion_over(CroOverride.id, Signed).

% -- community_stratum_skip_check(-Class, -Gaps): classify the override CRO and read its skip-gaps.
community_stratum_skip_check(Class, Gaps) :-
    % Mint the override CRO and its two endpoint occurrents.
    community_stratum_override_cro(CroOverride),
    community_stratum_override_occurrent(OOverride),
    region_stratum_action_occurrent(OAction),
    % Mint the two strata the CRO spans (this pack's community, and the imported region).
    community_stratum_stratum(SCommunity),
    region_stratum_stratum(SRegion),
    % Build the occurrent and stratum maps the classifier needs.
    cm_map_of([OOverride, OAction], OccMap),
    cm_map_of([SCommunity, SRegion], StratumMap),
    % Classify the cross-stratal relation (expected: skipping).
    causal_core_classify(CroOverride, OccMap, StratumMap, Class),
    % Read the skip-gaps (expected: none — skips:true makes the absence of a mechanism a positive finding).
    causal_core_skip_gaps(CroOverride, Class, Gaps).

% -- community_stratum_records(-Records): this stratum's four structure records.
community_stratum_records(Records) :-
    % Mint the stratum, the override occurrent, the override CRO, and the signed assertion.
    community_stratum_stratum(SCommunity),
    community_stratum_override_occurrent(OOverride),
    community_stratum_override_cro(CroOverride),
    community_stratum_signed_assertion(Signed),
    % Assemble the labelled record list.
    Records = [
        record(stratum_community,          stratum,                SCommunity),
        record(occurrent_contextual_override, occurrent,           OOverride),
        record(cro_contextual_override,    causal_relation_object, CroOverride),
        record(assertion_override_provenance, assertion,           Signed)
    ].
