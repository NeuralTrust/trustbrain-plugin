# TrustBrain plugin

Your memory of work, shared by every AI you use. [TrustBrain](https://brain.neuraltrust.ai) learns your people,
projects, decisions and preferences from your meetings, documents and AI chats. This plugin
connects your AI to it:

- **The TrustBrain connector** (MCP, `https://brain.neuraltrust.ai/mcp`): recall, search, explore, remember,
  correct and forget.
- **The memory skill** (`skills/memory/SKILL.md`): your AI checks your brain before it answers
  about your work, and saves what each conversation settles, so the next conversation, in any
  app, already knows.

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

Then type `/mcp`, pick trustbrain and sign in.

**Another TrustBrain address** (for example a regional one): install the plugin from your
TrustBrain onboarding or Settings > Agents instead. It points at your address.

## Privacy

The plugin holds no secret and runs no code on your machine. Your AI reaches TrustBrain only
after you approve it on TrustBrain's page; revoke it any time in Settings > Agents. TrustBrain
keeps the facts it learns, each linked to its source, never the raw transcripts or chats.

This repository is generated from TrustBrain's source (`brain plugin`); changes go there.
