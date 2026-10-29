#!/bin/sh
# Memorable hooks (https://github.com/NeuralTrust/trustbrain-plugin): sends a
# coding agent's hook event to Memorable and prints what it answers. All the
# logic is on the server; this needs only sh and curl. Usage:
#   trustbrain.sh <client> <event>    (the event's JSON on stdin)
TB_URL="${TRUSTBRAIN_URL:-https://brain.neuraltrust.ai}"
CLIENT="${1:-claude}"
EVENT="${2:-}"
DIR="${TRUSTBRAIN_HOME:-$HOME/.trustbrain}"
# The token is kept as the header that carries it, so curl reads it from the
# file and it never shows in the process list.
TOKEN_FILE="$DIR/auth-$CLIENT"
PENDING="$DIR/pending-$CLIENT"
# Where the agent works: Cursor runs a plugin's hooks from the plugin's own
# folder.
PROJECT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}"

# A hook that expects JSON gets an empty answer when Memorable has none.
nothing() {
  case "$EVENT" in
    Stop|SubagentStop|stop|afterAgentResponse|afterMCPExecution|afterShellExecution|afterFileEdit|sessionStart|postToolUse|postToolUseFailure) printf '{}' ;;
    beforeSubmitPrompt) printf '{"continue":true}' ;;
  esac
  exit 0
}

# Cursor runs Claude Code's hooks too; its own plugin answers there.
[ "$CLIENT" = claude ] && [ -n "$CURSOR_VERSION" ] && nothing
command -v curl >/dev/null 2>&1 || nothing
INPUT=$(cat)
mkdir -p "$DIR" 2>/dev/null && chmod 700 "$DIR" 2>/dev/null

# Cursor takes no context before a message: what Memorable found for it is
# kept, and printed after the message's first tool call.
CONVERSATION=$(printf '%s' "$INPUT" | sed -n 's/.*"conversation_id"[[:space:]]*:[[:space:]]*"\([A-Za-z0-9_-]*\)".*/\1/p' | head -n 1)
LATER="$DIR/later-$CLIENT-${CONVERSATION:-none}"
case "$EVENT" in
  postToolUse|postToolUseFailure)
    if [ -s "$LATER" ]; then
      cat "$LATER"
      rm -f "$LATER"
      exit 0
    fi
    nothing ;;
  UserPromptSubmit|beforeSubmitPrompt) WAIT=2 ;;
  SessionStart|sessionStart) WAIT=5 ;;
  *) WAIT=20 ;;
esac

# Signing in, once per device: the server gives a code the person approves
# in the browser; the next hook takes the token.
if [ ! -s "$TOKEN_FILE" ] && [ -s "$PENDING" ]; then
  TOKEN=$(printf '{"device_code":"%s"}' "$(cat "$PENDING")" | curl -s -m 5 -X POST "$TB_URL/hooks/device/token" \
    -H 'Content-Type: application/json' --data-binary @- | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  if [ -n "$TOKEN" ]; then
    (umask 077; printf 'Authorization: Bearer %s\n' "$TOKEN" > "$TOKEN_FILE")
    rm -f "$PENDING"
  fi
fi
if [ ! -s "$TOKEN_FILE" ]; then
  case "$EVENT" in
    SessionStart|sessionStart|UserPromptSubmit) ;;
    *) nothing ;;
  esac
  # A message asks a new code only once the last has run out; a new
  # session always does, so the link it shows is good.
  case "$EVENT" in
    SessionStart|sessionStart) ;;
    *) [ -s "$PENDING" ] && [ -n "$(find "$PENDING" -mmin -14 2>/dev/null)" ] && nothing ;;
  esac
  HDR=$(mktemp) || nothing
  BODY=$(curl -s -m 5 -D "$HDR" -X POST "$TB_URL/hooks/device/code?client=$CLIENT&event=$EVENT" \
    -H 'Content-Type: application/json' -d "{\"device\":\"$(hostname 2>/dev/null)\"}")
  CODE=$(sed -n 's/^[Xx]-[Tt]rust[Bb]rain-[Dd]evice-[Cc]ode: *\([^[:space:]]*\).*/\1/p' "$HDR")
  rm -f "$HDR"
  [ -n "$CODE" ] && (umask 077; printf '%s' "$CODE" > "$PENDING")
  printf '%s' "$BODY"
  exit 0
fi

# Only the repository's address: credentials in it (https://user:token@…) stay here.
REMOTE=$(git -C "$PROJECT" remote get-url origin 2>/dev/null | sed 's#://[^/@]*@#://#')
HDR=$(mktemp) || nothing
BODY=$(printf '%s' "$INPUT" | curl -s -m "$WAIT" -D "$HDR" -X POST "$TB_URL/hooks/$CLIENT/$EVENT" \
  -H @"$TOKEN_FILE" -H 'Content-Type: application/json' -H "X-TrustBrain-Repo: $REMOTE" --data-binary @-)
STATUS=$(sed -n 's/^HTTP\/[0-9.]* \([0-9]*\).*/\1/p' "$HDR" | tail -n 1)
FROM=$(sed -n 's/^[Xx]-[Tt]rust[Bb]rain-[Ss]end-[Ff]rom: *\([0-9]*\).*/\1/p' "$HDR")
SESSION=$(sed -n 's/^[Xx]-[Tt]rust[Bb]rain-[Ss]ession: *\([^[:space:]]*\).*/\1/p' "$HDR")
KEEP=$(sed -n 's/^[Xx]-[Tt]rust[Bb]rain-[Ll]ater: *\(1\).*/\1/p' "$HDR")
rm -f "$HDR"
if [ "$STATUS" = "401" ]; then
  rm -f "$TOKEN_FILE"
  nothing
fi
if [ "$KEEP" = 1 ] && [ -n "$BODY" ]; then
  (umask 077; printf '%s' "$BODY" > "$LATER")
  nothing
fi
# The end of a turn: the transcript's new lines, which the server does not
# have yet (it says from which).
if [ -n "$FROM" ] && [ -n "$SESSION" ]; then
  TRANSCRIPT=$(printf '%s' "$INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    tail -n +"$((FROM + 1))" "$TRANSCRIPT" | head -c 4000000 | curl -s -m 30 -o /dev/null -X POST \
      "$TB_URL/hooks/$CLIENT/transcript?session=$SESSION&from=$FROM" -H @"$TOKEN_FILE" \
      -H 'Content-Type: application/x-ndjson' -H "X-TrustBrain-Repo: $REMOTE" --data-binary @-
  fi
fi
[ -n "$BODY" ] && printf '%s' "$BODY" && exit 0
nothing
