# openbot-lab

Experimental lab for evaluating [CopilotKit/OpenBot](https://github.com/CopilotKit/OpenBot) as a self-hosted runtime for persistent AI coworkers.

## Goal

Validate whether OpenBot can replace or complement hosted persistent-agent products by giving our agents:

- a persistent computer and browser profile;
- filesystem and shell access;
- scheduled routines;
- governed MCP/tool access;
- auditability and policy boundaries;
- pluggable AG-UI agents;
- restart-safe state.

The first reference coworker is **Job Scout**.

## Repository strategy

This repository intentionally does **not** vendor the whole OpenBot source tree. OpenBot is still alpha and moving quickly. Instead, this lab keeps our tenant configuration, agent contracts, policies, evaluation scenarios and bootstrap scripts separate from upstream.

```text
CopilotKit/OpenBot (upstream)
          |
          v
   local OpenBot checkout
          |
          +-- mounted/configured from this repo
                    |
                    +-- agents/
                    +-- policies/
                    +-- evals/
                    +-- docs/
```

## Phase 1 - Job Scout POC

Success criteria:

1. OpenBot starts locally from a pinned upstream revision.
2. Job Scout appears as a coworker.
3. The coworker gets an isolated browser/computer.
4. Browser state survives normal agent turns.
5. A scheduled routine can trigger a job search.
6. Results can be persisted to the coworker's workspace.
7. Duplicate jobs can be rejected using durable state.
8. Browser, file and tool actions appear in the audit trail.
9. Restarting OpenBot does not destroy the thread/state we expect to be durable.
10. The agent implementation can later be replaced by our own AG-UI endpoint without changing the surrounding runtime.

## Quick start

Prerequisites:

- Docker
- Bun 1.3+
- Git
- a model API key supported by the chosen OpenBot agent
- CopilotKit Intelligence credentials required by OpenBot

Bootstrap an upstream checkout:

```bash
./scripts/bootstrap-openbot.sh
```

The script clones OpenBot under `.runtime/openbot` at the revision recorded in `OPENBOT_VERSION`.

Then follow `docs/phase-1-job-scout.md`.

## Status

- [x] Lab repository initialized
- [x] POC boundaries defined
- [x] Upstream pin/bootstrap strategy defined
- [x] Job Scout tenant configuration drafted
- [ ] OpenBot boot verified locally
- [ ] Job Scout visible in UI
- [ ] Isolated computer verified
- [ ] Routine verified
- [ ] Durable ledger verified
- [ ] AG-UI custom agent verified

## Why this lab exists

The important question is not whether OpenBot can chat. The question is whether it can become a trustworthy **agent runtime layer**: computers, credentials, policies, audit, routines and human takeover around agents that we own.
