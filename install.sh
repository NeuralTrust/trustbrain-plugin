#!/bin/sh
# Memorable for coding agents (https://github.com/NeuralTrust/trustbrain-plugin),
# plugin 2.1.3: adds Memorable's plugin to every coding agent on this
# computer, each in its own form: Claude Code and Codex from their plugin
# marketplace, Cursor as a local plugin, OpenCode as a plugin file. Each gets
# Memorable's MCP server, its skills, and hooks that start each session with
# what Memorable knows and send the session to learn from.
#
#   curl -fsSL https://brain.neuraltrust.ai/hooks/install.sh | sh
#   curl -fsSL https://brain.neuraltrust.ai/hooks/install.sh | sh -s -- --agents codex,cursor --yes
#
# Options: --agents claude,codex,cursor,opencode (default: those found),
# --yes (do not ask), --dry-run (say what it would do), --uninstall.
set -u

TB_URL="https://brain.neuraltrust.ai"
MARKETPLACE="trustbrain"
GITHUB="NeuralTrust/trustbrain-plugin"
HOME_DIR="${TRUSTBRAIN_HOME:-$HOME/.trustbrain}"
BUNDLE="$HOME_DIR/plugin"
CURSOR_DIR="$HOME/.cursor/plugins/local/trustbrain"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"
# The hooks.json the first installer wrote, to replace when nobody edited it.
LEGACY_CODEX='{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "command": "sh $HOME/.trustbrain/trustbrain.sh codex SessionStart",
            "timeout": 10,
            "type": "command"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "command": "sh $HOME/.trustbrain/trustbrain.sh codex Stop",
            "timeout": 30,
            "type": "command"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "command": "sh $HOME/.trustbrain/trustbrain.sh codex UserPromptSubmit",
            "timeout": 5,
            "type": "command"
          }
        ]
      }
    ]
  }
}'
LEGACY_CURSOR='{
  "hooks": {
    "afterAgentResponse": [
      {
        "command": "sh $HOME/.trustbrain/trustbrain.sh cursor afterAgentResponse"
      }
    ],
    "afterFileEdit": [
      {
        "command": "sh $HOME/.trustbrain/trustbrain.sh cursor afterFileEdit"
      }
    ],
    "afterMCPExecution": [
      {
        "command": "sh $HOME/.trustbrain/trustbrain.sh cursor afterMCPExecution"
      }
    ],
    "afterShellExecution": [
      {
        "command": "sh $HOME/.trustbrain/trustbrain.sh cursor afterShellExecution"
      }
    ],
    "beforeSubmitPrompt": [
      {
        "command": "sh $HOME/.trustbrain/trustbrain.sh cursor beforeSubmitPrompt"
      }
    ],
    "sessionStart": [
      {
        "command": "sh $HOME/.trustbrain/trustbrain.sh cursor sessionStart"
      }
    ],
    "stop": [
      {
        "command": "sh $HOME/.trustbrain/trustbrain.sh cursor stop"
      }
    ]
  },
  "version": 1
}'

have() { command -v "$1" >/dev/null 2>&1; }
say() { printf '%s\n' "$*"; }
run() {
  if [ "$DRY" = 1 ]; then
    say "  would run: $*"
    return 0
  fi
  "$@"
}
# quiet runs what may fail harmlessly (a marketplace already added).
quiet() {
  if [ "$DRY" = 1 ]; then
    say "  would run: $*"
    return 0
  fi
  "$@" >/dev/null 2>&1
}

AGENTS=""
YES=0
DRY=0
UNINSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --agents) AGENTS="${2:-}"; shift 2 ;;
    --agents=*) AGENTS="${1#*=}"; shift ;;
    -y|--yes) YES=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) say "Usage: install.sh [--agents claude,codex,cursor,opencode] [--yes] [--dry-run] [--uninstall]"; exit 0 ;;
    *) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
done

if [ -z "$AGENTS" ]; then
  have claude && AGENTS="$AGENTS claude"
  have codex && AGENTS="$AGENTS codex"
  { have cursor || have cursor-agent || [ -d "$HOME/.cursor" ] || [ -d /Applications/Cursor.app ]; } && AGENTS="$AGENTS cursor"
  { have opencode || [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" ]; } && AGENTS="$AGENTS opencode"
fi
AGENTS=$(printf '%s' "$AGENTS" | tr ',' ' ')
if [ -z "$(printf '%s' "$AGENTS" | tr -d ' ')" ]; then
  say "No coding agent found (Claude Code, Codex, Cursor, OpenCode). Install one, or name it: --agents codex"
  exit 1
fi
for a in $AGENTS; do
  case "$a" in claude|codex|cursor|opencode) ;; *) say "Unknown agent: $a (claude, codex, cursor or opencode)"; exit 2 ;; esac
done

if [ "$UNINSTALL" = 1 ]; then
  say "Memorable will be removed from:$(printf ' %s' $AGENTS)"
else
  say "Memorable ($TB_URL) will be added to:$(printf ' %s' $AGENTS)"
fi
if [ "$YES" != 1 ] && [ "$DRY" != 1 ] && [ -r /dev/tty ]; then
  printf 'Go on? [Y/n] '
  read -r answer </dev/tty || answer=""
  case "$answer" in n*|N*) exit 0 ;; esac
fi

