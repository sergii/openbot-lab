# Phase 1 - Job Scout POC

## Objective

Prove that OpenBot can provide the runtime around a persistent Job Scout coworker before we invest in a custom AG-UI implementation.

## Upstream

The tested OpenBot revision is stored in `OPENBOT_VERSION`. Do not silently follow `main` during an experiment. Upgrade the pin deliberately and record what changed.

## 1. Bootstrap

```bash
git clone git@github.com:sergii/openbot-lab.git
cd openbot-lab
chmod +x scripts/bootstrap-openbot.sh
./scripts/bootstrap-openbot.sh
```

This creates `.runtime/openbot` and checks out the pinned revision.

## 2. Configure OpenBot

```bash
cd .runtime/openbot
cp .env.example .env
```

Configure the credentials required by upstream OpenBot. For local development keep single-user mode enabled.

Set the tenant package to the absolute path of this lab's Job Scout package:

```bash
export TENANT_PACKAGE_DIR="$(cd ../.. && pwd)/tenant/job-scout"
```

If you prefer to persist it, place the absolute value in the OpenBot `.env` file.

## 3. Start

From `.runtime/openbot`:

```bash
bash scripts/start.sh
```

Expected local surfaces from upstream are the API server and web app described by OpenBot's startup output.

## 4. Acceptance test A - coworker exists

Open the OpenBot UI and verify:

- `Job Scout` is present;
- title is `Senior Ruby/Rails Job Scout`;
- the `Job Scout` channel exists;
- no unrelated example coworkers from the upstream fintech tenant are loaded.

## 5. Acceptance test B - isolated computer

Ask Job Scout to:

1. open a public website in its browser;
2. create `/workspace/job-scout/probe.txt` using its shell;
3. read that file back;
4. report the current page URL.

Verify the browser/file/shell actions appear in OpenBot's audit surface.

## 6. Acceptance test C - durable ledger

Ask Job Scout to initialize:

```text
/workspace/job-scout/jobs-ledger.json
```

Suggested first shape:

```json
{
  "version": 1,
  "jobs": {}
}
```

Then give it one synthetic job URL twice. The second pass must be classified as already reviewed using the ledger rather than model memory.

## 7. Acceptance test D - routine

Create a routine for Job Scout that searches one low-friction source on a schedule.

For the first routine, avoid trying to solve all job boards. We only need to prove:

- scheduled execution fires;
- it runs in the intended channel;
- it can use the coworker's computer;
- the ledger survives between executions;
- failures are visible.

## 8. Acceptance test E - restart

Stop OpenBot normally, start it again, then verify:

- the Job Scout conversation/thread remains where OpenBot promises durability;
- `/workspace/job-scout/jobs-ledger.json` remains available;
- browser profile behavior matches expectations;
- the routine is still configured;
- audit history remains available.

Record exactly what survives and what does not. We should not assume all four persistence layers have identical semantics.

## 9. Phase 1 exit criteria

Phase 1 is successful when all of the following are true:

- [ ] OpenBot boots with our tenant package
- [ ] Job Scout is visible
- [ ] Job Scout can browse
- [ ] Job Scout can use shell/files
- [ ] actions are audited
- [ ] durable ledger deduplicates a repeated job
- [ ] routine executes successfully
- [ ] expected state survives restart

## Phase 2

Only after Phase 1 passes, replace the built-in Job Scout brain with a small custom AG-UI endpoint. The runtime contract should remain the same while the reasoning/search/evaluation implementation becomes ours.
