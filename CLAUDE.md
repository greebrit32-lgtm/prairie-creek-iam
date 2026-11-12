# Prairie Creek ISD — IAM Portfolio Lab

## Who I am and why this exists
I'm Britt, a high school chemistry teacher (14 years) moving into IAM / GRC / privacy roles.
Target roles: IAM analyst/engineer, **and** GRC/compliance roles, especially at defense contractors
(CMMC compliance analyst, security compliance analyst, IAM at a contractor).
This project is three things at once:
1. Hands-on practice for the Microsoft SC-300 exam (skills measured as of Oct 28, 2026).
2. A portfolio piece showing hiring managers real Microsoft Entra configuration skills.
3. A compliance portfolio: every feature produces **evidence mapped to NIST SP 800-171 Rev 2**,
   families Access Control (3.1.x) and Identification & Authentication (3.5.x).
   Use **Rev 2, not Rev 3**, because CMMC Level 2 assesses against Rev 2.

The tenant is a fictional school district: **Prairie Creek ISD**. Microsoft no longer lets free
accounts create new tenants, so the lab uses my existing Entra directory, renamed to "Prairie Creek ISD".
Domain: `<tenant>.onmicrosoft.com`. The real value is in `config/lab.local.psd1` (gitignored), because
the default domain is derived from my personal email. Scripts read it from there. Never hard-code it.
All people and data are fictional. Never use real student, staff, or district names.

## How to work with me (most important section)
- **Teach, don't just do.** I learn by repetition. Before each task, tell me in 2–3 sentences
  what we're doing, why a real district would do it, and which SC-300 skill it covers.
- **Portal first, script second.** For every new feature, walk me through doing it by hand in the
  Entra admin center (entra.microsoft.com) first: exact menu path, which settings to choose, and why.
  Only after I've done it by hand do we script it with Microsoft Graph PowerShell.
- **Show before you run.** Show me every command that changes the tenant, explain it line by line,
  and wait for my OK before running it. Read-only commands (Get-*) can run without asking.
- **Repeat with a twist.** After I finish a task, give me a short variation to do on my own
  (for example, a second policy for a different group) and check my work afterward.
- **Quiz me.** At the end of each session, ask me 5 SC-300-style questions on what we did,
  one at a time, and explain any I miss.
- **Keep it plain.** Define jargon the first time you use it. I'm new to IT but not to systems thinking.
- **Map it.** For each feature, name the NIST SP 800-171 Rev 2 requirement(s) it supports and whether
  it's implemented, partial, or inherited from Microsoft. Paraphrase requirements in plain words; never
  paste NIST text. Remind me to check each mapping against the official Rev 2 PDF.

## Evidence rules (compliance angle)
- **Capture evidence the same week we build each feature.** Sign-in and audit logs are kept only
  30 days on P1/P2 (7 days on the free tier), and the P2 trial expires after 30 days.
- Naming: `EV-###_YYYY-MM-DD_short-name.ext`. Log every item in `evidence/evidence-register.csv`.
- Raw captures (unredacted screenshots, Graph exports) go in `evidence/raw/`, which is gitignored.
  Redacted copies go in `evidence/weekN/`.
- Redact: my Gmail-based domain/tenant name, tenant ID, IP addresses, locations, and any password.
- Evidence files never contain passwords, TAP codes, or tokens, even in `raw/`.

## Safety rules
- Sign in with delegated, interactive auth only: `Connect-MgGraph -Scopes ...` using the
  least-privilege scopes the task needs. No client secrets or certificates for my own sign-in.
- Always sign in to Graph as the lab admin, `britt.admin@<tenant>.onmicrosoft.com`,
  never my personal Gmail account. Check `Get-MgContext` before any command that changes the tenant.
- The tenant domain contains my personal email address. Remind me to blur it in every screenshot
  (or add a custom domain) before anything is published.
- Never write passwords, Temporary Access Pass codes, tenant secrets, or tokens to any file.
  Generated test passwords go to the terminal only, never to disk or git.
- Never modify the two emergency access ("break-glass") accounts. Every
  Conditional Access policy must exclude them.
- Create new Conditional Access policies in **report-only** mode first. Turn one on only after
  we've tested it with the What If tool and I've said yes.
- Don't create billable Azure resources (VMs, etc.) without asking. Budget alert is $5.
- Keep `.gitignore` covering any file with secrets, exports with real-looking data, and `*.log`.

## The district (fictional)
- 3 campuses: Prairie Creek High School, Bluebonnet Middle School, Mesquite Elementary
- Roles: Teachers, Students, Campus Admins (principals/APs), District Admins, IT Staff, Substitutes
- About 30 users to start, created from a CSV. Attributes we rely on: department (campus),
  jobTitle (role), employeeHireDate, employeeLeaveDateTime
