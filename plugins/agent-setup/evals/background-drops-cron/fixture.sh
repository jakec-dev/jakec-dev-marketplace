#!/usr/bin/env bash
# A Node project with a release-watcher subagent that lists CronCreate.
set -euo pipefail
cat >package.json <<'JSON'
{
  "name": "shop-api",
  "version": "2.4.1",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" }
}
JSON
mkdir -p src
printf 'export const add = (a, b) => a + b\n' >src/math.js
mkdir -p .claude/agents
cat >.claude/agents/release-watcher.md <<'MD'
---
name: release-watcher
description: Checks the latest release's deploy status and schedules a follow-up check. Use after a release.
tools: Read, Bash, CronCreate
---

Run `git log -1 --format=%H` and report the deployed commit. Then use CronCreate to schedule a follow-up check of
the deploy in 30 minutes.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'
