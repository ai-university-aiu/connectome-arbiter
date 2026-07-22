/*  connectome-arbiter — the Causalontology 3.0.0 structure validator.

    Assembles the arbiter's newly-minted structure records from the three stratum
    packs (synaptic, region, community) and validates every one against PrologAI's
    UNMODIFIED Causalontology 3.0.0 conformance engine:
      - co_validate_schema/4  — the record satisfies its kind's JSON schema.
      - causal_core_validate_semantics/3 — the local semantic rules hold.
      - the contextual-override CRO classifies as SKIPPING with NO skip-gap
        (community 14 -> region 9; skips:true, honest about the un-modeled pathway).
      - the signed provenance assertion VERIFIES (Ed25519).
    These are NEW records for the selector, grounded the way the slice's were —
    not a copy of the slice's set. It writes each record to structure/<name>.json.
    Exit 0 iff every check passes.
*/

% Import the three stratum packs that each mint the selector's structure records.
:- use_module(library(synaptic_stratum)).
:- use_module(library(region_stratum)).
:- use_module(library(community_stratum)).
% Import PrologAI's Causalontology engine (identity, kind, semantics, algorithms).
:- use_module(library(causal_core)).
% Import PrologAI's JSON-schema validator (co_validate_schema/4).
:- use_module(library(schema_check)).
% Import PrologAI's signing layer (co_verify_record/2).
:- use_module(library(signing)).
% Import JSON writing for the structure artifacts.
:- use_module(library(http/json)).
% Import list utilities.
:- use_module(library(lists)).

% -- validate_structure_records(-Records): assemble every record from the three stratum packs.
validate_structure_records(Records) :-
    % Collect each stratum pack's own record list.
    synaptic_stratum_records(RSyn),
    region_stratum_records(RRegion),
    community_stratum_records(RCommunity),
    % Concatenate them, grouped by stratum (order does not affect ids or validity).
    append([RSyn, RRegion, RCommunity], Records).

% -- validate_structure_main/0: run every check, write artifacts, and halt with the verdict.
validate_structure_main :-
    % Print the banner.
    format("~n== connectome-arbiter :: Causalontology 3.0.0 structure validation ==~n~n", []),
    % Assemble the full labelled record list from the three stratum packs.
    validate_structure_records(Records),
    % Schema- and semantics-validate every record, collecting failures.
    foldl(validate_one, Records, [], SchemaFails),
    % Write each record to its structure/<name>.json artifact.
    forall(member(record(Name, _Kind, Dict), Records), write_structure_artifact(Name, Dict)),
    % Check the override CRO classifies as skipping with no skip-gap.
    validate_skip(SkipOk),
    % Check the signed provenance assertion verifies.
    validate_signature(SignOk),
    % Print the per-kind coverage summary.
    report_coverage(Records),
    % Decide the overall verdict from the three checks.
    ( SchemaFails == [], SkipOk == ok, SignOk == ok
    % Everything passed: announce success and exit 0.
    ->  length(Records, N),
        format("~nVALIDATION: PASS -- ~w records valid against Causalontology 3.0.0; skip finding and signature verified.~n~n", [N]),
        halt(0)
    % Something failed: announce and exit 1.
    ;   format("~nVALIDATION: FAIL~n", []),
        forall(member(F, SchemaFails), format("  schema/semantics fail: ~w~n", [F])),
        ( SkipOk == ok -> true ; format("  skip check fail: ~w~n", [SkipOk]) ),
        ( SignOk == ok -> true ; format("  signature check fail: ~w~n", [SignOk]) ),
        nl, halt(1) ).

% -- validate_one(+Record, +FailsIn, -FailsOut): validate one record's schema and semantics.
validate_one(record(Name, Kind, Dict), FailsIn, FailsOut) :-
    % Run the JSON-schema validation for the record's kind.
    co_validate_schema(Dict, Kind, SchemaOk, SchemaWhy),
    % Run the local semantic validation for the record's kind.
    causal_core_validate_semantics(Dict, Kind, SemReasons),
    % Combine the two outcomes into a pass/fail for this record.
    ( SchemaOk == true, SemReasons == []
    % The record passed both: print an OK line and leave the failure list unchanged.
    ->  format("  ok    ~w~t~42|~w~n", [Kind, Name]),
        FailsOut = FailsIn
    % The record failed one: print a FAIL line and record the reason.
    ;   format("  FAIL  ~w~t~42|~w  schema=~w why=~w sem=~w~n", [Kind, Name, SchemaOk, SchemaWhy, SemReasons]),
        FailsOut = [Name-schema(SchemaWhy)-semantics(SemReasons)|FailsIn] ).

% -- validate_skip(-Result): confirm the override CRO is a skipping relation with no gap.
validate_skip(Result) :-
    % Classify the override CRO and read its skip-gaps (from the community stratum pack).
    community_stratum_skip_check(Class, Gaps),
    % Print the finding.
    format("~n  skip finding: override CRO classifies as ~w; skip-gaps=~w (community 14 -> region 9)~n", [Class, Gaps]),
    % The finding is correct only when the class is skipping and there is no gap.
    ( Class == skipping, Gaps == [] -> Result = ok ; Result = wrong(Class, Gaps) ).

% -- validate_signature(-Result): confirm the signed provenance assertion verifies.
validate_signature(Result) :-
    % Fetch the signed assertion over the override CRO (from the community stratum pack).
    community_stratum_signed_assertion(Signed),
    % Verify its Ed25519 signature.
    ( co_verify_record(Signed, assertion)
    % The signature verified: report ok.
    ->  format("  signature: Ed25519 assertion over the override CRO VERIFIES~n", []),
        Result = ok
    % The signature failed to verify: report the failure.
    ;   Result = signature_did_not_verify ).

% -- report_coverage(+Records): print how many distinct Causalontology kinds the arbiter touched.
report_coverage(Records) :-
    % Collect the distinct kinds across all records.
    findall(Kind, member(record(_, Kind, _), Records), Kinds0),
    % Deduplicate them.
    sort(Kinds0, Kinds),
    % Count them.
    length(Kinds, KindCount),
    % Print the coverage line.
    format("~n  kinds touched (~w): ~w~n", [KindCount, Kinds]).

% -- write_structure_artifact(+Name, +Dict): write one record to structure/<name>.json.
write_structure_artifact(Name, Dict) :-
    % Build the artifact path under the structure/ directory.
    atomic_list_concat(['structure/', Name, '.json'], Path),
    % Open the file for writing.
    setup_call_cleanup(
        open(Path, write, Stream),
        % Write the record as pretty JSON.
        json_write_dict(Stream, Dict, [width(80)]),
        % Always close the stream.
        close(Stream)).

% Run the validator as soon as the file is loaded.
:- initialization(validate_structure_main).
