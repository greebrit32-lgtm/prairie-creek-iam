# Prairie Creek ISD — Microsoft Entra ID & NIST 800-171 Lab

A hands-on identity and access management (IAM) lab built in a live Microsoft Entra ID tenant for a
**fictional** Texas school district. Every feature is configured by hand in the Entra admin center first,
then automated with Microsoft Graph PowerShell, and **documented as compliance evidence mapped to
NIST SP 800-171 Rev 2** (the standard CMMC Level 2 assesses against).

I'm a 14-year high school teacher moving into IAM and GRC. I hold **Microsoft SC-300 (Identity and Access
Administrator)** and **CompTIA Security+ (SY0-701)**. This lab puts those skills into practice and shows how
I'd build, test, and evidence identity controls.

> **Status: Week 1 of 5, in progress.** The table below shows only what's built today.

## Status

| Area | Status | What exists |
|---|---|---|
| Tenant setup & branding | ✅ Done | Custom sign-in branding in **English and Spanish** |
| Emergency access (break-glass) accounts | ✅ Done | 2 cloud-only Global Admin accounts, created by hand; evidence EV-001 |
| Bulk user provisioning | ✅ Done | 33 fictional users across 3 campuses + District Office, with job title, department, employee ID, hire/leave dates; evidence EV-002 |
| Separate daily (non-admin) account | 🔄 In progress | Planned for NIST 3.1.6 |
| Groups (static, incl. a restricted finance group) | 🔄 In progress | None yet |
| MFA / auth methods, SSPR, Conditional Access | 📅 Week 2 | Includes a restricted CA set: phishing-resistant MFA, US-only, 4-hour sign-in frequency |
| Dynamic groups, app roles, admin units | 📅 Week 3 | |
| Access packages, guests, access reviews, offboarding | 📅 Week 4 | |
| PIM, logs/KQL, Secure Score, control mapping & POA&M | 📅 Week 5 | |

## Compliance evidence approach

- **Framework:** NIST SP 800-171 Rev 2, families 3.1 (Access Control) and 3.5 (Identification & Authentication).
- **Evidence register:** [`evidence/evidence-register.csv`](evidence/evidence-register.csv): each item has an ID,
  date, mapped requirements, method, and a **SHA-256 hash** of the original capture for integrity.
- **Redaction:** originals stay local (gitignored); only redacted copies are published. Rules in
  [`evidence/README.md`](evidence/README.md).
- **Reconciliation, not just screenshots:** EV-002 compares the tenant against the approved source roster
  (all present, attributes match, unique IDs, no regular user holds an admin role).
- **Scope, mapping, POA&M:** [`compliance/`](compliance/). The control-mapping table and POA&M are skeletons that
  are filled in week by week.

| Evidence | What it shows | NIST 800-171 Rev 2 |
|---|---|---|
| EV-001 | Break-glass accounts exist, are cloud-only, enabled, and hold Global Admin; full Global Admin list | 3.1.1, 3.1.5 |
| EV-002 | 33 users reconciled against the roster; forced password change at first sign-in; no admin roles | 3.5.1, 3.5.9, 3.1.5 |

## Scripts (Microsoft Graph PowerShell)

| Script | Changes tenant? | Purpose |
|---|---|---|
| [`New-PcisdUsers.ps1`](scripts/week1/New-PcisdUsers.ps1) | Yes | Bulk-creates users from CSV. Supports `-WhatIf`, skips existing users, random passwords held in memory only (never shown or saved), refuses to run as the wrong account |
| [`Get-BreakGlassEvidence.ps1`](scripts/week1/Get-BreakGlassEvidence.ps1) | No | Captures EV-001 and writes raw + redacted JSON |
| [`Get-UserRosterEvidence.ps1`](scripts/week1/Get-UserRosterEvidence.ps1) | No | Captures EV-002 roster reconciliation |

Practices: delegated sign-in with least-privilege scopes, dry run before every change, no secrets on disk,
tenant-specific values kept in a gitignored local config ([`config/lab.example.psd1`](config/lab.example.psd1)).

**AI assistance:** I use Claude Code as a tutor and pair programmer. It drafted the scripts; I reviewed each one,
ran dry runs, and approved every tenant change before it ran. Portal configuration was done by hand.

## Repo layout

```
scripts/week1–5/   Graph PowerShell, one script per task
data/              Fictional roster CSV
evidence/          Redacted evidence + register (raw originals are gitignored)
compliance/        Scope, NIST 800-171 Rev 2 control mapping, POA&M
docs/              Decisions log, screenshot checklist, SC-300 study log
assets/            Branding images
```

## Related

- [Privacy Analyst Portfolio](https://github.com/greebrit32-lgtm/privacy-portfolio): edtech vendor privacy review,
  privacy impact assessment, incident response tabletop.

---
_All people, organizations, and data are fictional. Educational lab, not affiliated with or endorsed by Microsoft._
