# FairLens Demo Flow

Two ways to demo: **Demo Mode** (instant, pre-loaded data) or a **live
walkthrough** with real signup/upload/scoring. The live version is more
impressive but takes a few extra minutes.

## Option A — Demo Mode (2 minutes)

1. Landing page → click **"explore DEMO MODE"**.
2. Choose **Explore as Demo Recruiter**. This seeds (idempotently) a demo
   job and five demo candidates (`FL-1024`…`FL-1067`), tagged separately
   from any real account.
3. **Jobs → Blind Screening** — point out the crossed-out Name / Gender /
   Photograph / Location chips.
4. Click into a candidate → explainable score breakdown → claim-evidence
   gap on `FL-1044` → **Investigations** for the categorized fairness
   warnings → **Audit** to show the logged override/rejection/review
   request that come pre-seeded.

## Option B — Live walkthrough (6-8 minutes)

### 1. Sign up as an applicant
Landing → **Sign up as Applicant** → real account created in MongoDB.

### 2. Upload a real resume
Skill Profile → **Upload PDF / DOCX** with an actual resume file. Watch it
move through Uploading → Processing → extracted skills/education appear —
this is real `pypdf`/`python-docx` text extraction, not a simulation.

### 3. Apply to a job
Browse Jobs → open one → note the evaluation weights and "Initial screening
ignores name, gender, photograph and location." → **Apply Now**.

### 4. Take the AI-generated assessment
**Start Assessment** — questions are generated based on this candidate's
actual claimed skills/projects (a different candidate gets different
emphasis). Answer and submit; the score appears immediately.

### 5. Switch to a recruiter account
Sign out → **Sign up as Recruiter** (or sign back into an existing one) →
**Create Job** with your own description — point out this triggers real job
analysis, not a hardcoded parse.

### 6. Blind Screening → Candidate Detail
Open **Blind Screening** on the job the applicant applied to. Click into
the candidate: explainable breakdown, evidence, any claim-evidence gap.

### 7. Make a decision
**Override** (reason required) or **Reject** with a reason category that
isn't clearly job-related (e.g. "Other") to trigger **Fairness Review
Recommended**, then show Re-evaluate / Edit Reason / Continue with
Justification.

### 8. Audit Trail
**Audit** → filter by Overrides/Recruiter/Criteria → show the full
before/after state and reason for every action just taken.

### 9. Back to the applicant
Sign back in as the applicant → **Applications** shows the updated status →
**Transparency Center** shows what was evaluated, what was ignored, and
offers **Request Review**.

## Closing line

Every step in that walkthrough — the resume, the assessment, the score, the
decision — is a real database write. Nothing you just saw was mock data
outside of the explicit Demo Mode toggle.
