# FairLens Architecture

## Layers

### Frontend (`frontend/`)
React + TypeScript + Vite. Two portals (Applicant, Recruiter) plus a shared
landing/auth flow, all talking to one backend through `src/services/api.ts`.
Auth state lives in a React context (`src/hooks/useAuth.tsx`) backed by
`localStorage`, with a JWT attached to every authenticated request. Real
file uploads go through `FormData` (`api.uploadResume`); everything else is
JSON over `fetch`.

### Backend (`backend/app/`)
FastAPI application, organized by concern:

- `db/` — `mongo.py` (connection, health check, index creation) and
  `repo.py` (shared insert/find/update helpers so every router doesn't
  reimplement UUID generation and timestamps)
- `schemas/` — Pydantic request/response shapes (auth)
- `models/application_status.py` — the single source of truth for
  application status strings
- `routers/` — one file per resource; thin, delegating real logic to
  `scoring/`, `fairness/`, `nlp/`, `services/`, `audit/`
- `scoring/scoring_engine.py` — deterministic final-score computation, pure
  functions over plain dicts (no MongoDB or LLM dependency at all)
- `fairness/` — `fairness_engine.py` (detection, writes `fairness_warnings`)
  + `investigation_service.py` (drill-down data + weight simulation)
- `nlp/` — `resume_extraction.py` (real PDF/DOCX text extraction),
  `resume_parser.py` (text → structured skills/projects/education),
  `skill_extractor.py` (evidence confidence via the trained ML model, with
  heuristic fallback), `job_analyzer.py`, `semantic_matcher.py` (SBERT with
  deterministic fallback)
- `ml/` — `train_evidence_model.py` (trains the Evidence Confidence Model
  on a synthetic-but-principled dataset) and `evidence_confidence_model.py`
  (loads the trained artifact, exposes `predict_confidence()`, falls back
  to a deterministic heuristic if the artifact or scikit-learn is
  unavailable)
- `ai/` — `llm_provider.py` (vendor-agnostic interface + lazy-singleton
  factory), `claude_provider.py` (real Claude API calls), `mock_provider.py`
  (Demo Mode), `schemas.py` (Pydantic validation for every AI output shape)
- `services/` — `file_storage.py` (upload validation + storage
  abstraction), `assessment_generator.py`, `evidence_analyzer.py`
  (claim-evidence gap), `demo_seed.py` (explicit, tagged Demo Mode data)
- `audit/audit_service.py` — single write path for the audit log
- `utils/security.py` — password hashing, JWT, role-based route guards

### Database
MongoDB via Motor (async driver), configured entirely through
`MONGODB_URI`/`MONGODB_DATABASE`. `app/db/mongo.py` is the only file that
constructs a client; every other module calls `get_db()`. Switching from
local MongoDB to Atlas, or between environments, is purely a `.env` change.

For local experimentation without any MongoDB installed,
`USE_IN_MEMORY_DB=true` swaps in `mongomock-motor`, an in-memory simulator
with an identical async API. This is explicitly a dev/test convenience —
`main.py`'s startup log makes it impossible to miss that it's active, and it
must never be set in a real deployment.

## NLP / LLM pipeline

```
resume_extraction.py  -> real text from an uploaded PDF/DOCX (pypdf / python-docx)
resume_parser.py       -> structured {skills, projects, education, certifications}
                           from that real text (regex/heuristic; LLM-assisted
                           via llm_provider.analyze_resume when Claude is configured)
skill_extractor.py     -> Evidence rows: {sources, confidence, status} per claimed skill
job_analyzer.py         -> required/preferred skills + screening exclusions for a job
semantic_matcher.py     -> similarity(requirement, evidence) in [0,1]; real SBERT if
                           `sentence-transformers` + model weights are available,
                           otherwise a deterministic lexical-overlap fallback
llm_provider.py          -> vendor-agnostic interface: analyze_resume, analyze_job,
                           generate_assessment, evaluate_answer, analyze_claim_evidence,
                           generate_explanation. ClaudeProvider validates every
                           response against a Pydantic schema and retries once on
                           malformed output before raising a controlled LLMOutputError.
```

None of these modules return a final candidate score. That is the scoring
engine's job alone, which keeps the ranking deterministic and reproducible
even though the upstream evidence extraction may involve a nondeterministic
LLM call when Claude is configured.

## Scoring

`scoring_engine.compute_score()` takes plain values (matched skills,
required skills, assessment score, projects, experience years,
certifications, weights) and returns a `ScoreBreakdown` with each component
score, the normalized weights used, earned/max points per component,
rule-based `strengths`/`gaps`, a natural-language `explanation`, and a
`recommendation` label. It has zero knowledge of demographic fields — no
name, gender, photo, or location parameter appears anywhere in its
signature, and it never touches MongoDB or an LLM.

## Fairness

`fairness_engine.py` raises `fairness_warnings` documents in six categories
(Ranking Changed, Evidence Insufficient, Criteria Impact, Recruiter
Overrides, Repeated AI Acceptance, Claim-Evidence Mismatch).
`investigation_service.py` serves drill-downs and powers the weight
simulation slider by recomputing rankings from already-stored component
scores, without writing anything, so recruiters can safely explore "what
if" scenarios.

Rejections are checked against the job's configured evaluation criteria
(`JOB_RELATED_REASONS` in `routers/candidates.py`). A reason that doesn't
map to a job-related category returns `fairness_review_recommended: true`
instead of completing the rejection — the frontend then offers
re-evaluate / edit reason / continue with justification. Nothing is ever
silently rejected.

## Audit

`audit_service.log_event()` is the single write path for `audit_events`
documents. Every router that changes state calls it with actor, action,
entity, previous/new state, and an optional reason. There is no
update/delete path for audit events by design — the log is append-only.

## Security: blind screening

`routers/screening.py` builds `BlindCandidate` rows by querying only
`applications`, `candidate_scores`, `assessments`, `skills`, `projects`, and
`fairness_warnings` — it never queries `users` or `applicant_profiles`
(where name, gender, location, and photo live) at all. The exclusion is
enforced by which MongoDB collections this code path is even capable of
reading, not by a frontend field filter.

## AI output validation

Every `LLMProviderBase` method returns a specific Pydantic model
(`app/ai/schemas.py`). `ClaudeProvider` asks the model for JSON matching
that shape, parses it, and calls `.model_validate()` before returning —
malformed JSON or a shape mismatch triggers one retry with a stricter
prompt, then raises `LLMOutputError` if it still fails. Callers (resume
upload, assessment generation/scoring) catch that exception and degrade to
a controlled state (`processing_status=FAILED`, HTTP 503 "AI processing is
temporarily unavailable") rather than trusting or crashing on unvalidated
output.
