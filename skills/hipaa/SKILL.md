---
name: hipaa
description: |
  HIPAA compliance review for healthcare software. Checks code for PHI exposure,
  encryption requirements, access controls, audit logging, and regulatory violations.
  Only active in projects with a .hipaa marker file.
  Invoke for "HIPAA", "PHI", "protected health information", "healthcare compliance",
  "BAA", "hipaa review", "hipaa check".
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Agent
---

# HIPAA Compliance Review

## Gate: Project Activation Check

**This skill is project-specific.** Check for the activation marker before proceeding:

```bash
if [ ! -f ".hipaa" ]; then
  echo "NOT_ACTIVE"
fi
```

If `.hipaa` does not exist, tell the user:

> This project is not marked as HIPAA-regulated. To activate HIPAA reviews, run:
> ```
> touch .hipaa
> ```
> Add `.hipaa` to `.gitignore` if you don't want it tracked.

Then stop — do not run the review.

---

## Step 1: Load Project Context

Read `.hipaa` for project-specific HIPAA configuration (if it contains content):
```
# .hipaa file can optionally contain:
# phi_fields: ssn, dob, mrn, diagnosis, medication, insurance_id
# data_stores: postgres, s3, redis
# auth_model: oauth2, session, jwt
# covered_entity: yes/no
# baa_required: list of third-party services
```

Read `.claude/stack.md` and `.claude/project-context.md` if they exist.

## Step 2: PHI Exposure Scan

Search for PHI leaking into unsafe locations. PHI includes: names, addresses, dates
(birth, admission, discharge, death), SSN, MRN, phone, email, biometric, photos,
account numbers, certificate/license numbers, device identifiers, URLs, IPs,
diagnosis, medication, lab results, insurance info.

### 2.1 PHI in Logs

Search for logging calls that may include PHI fields:

```
Pattern: log\.(info|warn|error|debug)|logger\.|console\.(log|warn|error)|print\(|println!|tracing::(info|warn|error|debug)
```

Flag any log statement that includes:
- User/patient object serialization (e.g., `log.info(f"User: {user}")`)
- Medical record fields (diagnosis, medication, lab results)
- Direct identifiers (SSN, MRN, DOB, name, address, phone, email)
- Request/response body dumps containing patient data

**PASS:** Logs contain only IDs, timestamps, operation names, error codes
**FAIL:** Logs contain PHI fields, full objects with PHI, or patient-facing data

### 2.2 PHI in Error Messages / API Responses

Search for error handlers and API responses:

- Error responses should never include PHI in the message body
- Stack traces sent to clients must be scrubbed
- API responses should use minimum necessary principle (only fields the requester needs)

### 2.3 PHI in URLs / Query Parameters

```
Pattern: \?(.*)(ssn|dob|name|mrn|patient|diagnosis|medication)
```

PHI must never appear in URLs or query strings — these get logged by web servers,
proxies, and browsers.

### 2.4 PHI in Client-Side Storage

For web/mobile apps, check for PHI stored in:
- localStorage / sessionStorage
- Cookies (especially without Secure + HttpOnly flags)
- IndexedDB without encryption
- Mobile app shared preferences / UserDefaults without encryption

## Step 3: Encryption Verification

### 3.1 Data at Rest

Check that databases and file stores use encryption:

- Database connections should specify `sslmode=require` or equivalent
- S3 buckets should use server-side encryption (`SSE-S3` or `SSE-KMS`)
- Local file storage of PHI must use AES-256 or equivalent
- Backup encryption must be verified
- Encryption keys must not be in source code or committed configs

### 3.2 Data in Transit

- All HTTP endpoints must use TLS (no `http://` in production configs)
- Internal service-to-service communication should use TLS or mTLS
- Database connections must use SSL/TLS
- HSTS headers should be set

### 3.3 Encryption Key Management

Flag:
- Hardcoded encryption keys or secrets
- Keys stored alongside encrypted data
- Use of weak algorithms (DES, 3DES, MD5 for hashing, SHA1 for signatures)
- Missing key rotation mechanism

## Step 4: Access Controls

### 4.1 Authentication

