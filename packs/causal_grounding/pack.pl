% State the fact: name(causal_grounding) — the shared Causalontology minting vocabulary.
name(causal_grounding).
% State the fact: version('0.1.0') — a safety-layer prototype.
version('0.1.0').
% State the fact: title naming the pack as the shared minting helpers every stratum pack reuses.
title('Connectome arbiter — causal_grounding: the shared Causalontology 3.0.0 minting vocabulary').
% State the fact: author is the PrologAI Community.
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: home points at the connectome-arbiter repository.
home('https://github.com/ai-university-aiu/connectome-arbiter').
% State the fact: download points at the repository releases page.
download('https://github.com/ai-university-aiu/connectome-arbiter/releases').
% State the fact: requires([]) — PrologAI dependencies are declared as library imports in the module.
requires([]).
% State the fact: layer(0) — the minting vocabulary is substrate: every stratum pack imports it.
layer(0).
% NOTE: no stratum(...) fact — the minting vocabulary is NOT at a stratum, so it is
% UNBOUND under the N6 binding (a gap, never a violation), exactly as intended.
