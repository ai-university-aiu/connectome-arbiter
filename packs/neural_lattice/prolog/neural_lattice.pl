/*  connectome-arbiter (Wave 4, the safety layer) — the neural Lattice substrate (Layer 0), reused verbatim from the Wave 2 slice.

    This pack is the slice's realisation of the CLOSURE RULE: STIGMERGY FOR
    STATE plus NOTIFICATION FOR REACTIVITY. Regions coordinate only through a
    single PrologAI Lattice nexus. They never address one another: a region
    posts a numbered PHASE CUE (phase_0, phase_1, phase_2 — a positional slot
    number, exactly the spike's "set only a NUMBER, never name who picks it
    up") and awaits its own phase cue with lattice_await/5, woken by the
    lattice_notify/1 that every Lattice write performs. There is no busy-poll:
    a region blocks on a private message queue until a write wakes it.

    Exactly one phase cue exists at any instant (each region TAKES its cue when
    it acts, then POSTS the next slot's cue), so the ring is deterministic and
    only one region is ever active — which is why the glass-box narration reads
    as a clean sequence even though three region threads are alive.

    The pack also carries the glass-box TRACE: the ordered record of every hop
    the token makes, printed live and retained so the runner can PROVE the loop
    closed (3N+1 hops, strictly monotonic token, cortex re-entered N times).

    This pack imports only PrologAI's library(lattice) — an external dependency,
    invisible to the slice's own layer graph — so its declared layer(0) has no
    intra-slice upward edge to violate.
*/

% Declare the module and its public predicates (all pack-qualified whole words).
:- module(neural_lattice, [
    % neural_lattice_open/1: open (or reuse) the slice's coordination nexus.
    neural_lattice_open/1,
    % neural_lattice_reset/1: wipe all coordination facts for a fresh run.
    neural_lattice_reset/1,
    % neural_lattice_post_cue/3: hand the beat to a numbered phase slot.
    neural_lattice_post_cue/3,
    % neural_lattice_await_cue/3: block until this phase slot is cued, then take it.
    neural_lattice_await_cue/3,
    % neural_lattice_signal_done/2: announce the loop has come to rest.
    neural_lattice_signal_done/2,
    % neural_lattice_await_done/3: block (with a timeout) for the done signal.
    neural_lattice_await_done/3,
    % neural_lattice_narrate/2: print one glass-box narration line.
    neural_lattice_narrate/2,
    % neural_lattice_hop/3: record and print one token hop through the Lattice.
    neural_lattice_hop/3,
    % neural_lattice_trace_reset/0: clear the retained hop trace.
    neural_lattice_trace_reset/0,
    % neural_lattice_trace/1: fetch the retained hop trace, in order.
    neural_lattice_trace/1
]).

% Import PrologAI's Lattice: the stigmergy door plus the await/notify bridge.
:- use_module(library(lattice)).
% Import list utilities used when reading back the ordered trace.
:- use_module(library(lists), [member/2]).
% Import aggregate_all/3 for counting retained hops.
:- use_module(library(aggregate), [aggregate_all/3]).

