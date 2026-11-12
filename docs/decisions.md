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
