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
- Pass `keywords` too: the key terms and their synonyms in English and in the user's language
  (`santander release problem issue bug incident problema fallo incidencia`). Slack is often
  searched by words, so a message that says "bug" is only found if you include it.
- Use what it returns as your own knowledge of the user. Cite line IDs such as `[a1b2c3]` only
  when the user asks where something comes from.
- Overviews and conclusions come first: where a person or project stands, and what several
  lines amount to, drawn by TrustBrain from the lines they cite. Commitments show when they are
  due, overdue, or done.
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

When you draw a conclusion from what `recall` returned (a pattern, a risk, what several lines
amount to) and the user agrees with it, save it as one sentence with `based_on` set to the IDs of
the lines it rests on. It is kept only when those lines bear it out.

Write standalone sentences with names and dates, in the user's words. Save at a natural pause,
when a decision lands or a task ends, with everything in one call rather than one call per fact.
Ordinary work facts need no permission: save them and tell the user in a few words what you saved.

Never save small talk, one-off details, drafts or code you just produced, the contents of
documents the user pasted, secrets or credentials, health or other sensitive personal details,
or anything the user asked you not to keep. When unsure whether something lasts, skip it.

## Use the user's apps

The user connects their apps (Linear, Notion, Jira, GitHub…) to TrustBrain, not to you, and you use
them through two tools:

1. `search_tools` with the task in one sentence (and keywords: the app, the object, the action). It
   returns the tools that can do it, each with its input schema, and what the brain knows that
   helps fill them (the team an issue goes to, who owns what).
2. `execute_tool` with the tool as it was returned (`app/name`) and arguments that follow its schema.

Never guess a tool's name or its arguments. An argument that names something in the app (a team,
project, person, label or status) must be a value the app knows: take it from the brain's hints or
from the app itself (`search_tools` again for its list tool), never from the user's wording as it is.
When `recall` finds nothing, the user's connected apps may know: look there before saying you do
not know.

Reading needs no permission; before a change the user did not ask for (creating, updating,
deleting), say what you will do and wait for them. When no connected app can do it,
`search_tools` names one to connect and its link: give the user that link.
What you do in an app is learned into their brain; nothing else about the call is kept.

## Fix and forget

- The user says something in the brain is wrong: call `correct` with the line ID and the right
  statement.
- The user wants something gone: call `forget` to preview, show the user the lines, and apply
  only after they confirm.

## Personal and organization brains

`recall`, `search` and `explore` read the user's personal brain and the brains of their
organizations. `remember` always saves to the personal brain.

## When TrustBrain is not connected

If the TrustBrain tools are missing or answer that the user is not signed in, tell the user once:
connect TrustBrain in this app's connectors (for a plugin, its Connectors tab) and approve it.