% The fixed nexus address for the slice (a locus:// URI, as the Lattice requires).
neural_lattice_address('locus://localhost/connectome_slice').

% -- neural_lattice_open(-Nexus): open or reuse the slice's single nexus handle.
neural_lattice_open(Nexus) :-
    % Read the fixed slice address.
    neural_lattice_address(Address),
    % Open (idempotent) the nexus at that address; lattice_open reuses an open one.
    lattice_open(Address, Nexus).

% -- neural_lattice_reset(+Nexus): remove every coordination fact for a clean run.
neural_lattice_reset(Nexus) :-
    % Retract every node-fact held on this nexus (cues, state, done markers).
    retractall(lattice:lattice_node_fact(Nexus, _, _, _, _)),
    % Clear the retained glass-box hop trace as well.
    neural_lattice_trace_reset.

% -- neural_lattice_phase_relation(+Phase, -Relation): map a slot number to its cue relation.
neural_lattice_phase_relation(Phase, Relation) :-
    % Build the relation atom phase_<N> from the numeric slot; the name is a NUMBER, not an identity.
    atom_concat(phase_, Phase, Relation).

% -- neural_lattice_post_cue(+Nexus, +Phase, +State): hand the beat to a phase slot.
neural_lattice_post_cue(Nexus, Phase, State) :-
    % Resolve the numbered phase slot to its cue relation.
    neural_lattice_phase_relation(Phase, Relation),
    % Put the cue carrying the whole state snapshot; lattice_put notifies all waiters.
    lattice_put(Nexus, Relation, [State], []).

% -- neural_lattice_await_cue(+Nexus, +Phase, -State): block for this slot's cue, then take it.
neural_lattice_await_cue(Nexus, Phase, State) :-
    % Resolve the numbered phase slot to its cue relation.
    neural_lattice_phase_relation(Phase, Relation),
    % Block with NO CPU until the cue exists (woken by lattice_notify); infinite timeout.
    lattice_await(Nexus, Relation, infinite, _, _),
    % Consume exactly one matching cue so no stale cue can re-fire (removes it, notifies).
    lattice_take(Nexus, Relation, [State], _).

% -- neural_lattice_signal_done(+Nexus, +Token): announce the loop has come to rest.
neural_lattice_signal_done(Nexus, Token) :-
    % Post a single done marker carrying the final token value; notifies the driver's awaiter.
    lattice_put(Nexus, done, [Token], []).

% -- neural_lattice_await_done(+Nexus, +Timeout, -Token): wait (bounded) for the done marker.
neural_lattice_await_done(Nexus, Timeout, Token) :-
    % Block until the done marker appears or the timeout lapses (fails on timeout).
    lattice_await(Nexus, done, Timeout, [Token], _).

% ---------------------------------------------------------------------------
% Glass-box trace — the deliberate legibility debt the CLOSURE RULE asks us to pay.
% ---------------------------------------------------------------------------

% Declare the retained hop record as dynamic: hop(Ordinal, Region, Token).
:- dynamic neural_lattice_hop_record/3.

% -- neural_lattice_trace_reset/0: forget every recorded hop.
neural_lattice_trace_reset :-
    % Retract all retained hop records so a new run starts from an empty trace.
    retractall(neural_lattice_hop_record(_, _, _)).

% -- neural_lattice_hop(+Via, +Region, +Token): record and print one token hop.
neural_lattice_hop(Via, Region, Token) :-
    % Count the hops recorded so far to assign this hop its ordinal.
    aggregate_all(count, neural_lattice_hop_record(_, _, _), Prior),
    % This hop's ordinal is one past the number already recorded.
    Ordinal is Prior + 1,
    % Retain the hop so the runner can later prove the loop closed.
    assertz(neural_lattice_hop_record(Ordinal, Region, Token)),
    % Print the glass-box line: the medium the beat arrived through, who acted, the token now.
    format("    hop ~w  via ~w  ~w  token=~w~n", [Ordinal, Via, Region, Token]).

% -- neural_lattice_trace(-Hops): the ordered list of hop(Ordinal, Region, Token) terms.
neural_lattice_trace(Hops) :-
    % Collect every recorded hop as an ordinal-keyed pair.
    findall(Ordinal-hop(Ordinal, Region, Token),
            neural_lattice_hop_record(Ordinal, Region, Token),
            Pairs),
    % Sort by ordinal (keysort keeps insertion-independent order).
    keysort(Pairs, Sorted),
    % Drop the sort keys, leaving the hop terms in order.
    findall(H, member(_-H, Sorted), Hops).

% -- neural_lattice_narrate(+Indent, +Line): print one narration line at an indent.
neural_lattice_narrate(Indent, Line) :-
    % Print the indent then the line then a newline, for a readable glass-box trace.
    format("~w~w~n", [Indent, Line]).
