/*  connectome-arbiter (Wave 4, the safety layer) — causal_grounding (Layer 0): the shared minting vocabulary, reused from the atomic arm.

    THE DELIBERATE SHARED-INFRASTRUCTURE DECISION (recorded in COMPARISON.md).
    The atomic rule is one pack per named construct, and every construct that is
    grounded mints its OWN Causalontology 3.0.0 record in its OWN pack. But the
    HOW of minting — stamping a content-addressed id, folding extra key-value
    pairs, deriving the deterministic signing key — is not a construct; it is
    vocabulary. Re-implementing these fourteen helpers inside each of the nine
    record-owning packs would be pure duplication, not granularity. So the
    minting VOCABULARY is kept as one shared substrate pack (exactly as the
    slice leaned on PrologAI's causal_core engine), while the record DEFINITIONS
    are distributed one-per-construct. This is the atomic arm's answer to the
    order's question "how does atomic granularity handle shared infrastructure?"

    Every helper here is reused VERBATIM from the Wave 2 slice's causal_map pack,
    so that a record minted in any atomic pack has byte-identical content — and
    therefore a byte-identical content-addressed id — to the same record in the
    slice. The DATA is held constant; only the pack boundaries move.

    It imports only PrologAI's library(causal_core) and library(signing)
    (EXTERNAL — resolved on the library path, invisible to the arm's own layer
    graph), so its declared layer(0) has no intra-arm upward edge.
*/

% Declare the module and the fourteen shared minting helpers it exports.
:- module(causal_grounding, [
    % cm_id/2: stamp a content object with its Causalontology id.
    cm_id/2,
    % cm_stratum/6: mint a stratum record.
    cm_stratum/6,
    % cm_occ/4: mint a stratified occurrent record.
    cm_occ/4,
    % cm_cnt/3: mint a continuant (bearer) record.
    cm_cnt/3,
    % cm_rlz/4: mint a realizable record.
    cm_rlz/4,
    % cm_port/6: mint a port record bearing a realizable.
    cm_port/6,
    % cm_port/5: mint a port record with no realizable.
    cm_port/5,
    % cm_conduit/6: mint a computational conduit (with a transform).
    cm_conduit/6,
    % cm_conduit/5: mint a transmissive conduit (no transform).
    cm_conduit/5,
    % cm_cro/4: mint a causal_relation_object with extra key-value fields.
    cm_cro/4,
    % cm_put_pair/3: fold one key-value pair into a dict.
    cm_put_pair/3,
    % cm_bridge/4: mint a cross-stratal bridge record.
    cm_bridge/4,
    % cm_token/4: mint a token occurrence (an episode).
    cm_token/4,
    % cm_key/3: derive the deterministic Ed25519 keypair for a name.
    cm_key/3,
    % cm_map_of/2: build an id-keyed dict of a list of objects.
    cm_map_of/2,
    % cm_signed_assertion_over/2: mint an Ed25519-signed assertion over a record id.
    cm_signed_assertion_over/2
]).

% Import PrologAI's Causalontology engine for content identity, kind inference, and signing keys.
:- use_module(library(causal_core)).
% Import PrologAI's signing layer for the record signature.
:- use_module(library(signing)).
% Import SHA hashing for the deterministic keypair seed (the co_key convention).
:- use_module(library(sha)).
% Import dict/list utilities.
:- use_module(library(lists)).

