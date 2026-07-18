/*  connectome-arbiter — the runner (the Wave 4 safety layer).

    Exercises the basal-ganglia action selector over a set of selection episodes
    and prints the narrated, glass-box trace. Each stratum runs as a PrologAI
    cyclic_actor (a background thread) and they coordinate ONLY through the Lattice
    by numbered phase cues — synaptic gain (phase 0 -> 1), region selection
    (1 -> 2), community override (2 -> 3) — stigmergy for state, notification for
    reactivity, zero actor-to-actor references, no busy-poll.

    THE MEMBERSHIP INVARIANT IS CHECKED TWICE: once inside the selector (the emit
    sub-module refuses to output a non-member) and once again here, independently,
    by the driver on every episode's final selection. The run exits 0 ONLY if the
    invariant held on EVERY episode — the output was always a member of that
    episode's offered candidate set, or an explicit no-selection.

    Usage:  swipl ... bin/run_arbiter.pl
*/

% Import PrologAI's actors pack for the cyclic_actor background threads.
:- use_module(library(cyclic_actor)).
% Import the arbiter's Lattice substrate: open/reset/seed/cue/narrate.
:- use_module(library(neural_lattice)).
% Import PrologAI's Lattice directly for the driver's BOUNDED await on the final cue.
:- use_module(library(lattice)).
% Import the three stratum packs for their runtime ticks.
:- use_module(library(synaptic_stratum)).
:- use_module(library(region_stratum)).
:- use_module(library(community_stratum)).
% Import list utilities for the episode loop and the membership check.
:- use_module(library(lists)).

% -- run_arbiter/0: spawn the strata, run the episodes, prove the invariant, halt.
run_arbiter :-
    % Open (or reuse) the arbiter's single coordination nexus.
    neural_lattice_open(Nexus),
    % Wipe any facts and trace from a prior run for a clean start.
    neural_lattice_reset(Nexus),
    % Print the run banner.
    run_arbiter_banner,
    % Spawn the three stratum threads; each blocks on its own phase cue (no busy-poll).
    cyclic_actor(synaptic_gain,     synaptic_stratum:synaptic_stratum_gain_tick(Nexus), 0),
    cyclic_actor(region_select,     region_stratum:region_stratum_select_tick(Nexus),   0),
    cyclic_actor(community_override, community_stratum:community_stratum_override_tick(Nexus), 0),
    % The fixed set of selection episodes exercising normal, vetoed, and all-vetoed cases.
    run_arbiter_episodes(Episodes),
    % Run every episode through the pipeline, threading the token and collecting the results.
    run_arbiter_loop(Nexus, Episodes, 0, Results),
    % Stop the three stratum threads now that the run is complete.
    run_arbiter_stop_actors,
    % Print the verdict and halt with success only if the invariant held on every episode.
    ( run_arbiter_verdict(Results) -> halt(0) ; halt(1) ).

% -- run_arbiter_episodes(-Episodes): the fixed selection episodes (candidate set, dopamine, veto).
run_arbiter_episodes([
    % A normal selection: three candidates, no veto — the highest priority wins.
    episode(1, [cand(reach,3), cand(grasp,5), cand(withdraw,8)], 0.5, []),
    % An override: the context vetoes the top choice, so the selector falls back to the next offered.
    episode(2, [cand(reach,3), cand(grasp,5), cand(withdraw,8)], 0.5, [withdraw]),
    % A total veto: every offered action is suppressed, so the safe outcome is no-selection.
    episode(3, [cand(reach,3), cand(grasp,5)], 0.0, [reach, grasp]),
    % A single candidate: the only offered action is selected.
    episode(4, [cand(hold,1)], 0.0, []),
    % High dopamine: the gain raises vigour but never changes WHICH offered action wins.
    episode(5, [cand(left,2), cand(right,4)], 2.0, [])
]).

% -- run_arbiter_banner/0: print the run header.
run_arbiter_banner :-
    % Print the arbiter name.
    format("~n== connectome-arbiter :: the basal-ganglia action selector (Wave 4 safety layer) ==~n", []),
    % Print the coordination discipline.
    format("Strata: synaptic gain -> region selection -> community override; via the Lattice; zero actor-to-actor refs; no busy-poll~n", []),
    % Print the sacred invariant.
    format("INVARIANT: every emitted selection is a member of the offered candidate set, or an explicit no-selection.~n", []).

