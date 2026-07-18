% Test suite for the region_stratum pack — THE SELECTOR and its membership guard.
% These tests TRY to violate the membership invariant and confirm they cannot.
% Load the region_stratum module under test.
:- use_module(library(region_stratum)).
% Load PrologAI's schema validator for the structure records.
:- use_module(library(schema_check)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Load list utilities.
:- use_module(library(lists)).

% Open the test block for the region_stratum pack.
:- begin_tests(region_stratum).

% The membership guard endorses a member, permits no-selection, and REFUSES a non-member.
test(guard_classifies_correctly) :-
    % An offered set of three candidate actions.
    Set = [cand(reach, 3), cand(grasp, 5), cand(withdraw, 8)],
    % A member is endorsed as selected.
    region_stratum_membership_guard(Set, grasp, R1), assertion(R1 == selected(grasp)),
    % The explicit no-selection is permitted.
    region_stratum_membership_guard(Set, no_selection, R2), assertion(R2 == no_selection),
    % An action nobody offered is REFUSED, never endorsed.
    region_stratum_membership_guard(Set, teleport, R3), assertion(R3 == refused(teleport)).

% EMIT enforces the invariant: it emits a member or no-selection, and THROWS on a non-member.
test(emit_refuses_invented_action, [throws(error(membership_violation(teleport, _), _))]) :-
    % An offered set that does NOT contain 'teleport'.
    Set = [cand(reach, 3), cand(grasp, 5)],
    % Trying to emit an action nobody offered must throw — the invariant cannot be violated.
    region_stratum_emit(Set, teleport, _Emitted).

% EMIT passes a genuine member straight through.
test(emit_passes_member) :-
    % An offered set containing 'grasp'.
    Set = [cand(reach, 3), cand(grasp, 5)],
    % Emitting an offered action yields that action.
    region_stratum_emit(Set, grasp, E), assertion(E == grasp).

% SELECT always emits a member of the offered set (the highest priority), never an invention.
test(select_always_emits_a_member) :-
    % An offered set with distinct priorities.
    Set = [cand(reach, 3), cand(grasp, 5), cand(withdraw, 8)],
    % A gained set (dopamine preserves the actions; here priorities are simply carried).
    Gained = [cand(reach, 3.0), cand(grasp, 5.0), cand(withdraw, 8.0)],
    % The selection is the highest-priority member.
    region_stratum_select(Set, Gained, E),
    assertion(E == withdraw),
    % And the emitted action is provably a member of the offered set.
    region_stratum_actions_and_member(Set, E).

% Even if the gained set is TAMPERED to carry an action nobody offered, SELECT cannot emit it.
test(select_defeats_tampered_gained, [throws(error(membership_violation(ghost, _), _))]) :-
    % The ORIGINAL offered set (the immutable membership reference).
    Set = [cand(reach, 3), cand(grasp, 5)],
    % A tampered gained set carrying a top-priority action 'ghost' that was never offered.
    Tampered = [cand(reach, 3.0), cand(ghost, 99.0)],
    % SELECT picks 'ghost' by priority but the guard against the ORIGINAL set refuses it — a throw.
    region_stratum_select(Set, Tampered, _E).

% Priority compare picks the strictly-highest candidate.
test(priority_compare_picks_highest) :-
    % Compare a gained set.
    region_stratum_priority_compare([cand(a, 1.0), cand(b, 9.0), cand(c, 4.0)], W),
    assertion(W == cand(b, 9.0)).

% The ten structure records are all schema-valid, including the computational conduit.
test(records_valid) :-
    % Fetch the labelled records.
    region_stratum_records(Records),
    % There are exactly ten of them.
    length(Records, 10),
    % Each validates against its kind's schema.
    forall(member(record(_, Kind, Dict), Records),
           co_validate_schema(Dict, Kind, true, [])),
    % The selection conduit is present and computational (carries a transform).
    memberchk(record(conduit_selection, conduit, K), Records),
    get_dict(transform, K, _).

% Close the test block.
:- end_tests(region_stratum).

% -- region_stratum_actions_and_member(+Set, +Action): a test helper — Action is one of Set's actions.
region_stratum_actions_and_member(Set, Action) :-
    % Project the offered actions and assert membership.
    findall(A, member(cand(A, _), Set), Actions),
    memberchk(Action, Actions).
