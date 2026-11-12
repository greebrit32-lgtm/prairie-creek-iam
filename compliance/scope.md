# Scope — Prairie Creek ISD Compliance Lab

**Framework:** NIST SP 800-171 Rev 2, families 3.1 (Access Control) and 3.5 (Identification & Authentication).
Rev 2 is used because CMMC Level 2 assesses against Rev 2.

> Lab disclaimer: all people and data are fictional. "Federal grant data" stands in for CUI (Controlled
> Unclassified Information). No real CUI exists in this tenant.

## In scope
| Asset | What it is | Why it's in scope |
|---|---|---|
| Microsoft Entra ID tenant "Prairie Creek ISD" | Identity provider for all users and apps | Every 3.1/3.5 control in this lab is enforced here |
| "Finance & Grants – Restricted" group | 3–4 users who handle federal grant data (CUI stand-in) | The protected population; strictest controls apply |
| "Grants Portal" app (Week 3) | App that holds the grant data | The system CUI would live in; access limited to the restricted group |
| Privileged accounts | `britt.admin`, 2 break-glass accounts | Admin access to the whole tenant |
| `britt.green` | My non-admin daily account | Shows separation of privileged / non-privileged use (3.1.6) |
| Conditional Access policies | Sign-in rules (Week 2) | Main enforcement point for MFA, location, session controls |

## Out of scope (and why)
| Area | Reason | Where it's tracked |
|---|---|---|
| Endpoints / device management (Intune) | No Intune license | Compliant-device policy runs report-only → POA&M |
| Network, wireless, physical security | Not part of an identity lab | n/a |
| Other 800-171 families (audit, config mgmt, etc.) | Lab focuses on 3.1 and 3.5 | Partial overlap noted in control mapping |
| Real CUI data stores | None exist | n/a |

## Known boundary limitations
- **Commercial cloud.** This tenant is commercial Microsoft Entra ID. Real defense contractors handling CUI
  often use Microsoft 365 GCC High so the cloud meets DFARS 252.204-7012 requirements. The lab demonstrates the
  controls, not the cloud environment choice.
- **Shared responsibility.** Some requirements are partly or fully handled by Microsoft (e.g. password
  storage). These are marked "inherited" in the control mapping.
- **Personal Gmail admin.** The directory's original creator (a personal Microsoft account, `#EXT#`) holds
  Global Administrator. Reviewed in Week 5.

_Last updated: 2026-11-12_
