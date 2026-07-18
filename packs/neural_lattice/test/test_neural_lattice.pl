% Test suite for the neural_lattice pack (stigmergy + notification substrate).
% Load the neural_lattice module under test.
:- use_module(library(neural_lattice)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% Open the test block for the neural_lattice pack.
:- begin_tests(neural_lattice).

% A posted phase cue can be awaited and taken back, carrying its state snapshot.
test(cue_roundtrip) :-
    % Open the slice nexus and clear it.
    neural_lattice_open(N), neural_lattice_reset(N),
    % Post a phase-0 cue carrying a small state dict.
    neural_lattice_post_cue(N, 0, _{lap:1, token:0}),
    % Await and take the phase-0 cue back.
    neural_lattice_await_cue(N, 0, S),
    % The state came back intact.
    get_dict(lap, S, 1), get_dict(token, S, 0).

% The glass-box trace records hops in order with ascending ordinals.
test(trace_records_hops) :-
    % Start from a clean trace.
    neural_lattice_trace_reset,
    % Record three hops.
    neural_lattice_hop(lattice, cortex, 1),
    neural_lattice_hop(lattice, striatum, 2),
    neural_lattice_hop(lattice, thalamus, 3),
    % Read the trace back.
    neural_lattice_trace(Hops),
    % It has three hops in the order recorded.
    Hops = [hop(1, cortex, 1), hop(2, striatum, 2), hop(3, thalamus, 3)].

% Close the test block.
:- end_tests(neural_lattice).
