% Test suite for the causal_grounding pack (the shared minting vocabulary).
% Load the causal_grounding module under test.
:- use_module(library(causal_grounding)).
% Load PrologAI's schema validator to confirm a minted record is well formed.
:- use_module(library(schema_check)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% Open the test block for the causal_grounding pack.
:- begin_tests(causal_grounding).

% A minted stratum carries a content-addressed id and validates against its schema.
test(stratum_mints_and_validates) :-
    % Mint the synaptic stratum exactly as the anatomy defines it.
    cm_stratum("synaptic", "neuroendocrine", 7, "synapse", ["synaptic_physiology"], S),
    % The record has an id field (the content-addressed identity).
    get_dict(id, S, _),
    % The record satisfies the stratum schema.
    co_validate_schema(S, stratum, true, []).

% The deterministic key derivation returns a stable ed25519 public key for a name.
test(key_is_deterministic) :-
    % Derive the keypair twice for the same held-constant name.
    cm_key("connectome_slice", _, Public1),
    cm_key("connectome_slice", _, Public2),
    % The public key is identical both times (a deterministic seed).
    Public1 == Public2.

% Close the test block.
:- end_tests(causal_grounding).
