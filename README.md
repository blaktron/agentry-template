# BriefAgent template

The starting point for a **BriefAgent** — a single-purpose AI agent
packaged for [Agentry](https://secureagentry.net). A BriefAgent is one
manifest that declares what the agent is and what it may touch, plus the
instruction content itself. No tool code ships in a BriefAgent, ever: at
run time a per-run Docker MCP gateway serves the tools the manifest
declares, plus the report and input tools every run gets. Installed into
an existing coding agent (Claude Code, Codex, …) instead, the package
compiles the same contract into that application's tool grants, and
enforcement there is the host's.

One agent, one job: task in, result out, reports in an output folder,
then gone.

## Quick start

```bash
# 1. Start from this template (GitHub: "Use this template"), then:
git clone https://github.com/your-namespace/my-briefagent && cd my-briefagent

# 2. Make it yours: name, namespace, summary, instructions, capabilities.
$EDITOR agent.yaml AGENT.md

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
├── AGENT.md                    # the instruction file (entrypoints.instruction)
├── README.md                   # rendered on the BriefAgent's registry page
├── LICENSE                     # required for public publication (SPDX in agent.yaml)
├── output.schema.example.json  # rename to output.schema.json for structured output
├── Makefile                    # validate / dry-run / run convenience targets
└── .gitignore                  # keeps run outputs out of the source tree
```

There is one instruction file, whatever the agent does. A file with Agent
Skills frontmatter (this template's `AGENT.md` has it) works unchanged:
the frontmatter is stripped and the body becomes the harness instruction.
An existing `SKILL.md` can be named as `entrypoints.instruction: SKILL.md`.
MCP servers a BriefAgent needs are declared under `capabilities.mcpServers`,
not packaged as agents of their own.

## The manifest, option by option

`agent.yaml` is a closed schema: unknown keys are rejected, so a typo
cannot silently disable a control. `schemaVersion: "2"` is what you write;
releases published under `"1"` (the old `kind`-classified manifest) stay
readable forever, but only a v2 manifest can declare `interactive`.

### Identity and metadata

| Field | Required | Rules |
|---|---|---|
| `name` | yes | lowercase `[a-z0-9-]`, ≤65 chars, starts/ends alphanumeric; unique within the namespace |
| `namespace` | yes | the publishing handle (yours or your org's), lowercase `[a-z0-9-]`, ≤39 chars |
| `modes` | yes | the run modes the release supports: `[autonomous]`, `[interactive]`, or both (see below) |
| `version` | yes | strict semver, no leading `v`; must equal the git tag when publishing from a tag, and exceed every version already on the channel |
| `summary` | yes | one plain-text line, ≤140 characters — shown everywhere the BriefAgent appears |
| `license` | for public publish | an SPDX identifier (`MIT`, `Apache-2.0`, …) matching your LICENSE file |
| `authors` | no | list of `{name, email?}` credits |
| `homepage` | no | informational URL shown on the registry page |
| `tags` | no | lowercase `[a-z0-9-]` search facets |

### `modes` — how the BriefAgent runs

| mode | what a run is | status |
|---|---|---|
| `autonomous` | starts from its files — after the `intake` questions, if any, and MCP profile authentication — does the job, writes its output and receipts, and ends | `agentry run` today |
| `interactive` | the same plan and controls, but the run is a conversation: a chat in the terminal (CLI) or an in-app window (desktop). The agent can ask for information as the work reveals the need; you can answer and drop files into the read-only inputs folder. You cannot give it more access than the manifest declares | `interactive` runs today (agentry-cli#35, #36); the chat needs a terminal on stdin, so a piped task and JSON output are not accepted |

### `entrypoints.instruction` — the one instruction file

`AGENT.md` when omitted. Frontmatter is stripped; the body is the harness
instruction. The file must exist and be matched by `publish.include`.

### `intake` — questions asked before a run

Either mode may ask a few things up front; the runner asks them through
the same prompter that collects MCP profile secrets and stages the answers
read-only at `/inputs/intake.json`. Each question has an `id`
(`[a-z0-9_]{1,64}`, unique), a `prompt`, a `type` and `required`. The four
types are `text` (the default); `secret`, injected as a run-scoped secret
and never written as text; `choice` with its `choices`; and `file`, a host
path the runner stages into the inputs folder. At most 20. Non-secret
answers are receipts.

### `guide` — what a person reads before a run

Optional. The author's own words for the run setup on the site and the
desktop, and for `agentry run` on a terminal. They are shown to people
only: the guide never reaches the agent's context, the run plan, the
capability diff or the consent text, so changing only the guide asks
nobody to consent again. Without it, the setup shows `summary` and a
"What to have ready" list derived from `intake` and `capabilities`.

| part | where it shows | limit |
|---|---|---|
| `overview` | *Before you start*, in place of the summary, and before the questions on a terminal. Markdown: raw HTML is not shown, images are not loaded, and links open in the browser only when they are `http:` or `https:` | 4096 bytes |
| `prepare` | *Before you start*, as "What to have ready", in place of the derived list | 10 items of 200 characters |
| `files` | *Files*, above the file picker | 500 characters |
| `task` | the task field's placeholder, on *Details* | 200 characters |
| `connect` | *Connect tools*, under each key's field, and beside each key's prompt on a terminal. Keyed by a secret name the release declares (`capabilities.secrets` or an MCP server's `secrets`); any other name fails validation | 300 characters each |

Every part except `overview` is one line of plain text: no control or
format characters (zero-width, bidirectional overrides). `overview` may
span lines but carries no NUL, C1 control or format character either. The
block is in schema v2. A CLI or desktop older than the one that added it
refuses a manifest that carries it, which is why the template ships it
commented out.

### `interactive` — session hints

`opening` (≤ 500 characters) is the first message when a session starts
with no task text; `idleTimeoutSeconds` asks for less than the operator's
policy allows, never more. Validation warns when `interactive` is not
among the modes, and accepts the release anyway.

### `runtime` — informational hints

- `runtime.models` — free-form model hint patterns (e.g. `["claude-*"]`).
  A hint, never a lock: the **operator's** runner policy decides which
  model actually runs, with an operator-owned API key.
- `runtime.interfaces` — which `agentry install` targets the package
  supports: `claude-skill`, `agents-md`. Independent of mode; the first
  listed one is the default target. Installing to a target not listed
  here warns but proceeds.

### `capabilities` — the security contract

Closed vocabulary; omitted or empty means a **pure-text BriefAgent**,
whose only tools are `write_report` and the input readers every run gets.
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

A list of environment variable **names** — never values. At run time
every name must resolve: the runner looks in the BriefAgent's MCP profile
first, then the operator's secret source (host env or a dotenv file, per
their policy). A name that resolves nowhere stops the run before it
starts (exit 11, naming the variable). Values are injected only into the
tools container; the `fetch` tool can send one as an auth header
(`auth: {env: NAME}`) without the value ever entering model context, and
values never appear in plans, receipts, or process listings.

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
    - npm: github-mcp-server-js   # or `pypi: package-name`
      version: 0.1.7              # exact version — ranges are rejected
      tools: [list_issues, get_issue]   # optional: only these tools are granted
      secrets: [GITHUB_TOKEN]     # env-var NAMES the server needs, never values
      env:                        # plain configuration the server reads
        GITHUB_PERMISSION: read-only
      egress: [api.github.com]    # the server's own outbound allowlist
```

The release's first run installs the servers from the registries the
operator's policy names (npm and PyPI by default), pins the resolved
artifacts, and configures the gateway to load them for **this exact
release only**. A new version starts the trust decision over, and removal
deletes the configuration and keys unless the operator explicitly keeps
them. Server `secrets` are collected once into the release's MCP profile
by the guided setup, exactly like agent-level secrets. `env` is the
server's plain configuration — a mode switch, a directory — written in
the manifest so it is in the release diff and the review: at most 16
entries, single-line values, and never a name that is also a secret (the
validator refuses that). The registry validates and shows `env`, and the
runner passes it to the server's process when it launches it.

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
the same gate as `agentry install`), then compiles manifest + operator
policy into a deterministic run plan. The runner then executes one
container tree: an isolated agent container (internal-only network; it
can reach exactly the MCP gateway and an allowlisted egress proxy for the
model API), a per-run Docker MCP gateway, and the companion tools server.

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

**Input files.** Hand the run external files with `agentry run --file
PATH` (repeatable; files or directories). They mount read-only at
`/inputs` on the tool plane — task material like stdin, no manifest
capability needed. Output and receipts stay on the separate `/out`
volume.

**Machine setup & MCP profiles.** `agentry setup` configures your
preferred LLM provider and stands up the Docker MCP gateway once. The
first run of a release that declares `secrets:` starts a guided setup
that collects each key into the BriefAgent's **MCP profile** (stored per
exact release signature); keep it for future runs or remove it on
completion — configurable at run time with `--keep-profile`, the
guided question, or the policy default. `agentry profiles list|remove`
manages stored profiles.

**Structured output.** Ship an `output.schema.json` at the archive root
and list it in `publish.include`. The runner then embeds the schema in
the instruction and requires the final message to parse as JSON; anything
else is exit 17, with the raw output preserved in the receipts. This
template ships an inert `output.schema.example.json` to start from.

**Task input.** `--input FILE`, else piped stdin, else an empty task.
Runs compose like processes: `agentry run a … | agentry run b …`.

**Budgets.** The operator policy sets defaults (timeout, max tool-call
turns); `--timeout` and `--max-turns` override per run. Exceeding them is
exit 15 / 16.

**Exit codes.** `0` ok · `10` verify failed · `11` refused by
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
agentry install your-namespace/my-briefagent            # the default target (first runtime.interfaces entry)
agentry install your-namespace/my-briefagent --target claude-skill
agentry install your-namespace/my-briefagent --target agents-md
```

The `claude-skill` target compiles the capability contract into
`allowed-tools` frontmatter (`Read`/`Grep`/`Glob` ⇐ filesystem.read,
`Write`/`Edit` ⇐ filesystem.write, `Bash(cmd:*)` ⇐ exec commands,
`WebFetch(domain:host)` ⇐ egress hosts); the `agents-md` target
records the same contract as a Tools note. An allowed-tools line you
wrote yourself wins: the exporter narrows nothing it did not write.
Frontmatter without one gets the key inserted. Enforcement in embedded
mode is the host's.

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
