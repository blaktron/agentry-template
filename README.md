# BriefAgent template

The starting point for a **BriefAgent** — a single-purpose AI agent
packaged for [Agentry](https://secureagentry.net): one manifest that
declares what the agent is and what it may touch, the instruction content
itself, and nothing else. No tool code ships in a BriefAgent, ever — at
run time the Agentry runner serves exactly the tools the manifest
declares through an isolated Docker MCP Gateway, and when installed into
an existing coding agent (Claude Code, Codex, …) the host's built-in
tools stand in under the same declared contract.

One agent, one job: task in, result out, reports in an output folder,
then gone.

## Quick start

```bash
# 1. Start from this template (GitHub: "Use this template"), then:
git clone https://github.com/your-namespace/my-briefagent && cd my-briefagent

# 2. Make it yours: name, namespace, summary, instructions, capabilities.
$EDITOR agent.yaml SKILL.md

# 3. One-time machine setup: LLM provider + the docker MCP gateway.
agentry setup

# 4. Validate offline — the same rules and scanners the registry runs.
agentry validate .

# 5. See exactly what the runner will enforce (no docker needed).
agentry run --local . --dry-run --allow-unsigned --yes

# 6. Run it once, isolated, with an output folder for reports.
echo "your task here" | agentry run --local . --allow-unsigned --yes --out ./agentry-out

# 7. Publish to the registry (scanned, signed, immutable), then anyone runs:
agentry publish
agentry run your-namespace/my-briefagent@^0.1 --input task.json
```

`make validate`, `make dry-run`, and `make run` wrap steps 4–6.

## Repository layout

```
my-briefagent/
├── agent.yaml                  # the manifest — identity + security contract (required)
├── SKILL.md                    # the instructions (kind: skill entrypoint)
├── README.md                   # rendered on the BriefAgent's registry page
├── LICENSE                     # required for public publication (SPDX in agent.yaml)
├── output.schema.example.json  # rename to output.schema.json for structured output
├── Makefile                    # validate / dry-run / run convenience targets
└── .gitignore                  # keeps run outputs out of the source tree
```

For `kind: prompt-agent`, replace `SKILL.md` with `AGENT.md` (or
`PROMPT.md`) at the root. For `kind: mcp-server`, add your server code and
declare the `mcp` entrypoint instead.

## The manifest, option by option

`agent.yaml` is a closed schema: unknown keys are rejected, so a typo
cannot silently disable a control. `schemaVersion: "1"` is the only
schema major today.

### Identity and metadata

| Field | Required | Rules |
|---|---|---|
| `name` | yes | lowercase `[a-z0-9-]`, ≤64 chars, starts/ends alphanumeric; unique within the namespace |
| `namespace` | yes | the publishing handle (yours or your org's), lowercase `[a-z0-9-]`, ≤39 chars |
| `kind` | yes | `skill` \| `prompt-agent` \| `mcp-server` (see below) |
| `version` | yes | strict semver, no leading `v`; must equal the git tag when publishing from a tag, and exceed every version already on the channel |
| `summary` | yes | one plain-text line, ≤140 characters — shown everywhere the BriefAgent appears |
| `license` | for public publish | an SPDX identifier (`MIT`, `Apache-2.0`, …) matching your LICENSE file |
| `authors` | no | list of `{name, email?}` credits |
| `homepage` | no | informational URL shown on the registry page |
| `tags` | no | lowercase `[a-z0-9-]` search facets |

### `kind` — what sort of BriefAgent this is

| kind | definition | entrypoint | runnable by `agentry run`? |
|---|---|---|---|
| `skill` | an instruction package (Claude-skill-shaped) with optional support files | `entrypoints.skill:` names the skill file (default `SKILL.md`); its frontmatter is stripped and the body becomes the harness instruction | yes |
| `prompt-agent` | pure instructions, no code entrypoint | none declared — the runner reads `AGENT.md`, else `PROMPT.md`, at the archive root | yes |
| `mcp-server` | a tool server other BriefAgents can use | `entrypoints.mcp: {command, args[], transport: stdio\|http}` — args naming repo files must appear in `publish.include` | no — it is a tool, not an agent (the runner refuses it with exit 12) |

### `runtime` — informational hints

- `runtime.models` — free-form model hint patterns (e.g. `["claude-*"]`).
  A hint, never a lock: the **operator's** runner policy decides which
  model actually runs, with an operator-owned API key.
- `runtime.interfaces` — which `agentry install` targets the package
  supports: `claude-skill`, `mcp`, `agents-md`. Installing to a target not
  listed here warns but proceeds.

### `capabilities` — the security contract

The heart of the manifest. Closed vocabulary; omitted or empty means a
**pure-text BriefAgent** (its only run-time tool is `write_report`).
Declared capabilities are what the registry scans against
(declared-vs-detected), what installs prompt on (egress/exec need typed
consent; widened contracts re-ask on upgrade), and what the runner turns
into hard enforcement.

#### `capabilities.network.egress`

| value | meaning | run-time enforcement |
|---|---|---|
| `none` (or omitted) | no outbound network | tools container runs with networking disabled; no `fetch` tool exists |
| `[exact.dns.host, …]` | outbound only to these hosts | the `fetch` tool is granted, restricted to the listed hostnames (checked per request and per redirect hop), and the gateway pins the tools container to `host:443` with per-server proxies + DNS interception |
| `"*"` | unrestricted egress | refused at run time unless the operator's policy sets `allowWildcardEgress: true`; the receipt then discloses it loudly |

#### `capabilities.filesystem.read` / `.write`

| value | meaning | run-time enforcement |
|---|---|---|
| `none` (or omitted) | no access in that direction | the corresponding tools don't exist |
| `workspace` | the whole task workspace | `read` grants `fs_read` + `fs_list`; `write` grants `fs_write`; the workspace is bind-mounted into the **tools** container `ro`/`rw` accordingly |
| `{ paths: [repo/relative, …] }` | only these paths | per-path bind mounts plus server-side grant checks; a listed directory covers everything under it |

The agent container itself never mounts the workspace — every file access
goes through the gateway's tools, which is what makes the contract
enforceable.

#### `capabilities.exec`

| value | meaning | run-time enforcement |
|---|---|---|
| `none` (or omitted) | no subprocesses | no `run_command` tool; harness built-in shells are never enabled |
| `{ commands: [jq, git, …] }` | only these binaries | `run_command` is granted, restricted to the listed argv[0]s via an allowlist plus a shim `PATH` containing only those commands, cwd `/workspace` |

#### `capabilities.secrets`

A list of environment variable **names** — never values. At run time the
operator's secret source (host env or a dotenv file, per their policy)
must resolve every name or the run refuses to start (exit 11, naming the
variable). Values are injected only into the tools container; the `fetch`
tool can send one as an auth header (`auth: {env: NAME}`) without the
value ever entering model context, and values never appear in plans,
receipts, or process listings.

#### `capabilities.dataAccess`

Semantic categories the BriefAgent touches, for review and audit:
`email`, `calendar`, `files`, `tickets`, `code`, `messages`, `payments`,
`other`. Operators may catalog extra MCP servers per category in their
runner policy; categories you did not declare are never wired in.

#### `capabilities.mcpServers`

The MCP servers your BriefAgent requires, declared explicitly and
**version-pinned to this release**:

```yaml
capabilities:
  mcpServers:
    - npm: "@modelcontextprotocol/server-github"   # or `pypi: package-name`
      version: 2026.1.2       # exact version — ranges are rejected
      tools: [list_issues]    # optional: only these tools are granted
      secrets: [GITHUB_PAT]   # env-var NAMES the server needs, never values
      egress: [api.github.com]  # the server's own outbound allowlist
```

Installing the agent installs the servers from the operator's trusted
registries (npm/PyPI by default), pins the resolved artifacts, and
configures the gateway to load them for **this exact release only** — a
new version starts the trust decision over, and removal deletes the
configuration and keys unless the operator explicitly keeps them. Server
`secrets` are collected once into the release's MCP profile by the guided
setup, exactly like agent-level secrets.

### `dependencies`

```yaml
dependencies:
  agents:
    - ref: acme/other-agent
      version: "^1.2"     # semver constraint; omit for any
```

Informational in v1 — recorded and displayed, not auto-installed.

### `publish`

- `publish.include` (required) — the release archive **allowlist** of glob
  patterns (`path.Match` segments; a whole segment `**` matches any number
  of segments). Nothing outside it ships, so forgotten scratch files can't
  leak into a release.
- `publish.channel` — `stable` (default) or `beta`.

## What your BriefAgent gets at run time

`agentry run` verifies the release (sha256 digest + DSSE attestation —
the same gate as `agentry install`), compiles manifest + operator policy
into a deterministic run plan, and executes one container tree: an
isolated agent container (internal-only network; it can reach exactly the
MCP gateway and an allowlisted egress proxy for the model API), a
per-run Docker MCP Gateway, and the companion tools server.

| manifest declaration | tool(s) granted |
|---|---|
| — (always) | `write_report` — write files into the run's output folder |
| — (always) | `list_inputs`, `read_input` — the run's provided input files, read-only |
| `filesystem.read` | `fs_read`, `fs_list` |
| `filesystem.write` | `fs_write` |
| `network.egress` hosts | `fetch` (with optional declared-secret auth) |
| `exec.commands` | `run_command` |

**The runner contract**, appended to every instruction: tools come only
from the gateway; the workspace is rooted at `/workspace` as seen by
tools; provided input files are under `/inputs`; report files must be
written with `write_report`; the final message is the run's result.

**Input files:** hand the run external files with `agentry run --file
PATH` (repeatable; files or directories). They mount read-only at
`/inputs` on the tool plane — task material like stdin, no manifest
capability needed. Output and receipts stay on the separate `/out`
volume.

**Machine setup & MCP profiles:** `agentry setup` configures your
preferred LLM provider and stands up the docker MCP gateway once. The
first run of a release that declares `secrets:` starts a guided setup
that collects each key into the BriefAgent's **MCP profile** (stored per
exact release signature); keep it for future runs or remove it on
completion — configurable at install time with `--keep-profile`, the
guided question, or the policy default. `agentry profiles list|remove`
manages stored profiles.

**Structured output:** ship an `output.schema.json` at the archive root
(and list it in `publish.include`) and the runner embeds the schema in
the instruction and requires the final message to parse as JSON — exit
17 otherwise, with the raw output preserved in the receipts. This
template ships an inert `output.schema.example.json` to start from.

**Task input:** `--input FILE`, else piped stdin, else an empty task.
Runs compose like processes: `agentry run a … | agentry run b …`.

**Budgets:** the operator policy sets defaults (timeout, max tool-call
turns); `--timeout` and `--max-turns` override per run. Exceeding them is
exit 15 / 16.

**Exit codes:** `0` ok · `10` verify failed · `11` refused by
policy / missing secret · `12` package not compilable/runnable ·
`13` gateway or docker environment · `14` the BriefAgent itself failed ·
`15` timeout · `16` budget · `17` output schema.

**The output folder** (`--out`, default `./agentry-out/<ns>-<name>-<runid>/`):

```
reports/…              # whatever the BriefAgent wrote via write_report
result.json            # the machine-readable result envelope
receipts/              # events.ndjson, gateway.log, run-plan.json, meta.json, task.txt
```

The envelope names every enforcement mechanism that applied
(`capabilities_enforced`), the exact release digest, the attestation
state, usage, and the run-plan hash — the runtime counterpart of the
registry's public scan report.

## Installing into an existing coding agent instead

The same package installs into a host coding agent with **that
application's** MCP servers and built-in tools standing in — nothing
bundled either way, and no docker gateway involved:

```bash
agentry install your-namespace/my-briefagent --provider claude    # Claude Code
agentry install your-namespace/my-briefagent --provider codex     # Codex
agentry install your-namespace/my-briefagent --provider openclaw  # OpenClaw

# or by explicit target:
agentry install your-namespace/my-briefagent            # target by kind
agentry install your-namespace/my-briefagent --target claude-skill
agentry install your-namespace/my-briefagent --target agents-md
agentry install your-namespace/my-briefagent --target mcp   # kind: mcp-server
```

The `claude-skill` target compiles the capability contract into
spec-conformant `allowed-tools` frontmatter (`Read`/`Grep`/`Glob` ⇐
filesystem.read, `Write`/`Edit` ⇐ filesystem.write, `Bash(cmd:*)` ⇐ exec
commands, `WebFetch(domain:host)` ⇐ egress hosts); the `agents-md` target
records the same contract as a Tools note. Enforcement in embedded mode
is the host's.

## Publishing

`agentry publish` submits the version to the registry's mandatory
pipeline: manifest validation, content scanning against your declared
capabilities, and DSSE signing. Published releases are immutable and
content-addressed; `agentry run`/`install` verify the digest and
signature before anything executes. The registry's language rule applies
here too: a published BriefAgent is *scanned, with N findings, signed* —
never "safe". Declare the least you need and the whole chain stays
reviewable.

## License

This template is MIT (see [LICENSE](LICENSE)). Your BriefAgent's own
license is whatever you set in `agent.yaml` and your LICENSE file.
