# FairLens API Reference

Base URL: `http://localhost:8000`. Interactive Swagger UI at `/docs`.

Endpoints marked 🔒 require a Bearer JWT from `/api/auth/login` or a signup
endpoint. Role in parentheses where restricted.

## Health
- `GET /api/health` — app status, demo_ai_mode flag, and live MongoDB connection health

## Auth
- `POST /api/auth/signup/applicant` — `{name, email, password, confirm_password}`
- `POST /api/auth/signup/recruiter` — `{name, email, password, confirm_password, company, recruiter_role}`
- `POST /api/auth/login` — `{email, password}` → `{access_token, role, user_id, full_name}`
- `GET /api/auth/me` 🔒

## Applicants
- `POST /api/applicants/resume/upload` 🔒 (applicant) — multipart `file` (PDF/DOCX); real extraction, updates `skills`/`projects`/`candidate_evidence`
- `POST /api/applicants/resume/upload-demo` 🔒 (applicant) — Demo Mode only, fixed sample resume
- `GET /api/applicants/resume/status` 🔒 (applicant) — UPLOADED/PROCESSING/COMPLETED/FAILED
- `GET /api/applicants/skill-profile` 🔒 (applicant)
- `GET /api/applicants/dashboard` 🔒 (applicant)

## Jobs
- `GET /api/jobs` — open jobs
- `GET /api/jobs/{id}`
- `POST /api/jobs` 🔒 (recruiter) — real job-description analysis via LLMProvider
- `PUT /api/jobs/{id}/weights` 🔒 (recruiter) — validated to sum to 100%; recalculates rankings and raises a Criteria Impact warning

## Applications
- `POST /api/applications` 🔒 (applicant) — `{job_id}`; enforces resume-on-file and duplicate prevention (DB unique index)
- `GET /api/applications` 🔒 (applicant)
- `GET /api/applications/{id}`

## Assessments
- `POST /api/assessments/generate` 🔒 (applicant) — candidate-specific, 5 questions (real Claude call generates 5-10 when configured)
- `POST /api/assessments/submit` 🔒 (applicant) — deterministic MC scoring + AI-evaluated short-answer/scenario, triggers score recomputation

## Recruiter / Candidates
- `GET /api/recruiter/candidates?job_id=...` 🔒 (recruiter)
- `GET /api/recruiter/candidates/{application_id}` 🔒 — full explainable breakdown + claim-evidence gaps
- `POST /api/recruiter/candidates/{id}/accept` 🔒 (recruiter)
- `POST /api/recruiter/candidates/{id}/review` 🔒 (recruiter)
- `POST /api/recruiter/candidates/{id}/override` 🔒 (recruiter) — requires `reason`
- `POST /api/recruiter/candidates/{id}/reject` 🔒 (recruiter) — requires `reason_category`; may return `fairness_review_recommended: true` instead of completing
- `POST /api/recruiter/candidates/{id}/request-review` — applicant-initiated from Transparency Center

## Screening
- `GET /api/screening?job_id=...` 🔒 (recruiter) — blind candidate list; response contains **no** name/gender/photo/location fields (enforced by what collections the handler queries, not by hiding fields client-side)

## Fairness
- `GET /api/fairness/investigations` 🔒 (recruiter)
- `GET /api/fairness/investigations/{warning_id}` 🔒 (recruiter)
- `PUT /api/fairness/investigations/{warning_id}/status` 🔒 (recruiter) — OPEN/UNDER_REVIEW/RESOLVED/DISMISSED
- `POST /api/fairness/simulate-weights` 🔒 (recruiter) — hypothetical ranking, not persisted

## Audit
- `GET /api/audit?category=...` 🔒 (recruiter) — category: `ai|recruiter|criteria|fairness|overrides`

## Transparency
- `GET /api/transparency/{application_id}` — applicant-facing summary; no auth required (candidate_code, not identity, is the lookup key)

## Demo Mode
- `GET /api/demo/status` — whether demo data has been seeded
- `POST /api/demo/seed` — idempotent; creates demo users/job/candidates tagged `{"demo": true}`
- `POST /api/demo/clear` — removes all demo-tagged documents, leaves real accounts untouched
