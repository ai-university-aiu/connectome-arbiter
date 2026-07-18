% Test suite for the synaptic_stratum pack (the dopaminergic gain).
% Load the synaptic_stratum module under test.
:- use_module(library(synaptic_stratum)).
% Load PrologAI's schema validator for the structure records.
:- use_module(library(schema_check)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Load list utilities.
:- use_module(library(lists)).

% Open the test block for the synaptic_stratum pack.
:- begin_tests(synaptic_stratum).

% The gain scales a priority monotonically and leaves it unchanged at zero dopamine.
test(gain_is_monotonic) :-
    % Zero dopamine leaves the priority untouched (baseline vigour).
    synaptic_stratum_apply_gain(5.0, 0.0, G0), G0 =:= 5.0,
    % Positive dopamine raises the priority (higher vigour).
    synaptic_stratum_apply_gain(5.0, 1.0, G1), G1 > 5.0.

% The three structure records are all schema-valid.
test(records_valid) :-
    % Fetch the labelled records.
    synaptic_stratum_records(Records),
    % There are exactly three of them.
    length(Records, 3),
    % Each validates against its kind's schema.
    forall(member(record(_, Kind, Dict), Records),
           co_validate_schema(Dict, Kind, true, [])).

% The stratum record carries ordinal 7.
test(ordinal_is_7) :-
    % The gain occurrent stamps against the synaptic stratum, whose record has ordinal 7.
    synaptic_stratum_records(Records),
    memberchk(record(stratum_synaptic, stratum, S), Records),
    get_dict(ordinal, S, 7).

% Close the test block.
:- end_tests(synaptic_stratum).
