---
name: memory
description: Use TrustBrain, the user's memory of their work, whenever the conversation touches their work, people, companies, projects, meetings, decisions, commitments or preferences. Recall from it before answering, and save what the conversation settles so every AI the user works with knows it next time.
---

# TrustBrain memory

TrustBrain is the user's own memory of their work: people, organizations, projects, decisions,
commitments, preferences and open questions, learned from their meetings, documents and AI chats,
and shared by every AI they use. The `trustbrain` MCP server gives you its tools.

## Recall before you answer

- When the user asks about or works on anything to do with their work (a person, a company, a
  project, a meeting, a past decision, how they like things done), call `recall` with the task
  in one sentence before you answer. Once per topic is enough; call it again when the topic changes.
- Use what it returns as your own knowledge of the user. Cite line IDs such as `[a1b2c3]` only
  when the user asks where something comes from.
- When it returns nothing useful, answer as usual. Do not mention the brain unless the user asked.
- `explore` shows how a person or project connects to the rest; `fetch` opens a line with its
  sources, or a source with a link to the original.
- `brain://MEMORY.md` says who the user is and what they focus on. Read it at the start of a
  long working session.

## Save what the conversation settles

Call `remember` when the conversation produces something the user will want any AI to know next
week:

- a decision and its reason: "We bill EU customers through Stripe because it supports SEPA."
- a preference or way of working: "Ana wants project updates on Fridays, as five bullets."
- a lasting fact about a person, organization or project: a role, an owner, a deadline, a status.
- a commitment: who does what, by when.

Write standalone sentences with names and dates, in the user's words. Save at a natural pause,
when a decision lands or a task ends, with everything in one call rather than one call per fact.
Ordinary work facts need no permission: save them and tell the user in a few words what you saved.

Never save small talk, one-off details, drafts or code you just produced, the contents of
documents the user pasted, secrets or credentials, health or other sensitive personal details,
or anything the user asked you not to keep. When unsure whether something lasts, skip it.

## Fix and forget

- The user says something in the brain is wrong: call `correct` with the line ID and the right
  statement.
- The user wants something gone: call `forget` to preview, show the user the lines, and apply
  only after they confirm.

## Personal and organization brains

`recall`, `search` and `explore` read the user's personal brain and the brains of their
organizations. Writes go to the personal brain. Pass `brain` to save to an organization's brain
only when the fact belongs to the team, never with personal details. Ask when unsure.

## When TrustBrain is not connected

If the TrustBrain tools are missing or answer that the user is not signed in, tell the user once:
connect TrustBrain in this app's connectors (for a plugin, its Connectors tab) and approve it.
