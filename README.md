# TrustBrain plugin

Your memory of work, shared by every AI you use. [TrustBrain](https://brain.neuraltrust.ai) learns your people,
projects, decisions and preferences from your meetings, documents and AI chats, and what your
coding agents learn in each repository. This plugin connects your AI to it:

- **The TrustBrain connector** (MCP, `https://brain.neuraltrust.ai/mcp`): recall, search, explore, remember, correct and
  forget.
- **Skills**: `memory` (your AI checks your brain before it answers about your work, and saves what
  each conversation settles) and `learn-repo` (teaches TrustBrain the repository you are in: how to
  build, test and run it, where things live, its conventions).
- **Hooks for coding agents** (Claude Code, Codex, Cursor, OpenCode): at the start of a session, your
  MEMORY.md, what your agents learned in the repository you are in and your organization's
  procedures; before each message, what TrustBrain finds relevant; after each turn, the session's
  new lines, to learn from.

You need a TrustBrain account: sign up at https://brain.neuraltrust.ai.

## Install

**Every coding agent on your computer at once** (macOS and Linux): Claude Code, Codex, Cursor and
OpenCode, whichever you have, each in its own form.

```sh
curl -fsSL https://brain.neuraltrust.ai/hooks/install.sh | sh
```

Add `-s -- --agents codex,cursor` to pick them, `--dry-run` to see what it would do, `--uninstall`
to take it back. The first session in each agent shows a link: open it and approve the computer for
one of your workspaces.

**Claude (web and desktop)**

1. Open [Customize > Plugins](https://claude.ai/customize/plugins), click Add, then Add
   marketplace, and enter `NeuralTrust/trustbrain-plugin`.
2. Install TrustBrain, open its Connectors tab, click Connect and approve. Installing does not
   sign you in; on Team and Enterprise plans an Owner may need to add the connector first.

A plugin installed in Claude also reaches Claude Code on the same account.

**Each agent by hand**

| Agent | Install | Then |
| --- | --- | --- |
| Claude Code | `claude plugin marketplace add NeuralTrust/trustbrain-plugin`, then `claude plugin install trustbrain@trustbrain` | `/mcp`, pick trustbrain and sign in |
| Codex | `codex plugin marketplace add NeuralTrust/trustbrain-plugin`, then `codex plugin add trustbrain@trustbrain` | `/hooks` to trust its hooks; sign in to the connector when asked |
| Cursor | Customize > Plugins, or copy this folder to `~/.cursor/plugins/local/trustbrain` | reload the window and connect the MCP server |
| OpenCode | copy `opencode/trustbrain.js` to `~/.config/opencode/plugins/` | `opencode mcp auth trustbrain` |

Each agent reads only its own manifest (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`) and
its own hooks file (`hooks/hooks.json`, `hooks/codex.json`, `hooks/cursor.json`), so no hook runs
twice. Cursor takes no context before a message: what TrustBrain finds for it comes after the
message's first tool call.

**Another TrustBrain address** (for example a regional one): run the installer from that address
(`<address>/hooks/install.sh`), or install the plugin from your TrustBrain onboarding or Settings >
Agents. It points at your address.

## Privacy

The plugin holds no secret. Your AI reaches TrustBrain only after you approve it on TrustBrain's
page; revoke it any time in Settings > Agents. TrustBrain keeps the facts it learns, each linked
to its source, never the raw transcripts or chats.

The hooks run `hooks/trustbrain.sh` (`sh` and `curl`; `trustbrain.ps1` on Windows), or OpenCode's
plugin, on each event: it sends the event to TrustBrain and prints what TrustBrain answers; all the
logic is on the server. The device's token stays in `~/.trustbrain`, readable only by you, and the
repository's address goes without any credentials in it. A session's lines are sent only when your
workspace learns from your sessions (an organization that turned it on, or your Personal with
lessons on): they are kept sealed, with secrets taken out, until they are learned from, seven days at
most, then deleted.

This repository is generated from TrustBrain's source (`brain plugin`); changes go there.
