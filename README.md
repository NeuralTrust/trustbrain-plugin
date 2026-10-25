# TrustBrain plugin

Your memory of work, shared by every AI you use. [TrustBrain](https://brain.neuraltrust.ai) learns your people,
projects, decisions and preferences from your meetings, documents and AI chats. This plugin
connects your AI to it:

- **The TrustBrain connector** (MCP, `https://brain.neuraltrust.ai/mcp`): recall, search, explore, remember,
  correct and forget.
- **The memory skill** (`skills/memory/SKILL.md`): your AI checks your brain before it answers
  about your work, and saves what each conversation settles, so the next conversation, in any
  app, already knows.
- **Hooks for coding agents** (`hooks/`, Claude Code): at the start of a session, your MEMORY.md,
  your organization's procedures and the page of the repository you are in; before each message,
  what TrustBrain finds relevant; at the end of each turn, the session's new lines, to learn from.

You need a TrustBrain account: sign up at https://brain.neuraltrust.ai.

## Install

**Claude (web and desktop)**

1. Open [Customize > Plugins](https://claude.ai/customize/plugins), click Add, then Add
   marketplace, and enter `NeuralTrust/trustbrain-plugin`.
2. Install TrustBrain, open its Connectors tab, click Connect and approve. Installing does not
   sign you in; on Team and Enterprise plans an Owner may need to add the connector first.

A plugin installed in Claude also reaches Claude Code on the same account.

**Claude Code**

```sh
claude plugin install trustbrain --marketplace NeuralTrust/trustbrain-plugin
```

Then type `/mcp`, pick trustbrain and sign in. The first time a hook runs, it shows a link: open it
and approve this device for one of your workspaces.

**Codex and Cursor** take the same hooks with one command (their connector is added apart):

```sh
curl -fsSL "https://brain.neuraltrust.ai/hooks/install.sh?client=codex" | sh    # or client=cursor
```

**Another TrustBrain address** (for example a regional one): install the plugin from your
TrustBrain onboarding or Settings > Agents instead. It points at your address.

## Privacy

The plugin holds no secret. Your AI reaches TrustBrain only after you approve it on TrustBrain's
page; revoke it any time in Settings > Agents. TrustBrain keeps the facts it learns, each linked
to its source, never the raw transcripts or chats.

The hooks run `hooks/trustbrain.sh` (`sh` and `curl`; `trustbrain.ps1` on Windows) on each event:
it sends the event to TrustBrain and prints what TrustBrain answers; all the logic is on the
server. The device's token stays in `~/.trustbrain`, readable only by you, and the repository's
address goes without any credentials in it. A session's lines are sent only when your workspace
learns from your sessions (an organization that turned it on, or your Personal with lessons on):
they are kept sealed, with secrets taken out, until they are learned from, seven days at most,
then deleted.

This repository is generated from TrustBrain's source (`brain plugin`); changes go there.
