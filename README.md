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

## Reference

Everything about using a QuickAgent is on the docs site:

- [The manifest, option by option](https://docs.secureagentry.net/quickagents/#the-manifest-option-by-option),
  every block of `agent.yaml` and its limits
- [What a QuickAgent gets at run time](https://docs.secureagentry.net/quickagents/#what-a-quickagent-gets-at-run-time),
  the tools every run has and the ones each declaration adds
- [Running with files](https://docs.secureagentry.net/runner/#running-with-files),
  how inputs reach a run
- [The System Prompt](https://docs.secureagentry.net/runner/#the-system-prompt),
  the text every run's model reads before your instruction
- [Publishing](https://docs.secureagentry.net/quickagents/#publishing)
- [Installing into an existing coding agent](https://docs.secureagentry.net/quickagents/#installing-into-an-existing-coding-agent)

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
- `agentry review .` runs the built-in Examiner. It submits nothing.
- `agentry run --local . --allow-unsigned --yes --file …` runs it. The
  [exit codes](https://docs.secureagentry.net/runner/#exit-codes-stage-and-reason)
  and [the output folder](https://docs.secureagentry.net/runner/#the-output-folder)
  are described in the runner reference.

## License

The template is MIT ([LICENSE](LICENSE)). Your QuickAgent's license is
whatever you set in `agent.yaml` and put in its LICENSE file.