- Fictional apps: an LMS from the Entra app gallery, a custom "Gradebook" app registration
  with app roles Teacher and Student, and a "Grants Portal" app assigned only to the restricted group
- **Restricted group: "Finance & Grants – Restricted"**: 3–4 users who handle federal grant data,
  our stand-in for CUI (Controlled Unclassified Information, the data CMMC protects).
  It gets the strictest Conditional Access set and a quarterly access review.
- **My accounts:** `britt.admin` (Global Administrator, admin tasks only) and `britt.green`
  (non-admin daily account, no roles). Separating them shows NIST 3.1.6 (use non-privileged accounts
  for non-security work).

## 5-week plan
P2 trial (30 days, one per tenant) gets activated on day 1 of Week 2 — not before.

| Week | Milestone | SC-300 area |
|---|---|---|
| 1 (free tier) | Branding, 2 break-glass accounts, bulk users via CSV, attributes, static groups (incl. "Finance & Grants – Restricted"), `britt.green` daily account, one Graph PowerShell bulk task | User identities; emergency access accounts |
| 2 | Auth methods (Authenticator, TAP, passkeys), SSPR, banned passwords, registration campaign, 5 CA policies (report-only → on), What If testing, sign-in risk. **Plus the restricted CA set** for the restricted group: phishing-resistant MFA (authentication strength), block sign-ins outside the US (named location), 4-hour sign-in frequency with no persistent browser, and require compliant device **in report-only only** (no Intune, so it's a POA&M gap) | Authentication & access management; ID Protection |
| 3 | Dynamic groups, group-based app assignment, Gradebook app registration + app roles, **"Grants Portal" app assigned only to the restricted group**, administrative units per campus, scoped roles, mover test | User identities; workload identities |
| 4 | Entitlement catalog, Substitute Teacher access package with expiration, B2B guest vendor, Terms of Use, leaver automation (Lifecycle Workflows if Governance trial activates; otherwise PowerShell offboarding script), access review, **quarterly access review of the restricted group** | Identity governance |
| 5 | PIM for Entra roles (eligible, approval, MFA, justification, 4h), PIM for Groups, privileged role review, sign-in/audit logs, one KQL query in Log Analytics, Identity Secure Score, write-up, **finish `compliance/control-mapping.md` and `compliance/poam.md`** | Identity governance; monitoring |

Every week: capture evidence for that week's features before moving on (see Evidence rules).

## Repo layout
```
/scripts/week1 ... /scripts/week5   Graph PowerShell scripts, one per task, with comment headers
/data/                              Fictional CSVs only
/docs/decisions.md                  Each config: problem, what we set, why, what I'd improve
/docs/screenshots-checklist.md      Screenshots I still need to take, checked off as I go
/docs/sc300-log.md                  Which SC-300 skills I've practiced, and quiz results
/evidence/README.md                 Naming convention and redaction rules
/evidence/evidence-register.csv     One row per evidence item (ID, date, control, file, hash)
/evidence/week1 ... /evidence/week5 Redacted evidence, safe to commit
/evidence/raw/                      Unredacted captures (gitignored)
/compliance/scope.md                What's in scope (restricted group, apps, accounts) and boundaries
/compliance/control-mapping.md      NIST SP 800-171 Rev 2 (3.1.x, 3.5.x) → lab feature → evidence ID
/compliance/poam.md                 Plan of Action & Milestones: gaps, risk, planned fix
```
After every session, update `docs/decisions.md`, `docs/screenshots-checklist.md`,
`docs/sc300-log.md`, and `evidence/evidence-register.csv`, then suggest a git commit message.

## Current status
Week 1, in progress (started 2026-11-09).
- Lab tenant: my existing directory, renamed "Prairie Creek ISD", domain `<tenant>.onmicrosoft.com`
  (free accounts can no longer create new tenants).
- Lab admin: `britt.admin@<tenant>.onmicrosoft.com`, Global Administrator, MFA registered.
  Always use this account for Graph sign-in, never my Gmail.
- ⚠️ The domain contains my personal email. Blur it in screenshots or add a custom domain before publishing.
- GRC/CMMC angle added 2026-11-12 (NIST SP 800-171 Rev 2 evidence for every feature).
- Done: break-glass accounts `pcisd-ea01` / `pcisd-ea02` (Global Admin, Authenticator; upgrade to
  passkeys in Week 2); branding (English + Spanish); Hannah Albright created by hand;
  `scripts/week1/New-PcisdUsers.ps1` written and dry-run passed (1 skipped, 29 would be created).
- Known: personal Gmail (`#EXT#`) also holds Global Admin. Review it in Week 5.
- Next: EV-001 (break-glass evidence) → add restricted-group users to the CSV → real bulk run
  (needs my OK) → `britt.green` → static groups incl. "Finance & Grants – Restricted".