% -- run_arbiter_loop(+Nexus, +Episodes, +TokenIn, -Results): run each episode, collect result(N,Final,Ok).
run_arbiter_loop(_Nexus, [], _Token, []).
run_arbiter_loop(Nexus, [episode(N, Candidates, Dopamine, Context)|T], TokenIn, [result(N, Final, Ok)|RT]) :-
    % Announce the episode.
    format("~n-- episode ~w: candidates=~w dopamine=~w veto=~w --~n", [N, Candidates, Dopamine, Context]),
    % Build the seed state carrying the immutable offered candidate set and the episode inputs.
    Seed = _{ episode:N, candidates:Candidates, dopamine:Dopamine, context:Context, token:TokenIn },
    % Post the phase-0 cue: the synaptic gain wakes and the pipeline begins.
    neural_lattice_post_cue(Nexus, 0, Seed),
    % Block (bounded) until the community override posts this episode's final selection on phase 3.
    ( run_arbiter_await_final(Nexus, Done)
    % The episode completed: read the final selection and the token.
    ->  get_dict(final, Done, Final),
        get_dict(token, Done, TokenMid)
    % The episode stalled: record a stall (which fails the invariant check below).
    ;   Final = stalled, TokenMid = TokenIn ),
    % INDEPENDENTLY re-check the membership invariant on the final selection.
    run_arbiter_membership_ok(Candidates, Final, Ok),
    % Report the independent invariant verdict for this episode.
    format("   INVARIANT CHECK: final=~w  is-member-or-no-selection=~w~n", [Final, Ok]),
    % Continue with the next episode, threading the token forward.
    run_arbiter_loop(Nexus, T, TokenMid, RT).

% -- run_arbiter_await_final(+Nexus, -State): a BOUNDED await on the phase-3 final cue.
run_arbiter_await_final(Nexus, State) :-
    % Block up to 30 seconds for the phase-3 cue (fails on timeout rather than hanging).
    lattice_await(Nexus, phase_3, 30, _, _),
    % Consume exactly one phase-3 cue, yielding this episode's final state.
    lattice_take(Nexus, phase_3, [State], _).

% -- run_arbiter_membership_ok(+Candidates, +Final, -Ok): the driver's independent invariant check.
run_arbiter_membership_ok(_Candidates, no_selection, true) :-
    % An explicit no-selection satisfies the invariant.
    !.
run_arbiter_membership_ok(Candidates, Final, true) :-
    % A final action that is a member of the offered set satisfies the invariant.
    member(cand(Final, _), Candidates),
    !.
run_arbiter_membership_ok(_Candidates, _Final, false).
    % Anything else — an emitted action nobody offered, or a stall — VIOLATES the invariant.

% -- run_arbiter_stop_actors/0: stop each stratum thread, tolerating an already-stopped one.
run_arbiter_stop_actors :-
    % Stop each of the three strata in turn, ignoring any that already exited.
    forall(member(Name, [synaptic_gain, region_select, community_override]),
           ignore(catch(cyclic_actor_stop(Name), _, true))).

% -- run_arbiter_verdict(+Results): print the verdict; succeed iff the invariant held on every episode.
run_arbiter_verdict(Results) :-
    % Count the episodes and the ones whose invariant check held.
    length(Results, Total),
    include(run_arbiter_result_ok, Results, Held),
    length(Held, HeldCount),
    % Print the verdict block.
    format("~n-- membership invariant verdict --~n", []),
    format("  episodes                 : ~w~n", [Total]),
    format("  invariant held on        : ~w of ~w~n", [HeldCount, Total]),
    format("  actor-to-actor refs      : 0 (strata share only the Lattice; verified by bin/check_no_coupling.sh)~n", []),
    format("  busy-poll                : none (lattice_await blocks on a queue; woken by lattice_notify)~n", []),
    % The verdict holds only if EVERY episode's selection was a member or no-selection.
    ( HeldCount =:= Total
    ->  format("  VERDICT                  : pass (no selection ever left the offered set)~n~n", [])
    ;   format("  VERDICT                  : FAIL (an emitted selection escaped the offered set)~n~n", []),
        fail ).

% -- run_arbiter_result_ok(+Result): true when an episode's invariant check held.
run_arbiter_result_ok(result(_, _, true)).

% Run the arbiter as soon as the file is loaded (the shell script sets the library path).
:- initialization(run_arbiter).
