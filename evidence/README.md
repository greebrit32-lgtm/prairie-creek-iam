# Evidence

Evidence that each Prairie Creek ISD control is in place, mapped to **NIST SP 800-171 Rev 2**
(Access Control 3.1.x, Identification & Authentication 3.5.x). See `../compliance/control-mapping.md`.

> This is a lab with fictional data. It demonstrates evidence-collection practice, not a real CMMC assessment.

## Naming convention

```
EV-###_YYYY-MM-DD_short-name.ext
```

| Part | Meaning | Example |
|---|---|---|
| `EV-###` | Evidence ID, 3 digits, never reused | `EV-001` |
| `YYYY-MM-DD` | Date captured (not the date redacted) | `2026-11-12` |
| `short-name` | Lowercase, hyphens, what it shows | `break-glass-ga` |
| `.ext` | `.png` screenshot, `.json` / `.csv` Graph output | `.png` |

One evidence ID can have several files (e.g. a screenshot **and** a Graph query). They share the ID and date:
`EV-001_2026-11-12_break-glass-ga.png`, `EV-001_2026-11-12_break-glass-ga.json`.

**Avoid these words in file names:** `password`, `token`, `secret`, `export`, `tap`. `.gitignore`
blocks any file containing them (a safety net for secrets), so a redacted file with one of those names would
silently never be committed. Use alternatives like `pwd-policy`, `auth-methods`, `graph-query`.

## Folders

| Folder | What goes there | Committed to git? |
|---|---|---|
| `raw/` | Original, unredacted captures | **No** (gitignored) |
| `week1/` … `week5/` | Redacted copies, safe to publish | Yes |
| `evidence-register.csv` | One row per evidence item | Yes |

## Workflow (every item)

1. **Capture** the screenshot or Graph output into `raw/` with the full name.
2. **Hash** the raw file: `shasum -a 256 evidence/raw/<file>`. Record it in the register. This proves the
   original wasn't altered later (integrity).
3. **Redact** a copy into `weekN/`, keeping the same file name.
4. **Log** it in `evidence-register.csv`.
5. **Map** the evidence ID in `../compliance/control-mapping.md`.

## Redaction rules

Remove from every redacted copy:

- **My Gmail-based domain and tenant name** (the real value is in `config/lab.local.psd1`) wherever it appears: UPNs, URL bar, account
  menu, tenant switcher, `#EXT#` guest names. Replace with `<tenant>` in text files.
- **Tenant ID** and other directory GUIDs that identify the real tenant.
- **IP addresses** (sign-in logs, named locations).
- **Locations** (city/state/coordinates in sign-in logs; map views).
- **Any password, Temporary Access Pass, or token.** These should never be captured at all, even in `raw/`.
  If one appears, delete the raw file and recapture.

How:

- **Screenshots:** use a **solid box** (Preview → Markup → Shapes → filled rectangle), not just blur.
  Light blur on text can sometimes be reversed. Check the browser URL bar and the top-right account menu,
  since they're easy to miss.
- **Text/JSON:** replace values with `<tenant>`, `<tenant-id>`, `<ip>`, `<location>`.
- Before committing, open the redacted file and read it once, top to bottom.

Fictional people's names (from `data/pcisd-users.csv`) don't need redaction.
