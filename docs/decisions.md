# Configuration Decisions

Each entry: **Problem** → **What we set** → **Why** → **What I'd improve**

---

## 2026-11-09 — Lab tenant choice
- **Problem:** Microsoft no longer lets free accounts create brand-new Entra tenants.
- **What we set:** Renamed my existing directory to "Prairie Creek ISD" (domain `<tenant>.onmicrosoft.com`; real value in `config/lab.local.psd1`, gitignored).
  Created a dedicated lab admin, `britt.admin@…`, with Global Administrator and MFA.
- **Why:** A dedicated admin account keeps lab work separate from my personal Microsoft account and mirrors
  real practice, where admins use a separate privileged account for admin work.
- **What I'd improve:** Add a custom domain so the default `.onmicrosoft.com` name (which contains my email)
  isn't visible in the portfolio.

## 2026-11-09 to 11-12 — Emergency access (break-glass) accounts
- **Problem:** A bad Conditional Access policy, MFA outage, or lost phone could lock every admin out of the tenant.
- **What we set:** Two cloud-only Global Admins, `pcisd-ea01` / `pcisd-ea02`, on the `.onmicrosoft.com` domain,
  no department or job title, permanent active assignment, Authenticator MFA. Evidence EV-001.
- **Why:** Cloud-only accounts keep working if federation or a custom domain breaks; blank attributes keep them out
  of future dynamic groups; every CA policy will exclude them.
- **What I'd improve:** Move them to phishing-resistant passkeys on separate keys (Week 2), add a sign-in alert
  (Week 5), and test them about every 90 days.

## 2026-11-11 to 11-12 — Bulk user creation from CSV
- **Problem:** 30+ users with consistent attributes are slow and error-prone to create by hand.
- **What we set:** `scripts/week1/New-PcisdUsers.ps1`: CSV-driven, `-WhatIf` dry run, skips existing users, random
  passwords in memory only, forced change at first sign-in, refuses to run as the wrong account. Evidence EV-002
  (roster reconciliation).
- **Why:** Repeatable, auditable joiner process; attributes (department, jobTitle, hire/leave dates) drive later
  group, governance, and offboarding automation.
- **What I'd improve:** A source-of-truth HR feed instead of a CSV; validation for stray whitespace in attributes.

## 2026-11-15 — Separate non-admin daily account (`britt.green`)
- **Problem:** Doing everyday work in a Global Admin account means one phishing click hands over the tenant.
- **What we set:** `britt.green`, IT Staff / District Office, no roles, no groups, no licenses. Evidence EV-003.
- **Why:** NIST 3.1.6 (non-privileged account for non-security work); limits blast radius.
- **What I'd improve:** Regular users can read the Entra admin center by default. Consider "Restrict access to
  Microsoft Entra admin center" (Users → User settings), noting it only blocks the portal, not Graph/PowerShell.
- **Lesson:** Read-only Graph check found jobTitle saved as `"IT Staff "` (trailing space), which would have silently
  broken a future dynamic group rule. Fixed and re-verified. Verify attributes, don't trust the form.

## 2026-11-15 — Restricted static group: "Finance & Grants - Restricted"
- **Problem:** Federal grant data (our CUI stand-in) must be limited to the people who need it.
- **What we set:** Security group, assigned membership, not role-assignable, owner britt.admin, 4 members.
  Evidence EV-004.
- **Why:** Access is granted to groups, not individuals. Membership here is a human decision, not an attribute match,
  so it's static. The owner will confirm members in the Week 4 quarterly access review.
- **What I'd improve:** Tie it to the Grants Portal app (Week 3) and the restricted CA set (Week 2); until then 3.1.1/3.1.2
  are partial. Name uses a plain hyphen (easier in scripts and Graph filters); first save had a trailing space.

## 2026-11-15 — Campus staff groups filled by script
- **Problem:** Adding each campus's staff to their group by hand is slow and easy to forget for new hires.
- **What we set:** `scripts/week1/Add-PcisdCampusGroupMembers.ps1`: matches Department (campus) **and** excludes
  JobTitle "Student"; adds only, never removes (reports mismatches for a human); refuses restricted, role-assignable,
  and dynamic groups; scopes `User.Read.All` + `GroupMember.ReadWrite.All`. Ran for "Bluebonnet Middle School - Staff":
  4 added, re-run skipped all 4.
- **Why:** Repeatable joiner automation; least privilege (membership only, not group settings).
- **Lesson:** The first dry run showed 3 students would join a staff group, because students and staff share the
  campus Department value. Fixed by matching a second attribute. A second dry run exposed the `@($null)` empty-list bug
  (same as EV-002); fixed. Dry runs paid for themselves twice.
- **What I'd improve:** A dedicated attribute for staff vs. student (e.g., employeeType) instead of excluding a job
  title; replace with dynamic groups in Week 3.
