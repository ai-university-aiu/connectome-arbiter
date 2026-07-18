/*  connectome-arbiter — synaptic_stratum (ordinal 7 -> pack layer 1).

    THE SELECTOR'S NEUROMODULATORY GAIN, at the synaptic level. Under the Wave 3
    verdict's rule (one pack per stratum on the outside, one construct per module
    on the inside), this pack IS the synaptic stratum (Causalontology ordinal 7).
    Its ONE runtime construct is the DOPAMINERGIC GAIN: dopamine sets the vigour
    of basal-ganglia selection by scaling the candidate priorities before the
    selector competes them. That is DYNAMICS, kept native (a rate law, never a
    causal_relation_object, per the grounding rule) — here a single sub-module,
    synaptic_stratum_apply_gain/3.

    Its STRUCTURE is grounded in Causalontology 2.0.0: the synaptic stratum
    record, the dopaminergic-gain occurrent stamped at it, and the nigral
    continuant that is the gain's source.

    It coordinates ONLY through the Lattice: its tick awaits the numbered phase-0
    cue (the candidate set for one selection episode), applies the gain, and posts
    the phase-1 cue — a NUMBER, never the name of the region selector downstream
    (zero actor-to-actor references). Imports the minting vocabulary (0) and the
    Lattice (0); its layer(1) is the lowest stratum layer, matching ordinal 7 as
    the finest stratum the arbiter touches (the N6 binding check confirms it).
*/

% Declare the module: the gain runtime tick, the native gain, and the structure accessors.
:- module(synaptic_stratum, [
    % synaptic_stratum_gain_tick/1: the runtime step — gain the candidate priorities.
    synaptic_stratum_gain_tick/1,
    % synaptic_stratum_apply_gain/3: the native dopaminergic gain of one priority.
    synaptic_stratum_apply_gain/3,
    % synaptic_stratum_gain_occurrent/1: the dopaminergic-gain occurrent record (a co-cause of selection).
    synaptic_stratum_gain_occurrent/1,
    % synaptic_stratum_records/1: the labelled list of this stratum's three structure records.
    synaptic_stratum_records/1
]).

% Import the shared minting vocabulary (Layer 0).
:- use_module(library(causal_grounding)).
% Import the Lattice substrate (Layer 0) for the runtime cue await/post and narration.
:- use_module(library(neural_lattice)).
% Import list utilities for mapping the gain across the candidate set.
:- use_module(library(lists)).

% ---------------------------------------------------------------------------
% The native dynamics (kept native per the grounding rule — no CRO for a rate law).
% ---------------------------------------------------------------------------

% -- synaptic_stratum_apply_gain(+Priority, +Dopamine, -Gained): scale a priority by the dopaminergic gain.
synaptic_stratum_apply_gain(Priority, Dopamine, Gained) :-
    % Dopamine sets the vigour: higher tone amplifies every candidate's priority uniformly.
    Gained is Priority * (1.0 + Dopamine).

% -- synaptic_stratum_gain_candidates(+Candidates, +Dopamine, -Gained): gain every candidate's priority.
synaptic_stratum_gain_candidates(Candidates, Dopamine, Gained) :-
    % Apply the gain to each cand(Action, Priority), preserving the action.
    maplist(synaptic_stratum_gain_one(Dopamine), Candidates, Gained).

% -- synaptic_stratum_gain_one(+Dopamine, +Cand, -GainedCand): gain one candidate's priority.
synaptic_stratum_gain_one(Dopamine, cand(Action, Priority), cand(Action, Gained)) :-
    % Gain this candidate's priority; the ACTION is carried through unchanged (membership is preserved).
    synaptic_stratum_apply_gain(Priority, Dopamine, Gained).

% ---------------------------------------------------------------------------
% The runtime tick — Lattice-coordinated, phase 0 -> phase 1.
% ---------------------------------------------------------------------------

% -- synaptic_stratum_gain_tick(+Nexus): await the candidate set, gain it, hand on.
synaptic_stratum_gain_tick(Nexus) :-
    % Block with no busy-poll until phase 0 (a new selection episode) is cued, then take it.
    neural_lattice_await_cue(Nexus, 0, State0),
    % Read the episode's candidate set and dopamine tone.
    get_dict(candidates, State0, Candidates),
    get_dict(dopamine, State0, Dopamine),
    % Read the running token counter.
    get_dict(token, State0, Token0),
    % Apply the dopaminergic gain to the candidate priorities (actions unchanged).
    synaptic_stratum_gain_candidates(Candidates, Dopamine, Gained),
    % Advance the token by one for this hop.
    Token is Token0 + 1,
    % Record and print the synaptic hop; the beat arrived VIA the Lattice.
    neural_lattice_hop(lattice, synaptic_gain, Token),
    % Narrate the gain in glass-box style.
    format(string(Line), "synaptic: dopamine=~3f gained ~w candidate priorities (actions unchanged)", [Dopamine, Gained]),
    % Print the narration line.
    neural_lattice_narrate('      ', Line),
    % Add the gained candidates to the state; the original candidates stay for the membership guard.
    State1 = State0.put(_{gained: Gained, token: Token}),
    % Post the phase-1 cue: hand the beat to the next slot by NUMBER, naming no region.
    neural_lattice_post_cue(Nexus, 1, State1).

% ---------------------------------------------------------------------------
% The structure records (co-located with the runtime, the verdict's stratum-primary stance).
% ---------------------------------------------------------------------------

% -- synaptic_stratum_stratum(-Out): the synaptic stratum record (ordinal 7).
synaptic_stratum_stratum(Out) :-
    % Mint the synaptic stratum with the anatomy's fields (the shared neuroendocrine ladder).
    cm_stratum("synaptic", "neuroendocrine", 7, "synapse", ["synaptic_physiology"], Out).

% -- synaptic_stratum_gain_occurrent(-Out): the dopaminergic-gain event, stamped at the synaptic stratum.
synaptic_stratum_gain_occurrent(Out) :-
    % Read this pack's own stratum id.
    synaptic_stratum_stratum(SSyn),
    % Mint the dopaminergic-gain occurrent (a state-change of selection vigour).
    cm_occ("dopaminergic_gain", "state_change", SSyn.id, Out).

% -- synaptic_stratum_source_continuant(-Out): the nigral gain source (a bearer).
synaptic_stratum_source_continuant(Out) :-
    % Mint the substantia-nigra-pars-reticulata continuant (the basal-ganglia output/gain nucleus).
    cm_cnt("substantia_nigra_pars_reticulata", "object", Out).

% -- synaptic_stratum_records(-Records): this stratum's three structure records.
synaptic_stratum_records(Records) :-
    % Mint the stratum, the gain occurrent, and the source continuant.
    synaptic_stratum_stratum(SSyn),
    synaptic_stratum_gain_occurrent(OGain),
    synaptic_stratum_source_continuant(CSource),
    % Assemble the labelled record list.
    Records = [
        record(stratum_synaptic,          stratum,    SSyn),
        record(occurrent_dopaminergic_gain, occurrent, OGain),
        record(continuant_dopamine_source, continuant, CSource)
    ].
