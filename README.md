# Memorable

Your memory of work, shared by every AI you use. Memorable learns your people, projects,
decisions and preferences from your meetings, documents and AI chats. This plugin connects
your AI to it:

- **The Memorable connector** (MCP): recall, search, explore, remember, correct and forget.
- **The memory skill**: your AI checks your brain before it answers about your work, and saves
  what each conversation settles, so the next conversation, in any app, already knows. The
  learn-repo skill teaches it the repository a coding agent works in.
- **Hooks for coding agents** (Claude Code): your memory, what your agents learned in the
  repository and your organization's procedures at the start of a session, what is relevant before
  each message, and the session's new lines at the end of each turn, to learn from. The first time
  a hook runs, it shows a link to approve the device.

## Install

- **Claude (web and desktop):** Customize > Plugins > Add > Upload plugin, pick this zip, then
  open the plugin's Connectors tab, click Connect and approve. Installing does not sign you in;
  on Team and Enterprise plans an Owner may need to add the connector first.
- **Claude Code:** `claude plugin install trustbrain --marketplace https://brain.neuraltrust.ai/api/plugin/marketplace.json`,
  then type `/mcp` and pick trustbrain to sign in.
- **Every coding agent on your computer** (Claude Code, Codex, Cursor, OpenCode; macOS and Linux):
  `curl -fsSL https://brain.neuraltrust.ai/hooks/install.sh | sh`.

You approve each app once, on Memorable's page. Revoke an app any time in Settings > Agents
at https://brain.neuraltrust.ai.
