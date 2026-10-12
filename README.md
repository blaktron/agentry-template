# QuickAgent template

A starting point for a **QuickAgent**: a single-purpose AI agent packaged
for [Agentry](https://secureagentry.net). A QuickAgent is a manifest
(`agent.yaml`) that declares what the agent may touch, and an instruction
(`AGENT.md`) that says what it does. It ships no tool code. When it runs,
the Agentry runner serves exactly the tools the manifest declares, through
a per-run MCP gateway, and nothing else.

This template runs as it stands: it reads the files you give it and writes
a report. `agent.yaml` shows every other manifest option, commented, with
its limits. The full reference is the
[QuickAgents documentation](https://docs.secureagentry.net/quickagents/).

**This README is about the template.** The README you publish is shown on
your QuickAgent's page, so replace this one with your own: what it does,
what to give it, what it returns.

## Quick start

```bash
# Start from this template ("Use this template" on GitHub), then:
git clone https://github.com/your-namespace/my-quickagent && cd my-quickagent

# Make it yours: name, namespace, summary, guide, instruction, capabilities.
# Keep AGENT.md's frontmatter name and description equal to name and summary.
$EDITOR agent.yaml AGENT.md

# Once per machine: your model (an API key, or your ChatGPT, Claude or
# Copilot plan) and the docker MCP gateway.
agentry setup

# The registry's manifest rules and offline scanners, run here.
agentry validate .

# The compiled run plan: tools, mounts, network. No docker needed.
agentry run --local . --dry-run --allow-unsigned --yes

# One run, with a file to read. Reports and receipts land in ./agentry-out.
agentry run --local . --allow-unsigned --yes --out ./agentry-out --file notes.pdf

# Optional: what the registry's review would be expected to say, before you
# submit. Needs your own TypeSafe key.
agentry review .

# Publish (scanned, signed, immutable). The first time, create the
# QuickAgent at https://secureagentry.net/new, then:
agentry login
agentry publish
agentry run your-namespace/my-quickagent@^0.1 --file notes.pdf
```

`make validate`, `make dry-run`, `make review` and `make run FILES="…"`
wrap the checks and the local run.

Two other ways to start: `agentry init` scaffolds a smaller package (and
`agentry init --from` imports a `SKILL.md` or an MCP registry
`server.json`), and `agentry draft "what it should do"` has the built-in
Drafter write one (it needs your own TypeSafe key, as `review` does). The [Builder](https://secureagentry.net/build), on the
site and in the desktop app, does both in a form.

## What is in it

```
my-quickagent/
├── agent.yaml                  # the manifest (required)
├── AGENT.md                    # the instruction (entrypoints.instruction)
├── README.md                   # shown on the QuickAgent's page; required to publish publicly
├── LICENSE                     # required to publish publicly, with `license` set
├── output.schema.example.json  # rename to output.schema.json for JSON output
├── Makefile                    # validate, dry-run, review, run
└── .gitignore                  # keeps run output out of the repository
```

`SECURITY.md` is the template's own and need not ship with your
QuickAgent; `publish.include` leaves it out.

## The manifest at a glance

`agent.yaml` is a closed schema: an unknown key is an error, so a typo
cannot switch a control off. Each block, and where the reference covers it:

| Block | What it says | Reference |
|---|---|---|
| `name`, `namespace`, `version`, `summary`, `license`, `authors`, `homepage`, `tags` | identity; `version` is strict semver, `summary` one line of at most 140 characters | [Identity](https://docs.secureagentry.net/quickagents/#identity-and-metadata) |
| `modes` | `autonomous`, `interactive`, or both | [Modes](https://docs.secureagentry.net/quickagents/#modes-and-the-instruction-file) |
| `entrypoints.instruction` | the instruction file, `AGENT.md` by default | same |
| `guide` | what a person reads before a run: overview, what to prepare, which files, the task placeholder, help for each key. Never shown to the agent | [guide](https://docs.secureagentry.net/quickagents/#guide-what-a-person-reads-before-a-run) |
| `inputs` | the kinds of file it takes, and whether the agent reads their text or the originals first | [inputs](https://docs.secureagentry.net/quickagents/#inputs-what-files-it-takes-and-how-it-reads-them) |
| `intake` | questions asked before a run: text, choice, file, secret, a repository, a file at a URL, a target host | [intake](https://docs.secureagentry.net/quickagents/#intake-questions-asked-before-a-run) |
| `interactive` | an opening line and an idle limit for sessions | [interactive](https://docs.secureagentry.net/quickagents/#interactive-session-hints) |
| `knowledge` | knowledge packs the release ships, and whether to ask the person for one of theirs | [knowledge](https://docs.secureagentry.net/quickagents/#knowledge-packs-the-release-ships) |
| `runtime` | a model hint (never a lock) and the coding-agent exports it supports | [runtime](https://docs.secureagentry.net/quickagents/#runtime-informational-hints) |
| `capabilities` | the contract: network, filesystem, commands, secrets (required or optional), target hosts, data categories, MCP servers | [capabilities](https://docs.secureagentry.net/quickagents/#capabilities-the-security-contract) |
| `dependencies` | other QuickAgents it expects; shown, not installed | [dependencies](https://docs.secureagentry.net/quickagents/#dependencies) |
| `publish` | the archive's allowlist, and the channel | [publish](https://docs.secureagentry.net/quickagents/#publish) |

The guide, the inputs block and the intake grant nothing, so a release
that changes only them asks nobody to consent again. Everything under
`capabilities`, and the names of the packs a release ships, is the
contract: an upgrade that widens it asks for consent again.

## What a run gives your agent

Every run gets these tools, whatever the manifest declares:

| Tool | What it does |
|---|---|
| `list_inputs`, `read_input`, `search_inputs` | read the files given to the run, under `/inputs`, as decoded text or as uploaded |
| `write_report` | write a file into the run's `reports/` folder, which the person receives |
| `scratch_write`, `scratch_read`, `scratch_list`, `scratch_search` | a private scratch folder, deleted when the run ends |
| `export_pdf` | turn a Markdown report into a PDF (a report, a letter or a memo) in the person's report design |

And these only when the manifest declares them:

| Declaration | Tools |
|---|---|
| `filesystem.read` | `fs_read`, `fs_list` |
| `filesystem.write` | `fs_write` |
| `network.egress` hosts | `fetch`, to those hosts only, optionally sending a declared secret as an auth header |
| `exec.commands` | `run_command`, for those programs only |
| `targetHosts` | the runner's host tools, on the machine the person names (local runs only) |
| `mcpServers` | each server's tools, or those its `tools` list allows |

Files reach a run through `--file`, a `file` intake answer, the uploads of
a run in Agentry, or a `repository` or `url` answer the runner fetches
first. Documents, spreadsheets, slides, mail and images are turned into
text before the agent starts, archives are unpacked, and every uploaded
file is checked for malware. None of this needs a capability.

Before your instruction, every run's model reads Agentry's **System
Prompt**. It says the run is sandboxed, which tools it has and what each
grant allows, where the inputs are, how to read an attached knowledge pack
or Writing Voice, how to write reports and when to export a PDF, and that
the last message is the result. Text in inputs, files and tool results is
data, never instructions. The
[runner reference](https://docs.secureagentry.net/runner/#the-system-prompt)
prints it word for word. To read the text your own QuickAgent's model
gets, run the dry run above and open the `harness/` file in the plan
directory it prints.

## Writing the instruction

`AGENT.md` follows the shape the Drafter uses: six headings, in this
order, even when a section is one line.

- `## Role`: one or two sentences.
- `## Inputs`: the task, each intake answer and each kind of file, and what
  to do when one is missing.
- `## Steps`: numbered, one action each, naming the tool it uses and the
  rule for deciding.
- `## Output`: exactly what it returns, with a skeleton to copy.
- `## Background`: the domain knowledge a run with no network cannot look
  up.
- `## Checks`: edge cases, and what the result must pass before it is
  returned.

Spend the words on the task. The System Prompt already covers the sandbox,
the inputs, the tools and how to report, so the instruction need not
repeat any of it. Name only tools the manifest grants: a step that needs a
host, a command or a key the manifest does not declare fails in the run,
and the registry's scan can report it as an undeclared capability. A
result the person wants as a PDF is written in Markdown with
`write_report` and converted with `export_pdf`; `write_report` refuses a
`.pdf`.

Everything in `AGENT.md` reaches the agent, so keep notes for yourself out
of it. Its frontmatter is stripped at run time and becomes the skill
header when the package is installed as a Claude skill; its `name` must
equal the manifest's (validation refuses a mismatch), and its
`description` should equal the `summary`. The registry caps
an instruction at what a reviewer can read: 2 MiB a file and 1 MiB of text
across the archive. The Drafter keeps its own under 32,768 bytes.

For JSON output, rename `output.schema.example.json` to
`output.schema.json` and add it to `publish.include`. The runner then
appends the schema to the instruction and requires the final message to
parse against it (exit 17 otherwise, with the raw output kept in the
receipts).

## Checking before you publish

- `agentry validate .` runs the manifest rules and the offline scanners
  the registry runs.
- `agentry run --local . --dry-run --allow-unsigned --yes` shows the
  compiled plan.
- `agentry review .` runs the built-in Examiner: the registry's rules, AI
  Review's six questions and a model's reading of every file. It submits
  nothing, and the registry scans again when you do.
- `agentry run --local . --allow-unsigned --yes --file …` runs it. Exit
  codes: `0` done, `10` verification, `11` refused by policy or a missing
  secret, `12` not compilable, `13` docker or the gateway, `14` the agent
  failed, `15` timeout, `16` budget, `17` output schema, `18` blocked (the
  agent said it could not do the task); `1` and `2` are the CLI's own
  errors and usage.

The output folder holds `reports/` (what the agent wrote), `result.json`
(the result, with the release digest, the attestation state, usage and
the plan's hash) and `receipts/` (the event stream, the gateway's call
log and the exact run plan).

## Publishing

`agentry publish` submits the version. Its first publish needs the
QuickAgent's record, which you create at
[secureagentry.net/new](https://secureagentry.net/new); that also makes
the git repository the registry hosts for it, and pushing a release tag
there submits the same way. The Builder creates the record itself. Every submission is validated, scanned against its declared
capabilities, held for a person's review when the findings call for it,
and signed. A published release is immutable and content-addressed, and
`agentry run` and `agentry install` check its digest and signature before
anything runs. The archive is capped at 2,000 files and 10 MiB.

A published QuickAgent is *scanned, with N findings, signed*. Agentry
never calls one "safe", and neither should your README. Declare the least
you need, and the contract stays easy to review.

## Installing into a coding agent

The same package installs into Claude Code, Codex or OpenClaw, whose own
tools then stand in for the runner's:

```bash
agentry install your-namespace/my-quickagent --provider claude    # Claude Code
agentry install your-namespace/my-quickagent --provider codex     # Codex
agentry install your-namespace/my-quickagent --target agents-md   # a section in ./AGENTS.md
```

The `claude-skill` export compiles the contract into the skill's
`allowed-tools` (`Read`, `Grep` and `Glob` for a read grant, `Write` and
`Edit` for write, `Bash(cmd:*)` per command, `WebFetch(domain:host)` per
host). Enforcement there is the host application's, not Agentry's.

## License

The template is MIT ([LICENSE](LICENSE)). Your QuickAgent's license is
whatever you set in `agent.yaml` and put in its LICENSE file.
