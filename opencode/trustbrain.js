// Memorable for OpenCode (https://github.com/NeuralTrust/trustbrain-plugin):
// the user's memory of their work, shared by every AI they use. It adds
// Memorable's MCP server; at the start of a session and before each message
// it gives what Memorable knows; after each turn it sends the session's new
// messages, which Memorable learns from when the workspace learns from
// sessions. All the logic is on the server. One file for OpenCode 1 and 2:
// put it in ~/.config/opencode/plugins/.
import { execFileSync } from "node:child_process"
import { mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs"
import { homedir, hostname } from "node:os"
import { join } from "node:path"

const BASE = (process.env.TRUSTBRAIN_URL || "https://brain.neuraltrust.ai").replace(/\/+$/, "")
const DIR = process.env.TRUSTBRAIN_HOME || join(homedir(), ".trustbrain")
const CLIENT = "opencode"
const TOKEN = join(DIR, `auth-${CLIENT}`)
const PENDING = join(DIR, `pending-${CLIENT}`)
const MCP = { type: "remote", url: `${BASE}/mcp` }

const read = (path) => {
  try {
    return readFileSync(path, "utf8").trim()
  } catch {
    return ""
  }
}

const keep = (path, text) => {
  mkdirSync(DIR, { recursive: true, mode: 0o700 })
  writeFileSync(path, text, { mode: 0o600 })
}

// The token file holds the header that carries it, as the sh hooks keep it.
const token = () => read(TOKEN).match(/^Authorization:\s*Bearer\s+(\S+)/i)?.[1] || ""

// remote is the repository's address, without credentials in it.
const remote = (dir) => {
  try {
    return execFileSync("git", ["-C", dir, "remote", "get-url", "origin"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 2000,
    })
      .trim()
      .replace(/:\/\/[^/@]*@/, "://")
  } catch {
    return ""
  }
}

const post = (path, body, timeout, headers = {}) =>
  fetch(BASE + path, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body,
    signal: AbortSignal.timeout(timeout),
  })

// What a hook would print, in Claude Code's form.
const contextOf = (body) => {
  try {
    return JSON.parse(body)?.hookSpecificOutput?.additionalContext || ""
  } catch {
    return ""
  }
}

// signIn returns the device's token, or the message that tells the person
// where to approve this device: once per device, at most every 14 minutes.
let signingIn
const signIn = () => (signingIn ??= startSignIn().finally(() => (signingIn = undefined)))

async function startSignIn() {
  const t = token()
  if (t) return { token: t }
  const pending = read(PENDING)
  if (pending) {
    try {
      const r = await post("/hooks/device/token", JSON.stringify({ device_code: pending }), 5000)
      const access = r.ok ? (await r.json()).access_token : ""
      if (access) {
        keep(TOKEN, `Authorization: Bearer ${access}\n`)
        rmSync(PENDING, { force: true })
        return { token: access }
      }
    } catch {}
    try {
      if (Date.now() - statSync(PENDING).mtimeMs < 14 * 60 * 1000) return {}
    } catch {}
  }
  try {
    const r = await post(`/hooks/device/code?client=${CLIENT}&event=SessionStart`, JSON.stringify({ device: hostname() }), 5000)
    const code = r.headers.get("X-TrustBrain-Device-Code")
    if (code) keep(PENDING, code)
    return { message: contextOf(await r.text()) }
  } catch {
    return {}
  }
}

// hook sends one event: what Memorable gives for it and, at the end of a
// turn, from which line it wants the session's transcript.
async function hook(name, body, dir, timeout) {
  const auth = await signIn()
  if (!auth.token) return { context: name === "Stop" ? "" : auth.message || "", from: -1 }
  const repo = remote(dir)
  try {
    const r = await post(`/hooks/${CLIENT}/${name}`, JSON.stringify(body), timeout, {
      Authorization: `Bearer ${auth.token}`,
      "X-TrustBrain-Repo": repo,
    })
    if (r.status === 401) {
      rmSync(TOKEN, { force: true })
      return { context: "", from: -1 }
    }
    const from = r.headers.get("X-TrustBrain-Send-From")
    return { context: contextOf(await r.text()), from: from === null ? -1 : Number(from), auth: auth.token, repo }
  } catch {
    return { context: "", from: -1 }
  }
}