# The plugin for every agent, from this Memorable, unpacked once.
FETCHED=0
fetch() {
  [ "$FETCHED" = 1 ] && return 0
  FETCHED=1
  [ "$DRY" = 1 ] && { say "  would download $TB_URL/api/plugin/agents.tar.gz into $BUNDLE"; return 0; }
  tmp=$(mktemp -d) || exit 1
  if ! curl -fsSL "$TB_URL/api/plugin/agents.tar.gz" | tar -xzf - -C "$tmp"; then
    say "Could not download Memorable's plugin from $TB_URL."
    rm -rf "$tmp"
    exit 1
  fi
  mkdir -p "$HOME_DIR" && chmod 700 "$HOME_DIR"
  rm -rf "$BUNDLE"
  mv "$tmp/trustbrain" "$BUNDLE"
  rm -rf "$tmp"
}

# retire moves aside a hooks.json the first installer wrote, when nobody
# edited it: the plugin brings its own hooks now.
retire() {
  file="$1"
  legacy="$2"
  [ -f "$file" ] || return 0
  if [ "$(cat "$file")" = "$legacy" ]; then
    run mv "$file" "$file.trustbrain-old"
    say "  moved the hooks the first installer wrote to $file.trustbrain-old"
  elif grep -q '.trustbrain/trustbrain.sh' "$file" 2>/dev/null; then
    say "  $file still runs ~/.trustbrain/trustbrain.sh: remove those hooks, the plugin brings its own"
  fi
}

claude_install() {
  say "Claude Code:"
  have claude || { say "  claude is not installed; skipped"; return 0; }
  source="${GITHUB:-$TB_URL/api/plugin/marketplace.json}"
  quiet claude plugin marketplace add "$source" || quiet claude plugin marketplace update "$MARKETPLACE" || true
  if run claude plugin install "trustbrain@$MARKETPLACE"; then
    say "  installed. In Claude Code, type /mcp, pick trustbrain and sign in."
  else
    say "  could not install; inside Claude Code run: /plugin marketplace add $source, then /plugin install trustbrain@$MARKETPLACE"
  fi
}

claude_uninstall() {
  say "Claude Code:"
  have claude && run claude plugin uninstall "trustbrain@$MARKETPLACE" || true
}

codex_install() {
  say "Codex:"
  have codex || { say "  codex is not installed; skipped"; return 0; }
  if ! codex plugin --help >/dev/null 2>&1; then
    say "  this Codex has no plugins: update it (npm install -g @openai/codex) and run this again"
    return 0
  fi
  if [ -n "$GITHUB" ]; then
    source="$GITHUB"
  else
    fetch
    source="$BUNDLE"
  fi
  quiet codex plugin marketplace add "$source" || quiet codex plugin marketplace upgrade "$MARKETPLACE" || true
  if quiet codex plugin add "trustbrain@$MARKETPLACE" || run codex plugin install "trustbrain@$MARKETPLACE"; then
    retire "${CODEX_HOME:-$HOME/.codex}/hooks.json" "$LEGACY_CODEX"
    say "  installed. In Codex, open /hooks and trust Memorable's hooks; sign in to its connector when Codex asks."
  else
    say "  could not install; in Codex open /plugins and add trustbrain from the $MARKETPLACE marketplace ($source)"
  fi
}

codex_uninstall() {
  say "Codex:"
  have codex || return 0
  quiet codex plugin remove "trustbrain@$MARKETPLACE" || true
  quiet codex plugin marketplace remove "$MARKETPLACE" || true
}

cursor_install() {
  say "Cursor:"
  fetch
  run mkdir -p "$(dirname "$CURSOR_DIR")"
  run rm -rf "$CURSOR_DIR"
  run cp -R "$BUNDLE" "$CURSOR_DIR"
  # Hooks run from where Cursor installed the plugin: its path, written out.
  if [ "$DRY" != 1 ]; then
    sed "s#\${CURSOR_PLUGIN_ROOT}#$CURSOR_DIR#g" "$CURSOR_DIR/hooks/cursor.json" >"$CURSOR_DIR/hooks/cursor.json.new" &&
      mv "$CURSOR_DIR/hooks/cursor.json.new" "$CURSOR_DIR/hooks/cursor.json"
  fi
  retire "$HOME/.cursor/hooks.json" "$LEGACY_CURSOR"
  say "  installed in $CURSOR_DIR. Reload Cursor (Developer: Reload Window) and connect Memorable's MCP server when it asks."
}

cursor_uninstall() {
  say "Cursor:"
  run rm -rf "$CURSOR_DIR"
}

opencode_install() {
  say "OpenCode:"
  fetch
  run mkdir -p "$OPENCODE_DIR"
  run cp "$BUNDLE/opencode/trustbrain.js" "$OPENCODE_DIR/trustbrain.js"
  say "  installed in $OPENCODE_DIR. Restart OpenCode, then sign in to the connector: opencode mcp auth trustbrain"
}

opencode_uninstall() {
  say "OpenCode:"
  run rm -f "$OPENCODE_DIR/trustbrain.js"
}

for a in $AGENTS; do
  if [ "$UNINSTALL" = 1 ]; then
    "${a}_uninstall"
  else
    "${a}_install"
  fi
done

if [ "$UNINSTALL" = 1 ]; then
  say "Done. This computer's sign-ins are in $HOME_DIR: delete it, and disconnect them in Memorable's Settings > Agents."
else
  say "Done. The first session asks you to approve this computer in Memorable, once per agent."
fi
