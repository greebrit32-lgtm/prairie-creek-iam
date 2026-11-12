# Control Mapping — NIST SP 800-171 Rev 2

> ⚠️ **Paraphrased, not official text.** Each requirement below is written in plain words for study.
> Before using any of this in an interview or portfolio, **check each row against the official
> NIST SP 800-171 Rev 2 PDF** (csrc.nist.gov). CMMC Level 2 assessors also test each requirement's
> assessment objectives in NIST SP 800-171A, so one requirement can need several pieces of evidence.

**How it's met:** `implemented` · `partial` · `inherited from Microsoft` · `not implemented` (→ add to `poam.md`)

## 3.1 Access Control

| Requirement | Requirement (paraphrased) | Lab feature | How it's met | Evidence ID |
|---|---|---|---|---|
| 3.1.1 | Only let authorized users, processes acting for them, and devices into the system | | | |
| 3.1.2 | Limit what each authorized user can do to the functions their job needs | | | |
| 3.1.3 | Control where CUI flows, based on approved authorizations | | | |
| 3.1.4 | Separate duties so no single person can misuse access without being noticed | | | |
| 3.1.5 | Give least privilege, especially for security functions and privileged accounts | | | |
| 3.1.6 | Use non-privileged accounts for everyday, non-security work | | | |
| 3.1.7 | Stop non-privileged users from running privileged functions, and log privileged actions | | | |
| 3.1.8 | Limit failed sign-in attempts | | | |
| 3.1.9 | Show privacy and security notices that match CUI rules | | | |
| 3.1.10 | Lock sessions after inactivity and hide what was on screen | | | |
| 3.1.11 | End user sessions automatically after a defined condition | | | |
| 3.1.12 | Monitor and control remote access sessions | | | |
| 3.1.13 | Use encryption to protect remote access sessions | | | |
| 3.1.14 | Route remote access through managed access control points | | | |
| 3.1.15 | Authorize remote use of privileged commands and remote access to security information | | | |
| 3.1.16 | Authorize wireless access before allowing connections | | | |
| 3.1.17 | Protect wireless access with authentication and encryption | | | |
| 3.1.18 | Control the connection of mobile devices | | | |
| 3.1.19 | Encrypt CUI on mobile devices and mobile platforms | | | |
| 3.1.20 | Check and control connections to, and use of, external systems | | | |
| 3.1.21 | Limit use of portable storage devices on external systems | | | |
| 3.1.22 | Control CUI posted or processed on publicly accessible systems | | | |

## 3.5 Identification & Authentication

| Requirement | Requirement (paraphrased) | Lab feature | How it's met | Evidence ID |
|---|---|---|---|---|
| 3.5.1 | Identify users, processes acting for users, and devices | | | |
| 3.5.2 | Verify (authenticate) those identities before allowing access | | | |
| 3.5.3 | Use MFA for privileged accounts (local and network) and for network access by non-privileged accounts | | | |
| 3.5.4 | Use replay-resistant authentication for network access to all accounts | | | |
| 3.5.5 | Don't reuse identifiers for a defined period | | | |
| 3.5.6 | Disable identifiers after a defined period of inactivity | | | |
| 3.5.7 | Enforce minimum password complexity and require characters to change when a new password is set | | | |
| 3.5.8 | Block password reuse for a set number of generations | | | |
| 3.5.9 | Allow temporary passwords only for sign-in that must be changed right away to a permanent one | | | |
| 3.5.10 | Store and transmit only cryptographically protected passwords | | | |
| 3.5.11 | Hide (obscure) authentication information as it's typed | | | |

_Skeleton created 2026-11-12. Filled in week by week; completed in Week 5._