// lines turns a session's messages (OpenCode 1's {info, parts} or 2's
// {id, type, content}) into transcript lines in Claude Code's form, one per
// message, what Memorable gave left out.
function lines(messages) {
  const out = []
  for (const m of messages || []) {
    const id = m.info?.id ?? m.id
    const role = m.info?.role ?? m.role ?? m.type
    if (!id || (role !== "user" && role !== "assistant")) continue
    const parts = m.parts ?? m.content ?? (m.text ? [{ type: "text", text: m.text }] : [])
    const blocks = []
    const results = []
    for (const p of parts) {
      if (!p || p.synthetic || p.ignored) continue
      if (p.type === "text" && p.text?.trim()) blocks.push({ type: "text", text: p.text })
      if (p.type === "tool") {
        blocks.push({ type: "tool_use", name: p.tool, input: p.state?.input ?? {} })
        const output = p.state?.output ?? p.state?.error
        if (output) results.push({ type: "tool_result", content: String(output).slice(0, 2000) })
      }
    }
    if (blocks.length) out.push({ id, line: JSON.stringify({ type: role, message: { role, content: blocks } }) })
    if (results.length) out.push({ id: `${id}:result`, line: JSON.stringify({ type: "user", message: { role: "user", content: results } }) })
  }
  return out
}

// A session's transcript can shrink when OpenCode compacts it: what was
// sent is remembered by message, from the first line Memorable asked for.
const sent = new Map()

async function capture(sessionID, dir, messagesOf) {
  const r = await hook("Stop", { session_id: sessionID, transcript_path: "opencode" }, dir, 5000)
  if (r.from < 0) return
  let all
  try {
    all = lines(await messagesOf(sessionID))
  } catch {
    return
  }
  let seen = sent.get(sessionID)
  if (!seen) sent.set(sessionID, (seen = new Set(all.slice(0, r.from).map((l) => l.id))))
  const fresh = all.filter((l) => !seen.has(l.id))
  if (!fresh.length) return
  try {
    const res = await fetch(`${BASE}/hooks/${CLIENT}/transcript?session=${encodeURIComponent(sessionID)}&from=${r.from}`, {
      method: "POST",
      headers: { "Content-Type": "application/x-ndjson", Authorization: `Bearer ${r.auth}`, "X-TrustBrain-Repo": r.repo },
      body: fresh.map((l) => l.line).join("\n"),
      signal: AbortSignal.timeout(30000),
    })
    if (res.ok) for (const l of fresh) seen.add(l.id)
  } catch {}
}

// context is what a message starts with: at a session's first, who the user
// is and what their agents learned in the repository; then what Memorable
// finds relevant to the message.
const started = new Set()

async function context(sessionID, prompt, dir) {
  const asks = []
  if (!started.has(sessionID)) {
    started.add(sessionID)
    asks.push(hook("SessionStart", { session_id: sessionID, source: "startup" }, dir, 5000))
  }
  if (prompt.trim()) asks.push(hook("UserPromptSubmit", { session_id: sessionID, prompt }, dir, 2500))
  const got = await Promise.all(asks)
  return [...new Set(got.map((g) => g.context).filter(Boolean))].join("\n\n")
}

// OpenCode 1: chat.message adds the context to the message, and the
// session's idle event sends what is new.
async function server({ client, directory }) {
  const dir = directory || process.cwd()
  return {
    config: async (cfg) => {
      cfg.mcp ??= {}
      cfg.mcp.trustbrain ??= { ...MCP, enabled: true }
    },
    "chat.message": async (input, output) => {
      const prompt = (output.parts || [])
        .filter((p) => p.type === "text" && !p.synthetic)
        .map((p) => p.text)
        .join("\n")
      const text = await context(input.sessionID, prompt, dir)
      if (text) {
        output.parts.push({
          id: `prt_trustbrain${Date.now()}`,
          sessionID: input.sessionID,
          messageID: output.message?.id,
          type: "text",
          text,
          synthetic: true,
        })
      }
    },
    event: async ({ event }) => {
      if (event?.type !== "session.idle") return
      const sessionID = event.properties?.sessionID
      if (!sessionID) return
      void capture(sessionID, dir, async (id) => {
        const r = await client.session.messages({ path: { id }, query: { directory: dir } })
        return Array.isArray(r) ? r : r?.data
      })
    },
  }
}

// OpenCode 2: the prompt hook finds the context once per message and the
// context hook adds it to every model call of the turn; a finished
// execution sends what is new.
async function setup(ctx) {
  const dir = ctx.location?.directory || process.cwd()
  const given = new Map()
  const abort = new AbortController()
  await ctx.mcp.transform((editor) => {
    if (!editor.get("trustbrain")) editor.set("trustbrain", MCP)
  })
  await ctx.session.hook("prompt", async (event) => {
    const sessionID = event.sessionID ?? event.session?.id
    if (sessionID) given.set(sessionID, await context(sessionID, event.prompt?.text || "", dir))
  })
  await ctx.session.hook("context", (event) => {
    const text = given.get(event.sessionID)
    if (text) event.system.push({ type: "text", text })
  })
  void (async () => {
    try {
      for await (const event of ctx.event.subscribe({ signal: abort.signal })) {
        const sessionID = event?.data?.sessionID
        if (event?.type === "session.execution.succeeded" && sessionID) {
          void capture(sessionID, dir, (id) => ctx.session.context({ sessionID: id }))
        }
      }
    } catch {}
  })()
  return () => abort.abort()
}

export default { id: "trustbrain", setup, server }