Verify:
- Authentication required on all PHI-accessing endpoints
- Session timeout configured (HIPAA recommends ≤15 min idle)
- Failed login attempt limiting / lockout
- MFA support for admin/clinical users
- No default credentials in code

### 4.2 Authorization (Minimum Necessary)

Check for:
- Role-based access control (RBAC) or attribute-based (ABAC)
- Endpoint-level authorization checks (not just authentication)
- Row-level security where applicable (users see only their data)
- No admin backdoors or debug endpoints exposing PHI
- Break-the-glass procedures for emergency access (if applicable)

### 4.3 API Security

- Rate limiting on PHI endpoints
- Input validation on all patient data endpoints
- No IDOR vulnerabilities (check authorization on object access, not just endpoint)
- CORS properly restricted (no wildcard origins on PHI endpoints)

## Step 5: Audit Logging (§164.312(b))

HIPAA requires audit trails for PHI access. Verify:

### 5.1 Required Audit Events

- All PHI read access logged (who, what record, when, from where)
- All PHI modifications logged (who, what changed, old/new values or diff)
- All PHI deletions logged
- Authentication events (login, logout, failed attempts)
- Authorization failures (access denied)
- Admin actions (user creation, role changes, config changes)

### 5.2 Audit Log Integrity

- Audit logs must be tamper-evident (append-only, or signed)
- Audit logs must not contain PHI themselves (log record IDs, not record content)
- Retention: minimum 6 years (HIPAA requirement)
- Audit logs must be stored separately from application data

## Step 6: Data Retention & Disposal

Check for:
- Data retention policy implementation (records kept minimum 6 years)
- Secure deletion (not just soft delete — PHI must be unrecoverable when disposed)
- Database purge procedures
- Backup retention aligned with retention policy
- De-identification procedures if data is used for analytics

## Step 7: Third-Party / BAA Check

If `.hipaa` lists `baa_required` services, check:
- Third-party services that receive or store PHI
- Each must have a BAA in place
- Check for PHI sent to analytics services (Segment, Mixpanel, Google Analytics)
- Check for PHI sent to error tracking (Sentry, Bugsnag, Datadog)
- Check for PHI in email services (SendGrid, SES)

Common violations:
- Sending PHI to error tracking without scrubbing
- Analytics events containing patient identifiers
- Logging services receiving unscrubbed PHI

---

## Output Format

```markdown
# HIPAA Compliance Review

**Project:** {project name}
**Date:** {date}
**Reviewer:** HIPAA Compliance Skill (automated)

## Summary

| Category | Status | Findings |
|----------|--------|----------|
| PHI Exposure | PASS/FAIL/WARN | {count} issues |
| Encryption at Rest | PASS/FAIL/WARN | {count} issues |
| Encryption in Transit | PASS/FAIL/WARN | {count} issues |
| Access Controls | PASS/FAIL/WARN | {count} issues |
| Audit Logging | PASS/FAIL/WARN | {count} issues |
| Data Retention | PASS/FAIL/WARN | {count} issues |
| Third-Party / BAA | PASS/FAIL/WARN | {count} issues |

## Critical Findings (must fix)

### H-{N}: {title}
**Category:** {category}
**Severity:** CRITICAL / HIGH
**Location:** {file:line}
**Issue:** {description}
**Fix:** {specific remediation}
**HIPAA Reference:** §{section}

## Warnings (should fix)

### W-{N}: {title}
...

## Recommendations

- {improvement suggestions}
```

Save the report to `.ai-team/{feature}/hipaa-review.md` if a feature is active,
otherwise print to output.

---

## Rules

1. **Never suggest disabling security controls** to fix a build or test.
2. **Assume all patient data is PHI** unless explicitly de-identified per HIPAA Safe Harbor (18 identifiers removed) or Expert Determination.
3. **Flag uncertainty** — if you can't determine whether data is PHI, flag it as WARN.
4. **Minimum necessary principle** — flag any endpoint or query returning more PHI fields than needed.
5. **No PHI in this review** — never include actual patient data in examples or output.
6. **Be specific** — every finding must include file, line, and concrete fix.
