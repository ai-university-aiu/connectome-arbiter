/*  connectome-arbiter — the dedicated MEMBERSHIP-INVARIANT check.

    The safety layer's first and non-negotiable gate. It adversarially TRIES to
    make the selector emit an action that was never offered, across a battery of
    candidate sets and proposals — normal members, explicit no-selection, and
    inventions nobody offered — plus the selection pipeline and the override, and
    a TAMPERED gained set carrying a top-priority action that was never offered.

    Every emit is classified as one of: member(A) (safe), no_selection (safe),
    refused (safe — the guard threw), or ESCAPED(A) (a non-member emitted WITHOUT
    a throw — the one dangerous outcome the invariant forbids). Exit 0 iff NO
    attempt ever escaped; a single escape fails the gate.
*/

% Import the selector and its membership guard.
:- use_module(library(region_stratum)).
% Import the override that must also obey the invariant.
:- use_module(library(community_stratum)).
% Import list utilities for the adversarial battery.
:- use_module(library(lists)).

% -- try_emit(+Set, +Proposed, -Outcome): classify one guarded emit against Set.
try_emit(Set, Proposed, Outcome) :-
    % Run the guarded emit, catching the membership-violation throw as the SAFE 'refused'.
    catch(
        ( region_stratum_emit(Set, Proposed, E),
          % An emit that succeeded is safe only if it is a member or the explicit no-selection.
          ( E == no_selection
          ->  Outcome = no_selection
          ; member(cand(E, _), Set)
          ->  Outcome = member(E)
          % A succeeded emit of a non-member is the DANGER the invariant forbids.
          ;   Outcome = escaped(E) ) ),
        % The guard throwing on a non-member is the SAFE outcome.
        error(membership_violation(_, _), _),
        Outcome = refused ).

% -- try_override(+Context, +Set, +Gained, +Tentative, -Outcome): classify one override outcome.
try_override(Context, Set, Gained, Tentative, Outcome) :-
    % Run the override, catching the guard's throw as the SAFE 'refused'.
    catch(
        ( community_stratum_apply_override(Context, Set, Gained, Tentative, F),
          % The override's final selection must be a member or no-selection.
          ( F == no_selection
          ->  Outcome = no_selection
          ; member(cand(F, _), Set)
          ->  Outcome = member(F)
          % A non-member override output is the DANGER.
          ;   Outcome = escaped(F) ) ),
        error(membership_violation(_, _), _),
        Outcome = refused ).

% -- membership_battery(-Outcomes): every adversarial and normal outcome to inspect.
membership_battery(Outcomes) :-
    % The universe of actions; some are offered, some never are.
    AllActions = [a, b, c, d, e, ghost, phantom, teleport],
    % Every non-empty candidate set drawn from three of the actions (offered sets).
    findall(O,
            ( member(S1, [a,b,c,d]), member(S2, [a,b,c,d]), member(S3, [a,b,c,d]),
              sort([S1,S2,S3], SetActions), SetActions = [_|_],
              % Build a candidate set with ascending priorities.
              findall(cand(X, P), (nth0(I, SetActions, X), P is I+1), Set),
              % Its gained form (priorities carried; actions unchanged).
              findall(cand(X, PF), (member(cand(X, P), Set), PF is P*1.0), Gained),
              % ATTEMPT to emit EVERY action in the universe (members and non-members alike).
              member(Proposed, AllActions),
              try_emit(Set, Proposed, O) ),
            EmitOutcomes),
    % Add the pipeline: select over each set must yield a member.
    findall(O,
            ( member(S1, [a,b,c,d]), member(S2, [a,b,c,d]),
              sort([S1,S2], SetActions), SetActions = [_|_],
              findall(cand(X, P), (nth0(I, SetActions, X), P is I+1), Set),
              findall(cand(X, PF), (member(cand(X, P), Set), PF is P*1.0), Gained),
              region_stratum_select(Set, Gained, E),
              ( E == no_selection -> O = no_selection
              ; member(cand(E, _), Set) -> O = member(E)
              ; O = escaped(E) ) ),
            SelectOutcomes),
    % Add the override: normal, vetoed-fallback, all-vetoed, and TAMPERED gained.
    Set0 = [cand(a,1), cand(b,2), cand(c,3)],
    Gained0 = [cand(a,1.0), cand(b,2.0), cand(c,3.0)],
    Tampered = [cand(a,1.0), cand(ghost,99.0)],
    % Normal override (no veto): the tentative survives.
    try_override([],        Set0, Gained0, c, V1),
    try_override([c],       Set0, Gained0, c, V2),
    try_override([a,b,c],   Set0, Gained0, c, V3),
    try_override([b,a],     Set0, Tampered, a, V4),
    OverrideOutcomes = [V1, V2, V3, V4],
    % Assemble every outcome for inspection.
    append([EmitOutcomes, SelectOutcomes, OverrideOutcomes], Outcomes).

% -- check_membership_main/0: run the battery, report, and halt with the gate verdict.
check_membership_main :-
    % Print the banner.
    format("~n== connectome-arbiter :: membership-invariant check ==~n~n", []),
    % Run the whole adversarial battery.
    membership_battery(Outcomes),
    % Count the outcomes and the dangerous escapes.
    length(Outcomes, Total),
    include([escaped(_)]>>true, Outcomes, Escapes),
    length(Escapes, EscapeCount),
    % Count how many inventions were safely refused (the guard threw) for reassurance.
    include(==(refused), Outcomes, Refused),
    length(Refused, RefusedCount),
    % Report the tallies.
    format("  attempts inspected       : ~w~n", [Total]),
    format("  inventions refused (safe): ~w~n", [RefusedCount]),
    format("  ESCAPES (non-member out) : ~w~n", [EscapeCount]),
    % The gate holds iff not a single attempt escaped the offered set.
    ( EscapeCount =:= 0
    ->  format("~nMEMBERSHIP: PASS -- across ~w attempts, no selection ever left the offered set.~n~n", [Total]),
        halt(0)
    ;   format("~nMEMBERSHIP: FAIL -- ~w selection(s) escaped the offered set: ~w~n~n", [EscapeCount, Escapes]),
        halt(1) ).

% Run the membership check as soon as the file is loaded.
:- initialization(check_membership_main).
