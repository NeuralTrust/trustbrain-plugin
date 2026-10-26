---
name: learn-repo
description: Teach TrustBrain the repository you are working in (how to build, test and run it, where things live, its conventions and recorded decisions) so every coding agent the user works with knows it from the next session on. Use when the user asks to learn, index, onboard or remember this repository, or when TrustBrain knows nothing about the repository you are in.
---

# Learn this repository

1. Find the repository: `git remote get-url origin` (that is `repo` below). Call `recall` with "how to
   work in this repository" and `repo`, and leave out what TrustBrain already knows.
2. Read what says how the repository is built and worked on, not its code line by line: README,
   AGENTS.md or CLAUDE.md, CONTRIBUTING, the build files (Makefile, package.json scripts, go.mod,
   pyproject.toml, Cargo.toml…), CI workflows, docker-compose, the top-level layout, decision records.
3. Write at most 25 lines, each one standalone sentence with commands, paths and file names in
   backticks:
   - how to set it up, build, test, lint, run and migrate it, and what each needs first;
   - where its main parts live and what depends on what;
   - the conventions its code follows;
   - decisions it records, with their reason.
   Nothing a quick look at the code tells as well, nothing that changes every week, and no secrets,
   tokens, keys, internal addresses or links.
4. Call `remember` once with all of them and `repo`. Then tell the user in a few lines what you saved.
