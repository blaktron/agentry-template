# Security policy

This template is part of the Agentry open core; one policy covers all of
it. **Do not open a public issue for a security vulnerability.**

Report it as described in the core's
[SECURITY.md](https://github.com/blaktron/agentry/blob/main/SECURITY.md):
email **security@secureagentry.net** (or use GitHub's private vulnerability
reporting on this repository).

What would count here: a default in `agent.yaml` or `AGENT.md` that makes a
QuickAgent built from this template declare less than it uses, reach
something it did not declare, or carry a secret; or an example that a
scanner should catch and does not. A malicious QuickAgent published on a
registry is reported to that registry, not here: signed in, through its
abuse-report API (`POST /api/v1/agents/{ns}/{name}/abuse-reports` on
Agentry), or by email to the security address its operator publishes.
