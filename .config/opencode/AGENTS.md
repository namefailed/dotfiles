You have access to a shared knowledge base via Basic Memory MCP tools (http://127.0.0.1:8765/mcp).
This memory is shared across multiple AI tools — treat it as a collective persistent brain.
Your identity in this system: opencode

START of session: call read_note("index"), read_note("active-context"), read_note("user/user-profile").
DURING session: write facts, decisions, and preferences to memory using write_note / edit_note. Tag your entries with #opencode.
END of session: update active-context if anything changed. Append a short entry to logs/ai-log.

Keep notes concise. Use observation format: - [category] fact #tag
Never delete another AI's notes. Prefer appending over overwriting.

## Line endings
All `.org` files must use LF (`\n`) line endings — CRLF (`\r\n`) causes `^M` in Emacs. Never write `.org` files with CRLF. See `conventions/line-endings` in Basic Memory for fix details.

## Basic Memory Architecture & Protocols (System Update)

### Self-Serve Context
No need to scan dozens of files to figure out what happened while offline. Read `logs/daily-digest.md` — a background cron script generates this daily, detailing exactly what files were modified in the last 24 hours.

### Task Claiming
To prevent duplicate work, claim your tasks. Before starting deep work, add your task to the `## Currently In Progress` section of `active-context.md` and append `[LOCKED: opencode]`. Remove the lock when finished.

### Session Checkpoints
If your session is interrupted or you finish a chunk of work, leave a 1-line breadcrumb. Prepend `- [CHECKPOINT: opencode] (what you did/what's next)` to the `## 🔔 Recent Handoffs` section of `active-context.md` so the next AI can pick up seamlessly.

### Dispute Protocol
If you strongly disagree with an architectural choice made by Hermes or another AI, do not silently overwrite it. Change the lock to `[DISPUTE: opencode]`, document your reasoning in `reference/conflict-resolution.md`, and halt until Matt arbitrates.

### Canonical Tags
When creating new notes, do not invent new tags. Rely strictly on the Map of Content (MOC) index found at `reference/tags.md`.

### Garbage Collection
Basic Memory is self-cleaning. If you see notes older than 7 days flagged in the daily digest, curate them into permanent `reference/` notes or delete them. Stale code/projects go to the `archive/` folder.

**First action on any new task**: check `active-context.md` and the daily digest.
