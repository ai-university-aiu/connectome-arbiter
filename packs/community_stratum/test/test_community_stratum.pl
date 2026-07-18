% Test suite for the community_stratum pack — the contextual override.
% These tests confirm the override obeys the membership invariant on every branch.
% Load the community_stratum module under test.
:- use_module(library(community_stratum)).
% Load PrologAI's schema validator for the structure records.
:- use_module(library(schema_check)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Load list utilities.
:- use_module(library(lists)).

% Open the test block for the community_stratum pack.
:- begin_tests(community_stratum).

% An un-vetoed tentative selection survives the override unchanged.
test(unvetoed_survives) :-
    % An offered set and its gained form.
    Set = [cand(reach, 3), cand(grasp, 5), cand(withdraw, 8)],
    Gained = [cand(reach, 3.0), cand(grasp, 5.0), cand(withdraw, 8.0)],
    % With no veto, the tentative 'withdraw' survives.
    community_stratum_apply_override([], Set, Gained, withdraw, Final),
    assertion(Final == withdraw).

% A vetoed tentative selection falls back to the best NON-vetoed OFFERED candidate.
test(vetoed_falls_back_to_member) :-
    % An offered set and its gained form.
    Set = [cand(reach, 3), cand(grasp, 5), cand(withdraw, 8)],
    Gained = [cand(reach, 3.0), cand(grasp, 5.0), cand(withdraw, 8.0)],
    % The context vetoes the top choice 'withdraw'; the fallback is the next best OFFERED action, 'grasp'.
    community_stratum_apply_override([withdraw], Set, Gained, withdraw, Final),
    assertion(Final == grasp),
    % And the fallback is provably a member of the offered set.
    memberchk(cand(Final, _), Set).

% When the context vetoes EVERY offered action, the override yields no_selection — never an invention.
test(all_vetoed_yields_no_selection) :-
    % An offered set and its gained form.
    Set = [cand(reach, 3), cand(grasp, 5)],
    Gained = [cand(reach, 3.0), cand(grasp, 5.0)],
    % Every offered action is vetoed.
    community_stratum_apply_override([reach, grasp], Set, Gained, grasp, Final),
    % The only safe outcome is the explicit no-selection.
    assertion(Final == no_selection).

% The override CANNOT be steered to an invented action even by a rigged, tampered gained set.
test(override_cannot_invent) :-
    % An offered set and a gained set TAMPERED to carry an un-offered top-priority action 'ghost'.
    Set = [cand(reach, 3), cand(grasp, 5)],
    Tampered = [cand(reach, 3.0), cand(ghost, 99.0)],
    % Veto BOTH real offered actions so the override must reach for a fallback.
    community_stratum_apply_override([grasp, reach], Set, Tampered, grasp, Final),
    % The fallback filter excludes 'ghost' (it was never OFFERED), so the safe outcome is no-selection —
    % the invariant holds by TWO layers: 'ghost' is filtered before it can even reach the guard.
    assertion(Final == no_selection),
    % And whatever the outcome, it is provably a member of the offered set or an explicit no-selection.
    assertion(( Final == no_selection ; memberchk(cand(Final, _), Set) )).

% The override CRO classifies as a clean skip (community 14 -> region 9, skips:true, no gap).
test(override_is_a_clean_skip) :-
    % Classify the cross-stratal override relation.
    community_stratum_skip_check(Class, Gaps),
    assertion(Class == skipping),
    assertion(Gaps == []).

% The four structure records are all schema-valid, and the provenance assertion is signed.
test(records_valid) :-
    % Fetch the labelled records.
    community_stratum_records(Records),
    % There are exactly four of them.
    length(Records, 4),
    % Each validates against its kind's schema.
    forall(member(record(_, Kind, Dict), Records),
           co_validate_schema(Dict, Kind, true, [])),
    % The signed provenance assertion carries a signature.
    community_stratum_signed_assertion(Signed),
    get_dict(signature, Signed, _).

% Close the test block.
:- end_tests(community_stratum).
