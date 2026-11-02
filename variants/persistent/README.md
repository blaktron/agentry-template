# Tally, a persistent notes keeper

A persistent QuickAgent: it stays on your computer, keeps its conversation
and its memory between starts, and keeps your notes and reminders. It
reaches nothing on the internet, runs no programs and holds no accounts.

**Replace this README with your own.** It is shown on your agent's page:
what the agent does, what it keeps, what a person gives it and what it
returns.

## What it does

- Keeps what you tell it as short dated notes and finds them again with
  `recall`.
- Adds a task when you ask to be reminded, and tells you when it comes due.
- Answers briefly, and declines what it was not given the tools for.

## Install and run

Needs CLI v0.6.1015 or later and a container engine. Agentry Desktop 0.7.1
or later installs it from Browse with **Install as a persistent agent**.

```bash
agentry agent install your-namespace/my-persistent-agent
agentry agent start your-namespace/my-persistent-agent
agentry agent chat your-namespace/my-persistent-agent
agentry agent stop your-namespace/my-persistent-agent
```

Installing it again updates it. The conversation, the memory and the share
folder carry across. [Persistent agents](https://docs.secureagentry.net/agentry/persistent-agents/)
explains how to use one.

## Files

- `agent.yaml`: the manifest, with `modes: [persistent]`,
  `capabilities.persistent` and `persona`.
- `AGENT.md`: the standing instruction. It names only the tools its keys
  give: `recall` for `memory`, and the task tools for `clock`.
- `PERSONA.md`: the text the agent takes on. A person may replace it.

## License

MIT ([LICENSE](LICENSE)).