% -- cm_id(+Body, -Out): stamp a content object with its Causalontology id.
cm_id(Body, Out) :-
    % Compute the content-addressed id (kind inferred from the body's type field).
    causal_core_identify(Body, _, Id),
    % Attach the id, yielding the complete record.
    put_dict(id, Body, Id, Out).

% -- cm_stratum(+Label, +Scheme, +Ordinal, +Unit, +Governs, -Out): a stratum record.
cm_stratum(Label, Scheme, Ordinal, Unit, Governs, Out) :-
    % Build the stratum body with its required fields.
    B0 = _{type:"stratum", label:Label, scheme:Scheme, ordinal:Ordinal, unit:Unit, governs:Governs},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_occ(+Label, +Category, +StratumId, -Out): a stratified occurrent record.
cm_occ(Label, Category, StratumId, Out) :-
    % Build the occurrent body carrying its stratum id (identity-bearing).
    B0 = _{type:"occurrent", label:Label, category:Category, stratum:StratumId},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_cnt(+Label, +Category, -Out): a continuant (bearer) record.
cm_cnt(Label, Category, Out) :-
    % Build the continuant body.
    B0 = _{type:"continuant", label:Label, category:Category},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_rlz(+Bearer, +Kind, +Label, -Out): a realizable record.
cm_rlz(Bearer, Kind, Label, Out) :-
    % Build the realizable body (a disposition/function/role borne by a continuant).
    B0 = _{type:"realizable", kind:Kind, bearer:Bearer, label:Label},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_port(+Bearer, +Label, +Direction, +Accepts, +Realizable, -Out): a port record.
cm_port(Bearer, Label, Direction, Accepts, Realizable, Out) :-
    % Build the port body carrying its optional realizable id.
    B0 = _{type:"port", bearer:Bearer, label:Label, direction:Direction, accepts:Accepts, realizable:Realizable},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_port(+Bearer, +Label, +Direction, +Accepts, -Out): a port with no realizable.
cm_port(Bearer, Label, Direction, Accepts, Out) :-
    % Build the port body without a realizable field.
    B0 = _{type:"port", bearer:Bearer, label:Label, direction:Direction, accepts:Accepts},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_conduit(+From, +To, +Carries, +Label, +Transform, -Out): a computational conduit.
cm_conduit(From, To, Carries, Label, Transform, Out) :-
    % Build the conduit body WITH a transform id — asserting it is COMPUTATIONAL.
    B0 = _{type:"conduit", from:From, to:To, carries:Carries, label:Label, transform:Transform},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_conduit(+From, +To, +Carries, +Label, -Out): a transmissive conduit.
cm_conduit(From, To, Carries, Label, Out) :-
    % Build the conduit body WITHOUT a transform — asserting it is TRANSMISSIVE.
    B0 = _{type:"conduit", from:From, to:To, carries:Carries, label:Label},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_cro(+Causes, +Effects, +Extra, -Out): a causal_relation_object with extra Key-Value fields.
cm_cro(Causes, Effects, Extra, Out) :-
    % Build the minimal CRO body.
    B0 = _{type:"causal_relation_object", causes:Causes, effects:Effects},
    % Fold each extra Key-Value pair into the body (modality, temporal, skips).
    foldl(cm_put_pair, Extra, B0, B1),
    % Stamp the id.
    cm_id(B1, Out).

% -- cm_put_pair(+Key-Value, +DictIn, -DictOut): add one Key-Value pair to a dict.
cm_put_pair(K-V, D, O) :-
    % Insert the pair.
    put_dict(K, D, V, O).

% -- cm_bridge(+Coarse, +Fine, +Relation, -Out): a cross-stratal bridge record.
cm_bridge(Coarse, Fine, Relation, Out) :-
    % Build the bridge body relating one coarse occurrent to finer ones.
    B0 = _{type:"bridge", coarse:Coarse, fine:Fine, relation:Relation},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_token(+Instantiates, +Interval, +Observer, -Out): a token occurrence (an episode).
cm_token(Instantiates, Interval, Observer, Out) :-
    % Build the token body with its observer (local-by-default: it belongs to one source).
    B0 = _{type:"token_occurrence", instantiates:Instantiates, interval:Interval, observer:Observer},
    % Stamp the id.
    cm_id(B0, Out).

% -- cm_key(+Name, -Secret, -Public): the deterministic Ed25519 keypair for a name (co_key convention).
cm_key(Name, Secret, Public) :-
    % Build the seed string "key:<Name>".
    atomic_list_concat(['key:', Name], KeyString),
    % Hash it with SHA-256 to a 32-byte seed.
    sha_hash(KeyString, Seed, [algorithm(sha256), encoding(utf8)]),
    % Derive the keypair; Public is "ed25519:<hex>".
    co_keypair_from_seed(Seed, Secret, Public).

% -- cm_map_of(+Objs, -Dict): a dict keyed by each object's atomized id.
cm_map_of(Objs, Dict) :-
    % Pair each object with its id as an atom key.
    findall(KA-O, (member(O, Objs), get_dict(id, O, Id), atom_string(KA, Id)), Pairs),
    % Deduplicate by key.
    sort(1, @<, Pairs, Uniq),
    % Assemble the id-keyed dict.
    dict_pairs(Dict, _, Uniq).

% -- cm_signed_assertion_over(+AboutId, -Signed): an Ed25519-signed assertion over a record id.
cm_signed_assertion_over(AboutId, Signed) :-
    % Derive the arm's deterministic signing key (the name is held constant: connectome_slice).
    cm_key("connectome_slice", Secret, Public),
    % Build the assertion body naming the signer (source) and its evidence.
    Body = _{type:"assertion", about:AboutId, evidence_type:"observation",
             confidence:0.9, timestamp:"2026-07-17T01:00:00Z", source:Public},
    % Sign it: this stamps both the content id and the Ed25519 signature.
    co_sign_record(Body, Secret, assertion, Signed).
