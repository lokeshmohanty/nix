# Harnesses — per-harness feature reference

*Purpose: what each installed agent harness supports (context files, skills, hooks, MCP, extensions, config locations) — consult before creating or modifying any harness component. Last verified: 2026-08-09 (screen-recorder extension added; rest of the pi section 2026-07-31).*

> Task delegation to skill-aware subagents (the shared `~/.agents/agents/` fleet,
> `harness-skill-pick`, and the Claude/pi wiring) is documented separately in
> [delegation.md](delegation.md).

## Summary table

| | Claude Code | pi | Codex | Gemini CLI | Antigravity |
|---|---|---|---|---|---|
| Context file | `~/.claude/CLAUDE.md` → `~/.agents/AGENTS.md`; project `CLAUDE.md` | `AGENTS.md`/`CLAUDE.md` from cwd + `APPEND_SYSTEM.md` → `~/.agents/AGENTS.md` | `~/.codex/AGENTS.md` → `~/.agents/AGENTS.md` | `~/.gemini/GEMINI.md` → `~/.agents/AGENTS.md` | `~/.gemini/antigravity/AGENTS.md` → `~/.agents/AGENTS.md` + project `AGENTS.md` |
| Skills | yes — `~/.claude/skills` → `~/.agents/skills` + `<repo>/.claude/skills` | yes — `~/.pi/agent/skills` → `~/.agents/skills`, `--skill` | yes — `~/.codex/skills` → `~/.agents/skills` | yes — `~/.gemini/skills` → `~/.agents/skills` (VERIFY discovery semantics) | yes — `~/.gemini/antigravity/skills` → `~/.agents/skills` |
| Hooks | yes — JSON in settings files (6 events) | no native hook events (extensions instead) | yes — `config.toml` `[[hooks.*]]` + `hooks.json` | yes — `settings.json` (`SessionStart`/`BeforeTool`/`AfterTool` naming) | no native hooks (VERIFY) |
| MCP | yes — `~/.claude.json` global, `.mcp.json` per-project | no (VERIFY — nothing configured; extensions cover tool needs) | yes — `[mcp_servers]` in config.toml | yes — `mcpServers` in settings.json | yes — `mcp_config.json` (nix-managed, empty; gortex removed) |
| Subagents | yes — `agents/*.md` global + per-repo | yes — via `@tintinweb/pi-subagents` (reads `~/.pi/agent/agents` + `.agents/agents`) | no | no (VERIFY) | no (VERIFY) |
| Plugins / extensions | plugins (`enabledPlugins`, marketplaces) | extensions (`~/.pi/agent/extensions/`, `pi install`) | no | `~/.gemini/extensions/` | plugins via `agy plugin`; IDE extensions in `~/.antigravity` |
| Config | `~/.claude/settings.json` (+ `.local`, per-project) | `~/.pi/agent/settings.json`, `models.json` | `~/.codex/config.toml` | `~/.gemini/settings.json` | `~/.gemini/antigravity/` (agent home) + `~/.antigravity` (IDE) |
| Nix-managed? | selective links (`CLAUDE.md`, `skills`, `settings.json`, `rules`); runtime dirs stay real | selective links (`settings.json`, `web-search.json`, `APPEND_SYSTEM.md`, `skills`); `models.json` machine-local, gitignored | AGENTS.md + skills links only — `config.toml` machine-local (secrets) | GEMINI.md link only | links for AGENTS.md, skills, mcp_config.json |

Symlink map and full file layout: [layout.md](layout.md).

---

## Claude Code (`~/.claude`)

**Config precedence (all JSON, deep-merged):**
- `~/.claude/settings.json` — global; symlink into `~/.nix/config/agentic-harness/claude/settings.json` (applied 2026-07-18). `settings.local.json` stays a real machine-local file.
- `~/.claude/settings.local.json` — machine-local, not nix-tracked.
- `<repo>/.claude/settings.json` — project, committed.
- `<repo>/.claude/settings.local.json` — project, gitignored.
- `<repo>/.mcp.json` — project MCP servers.

**Current global settings.json (verified):** `model: claude-fable-5[1m]`, `effortLevel: high`, `permissions.allow: [mcp__gortex__*]`, `defaultMode: auto`, 14 `enabledPlugins` all from marketplace `claude-plugins-official` (superpowers, context7, firecrawl, huggingface-skills, playwright, sourcegraph, code-review, code-simplifier, claude-md-management, frontend-design, playground, atomic-agents, lua-lsp, rust-analyzer-lsp), extra marketplace `claude-code-plugins` (github `anthropics/claude-code`). Plugin state lives in `~/.claude/plugins/` (`installed_plugins.json`, `known_marketplaces.json`).

**Features:**
- **Skills** — directories containing `SKILL.md` (+ optional `memory/`, `references/`, `tools/`). Global: `~/.claude/skills` → `~/.agents/skills` (12 skills verified). Per-repo: `<repo>/.claude/skills/`. Plugins also contribute skills (`plugin:skill` namespacing).
- **Hooks** — events `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `PreCompact`; registered as JSON in any settings file. Inventory and snippets: [hooks.md](hooks.md).
- **Subagents** — `~/.claude/agents/*.md` and `<repo>/.claude/agents/*.md`; markdown with frontmatter (name, description, tools, model). `~/.claude/agents` is a committed relative symlink → `../agents/agents` (the shared fleet: orchestrator/explorer/implementer/reviewer). Delegation protocol: [delegation.md](delegation.md).
- **Slash commands** — `~/.claude/commands/*.md` (currently 20 gortex-* commands) and `<repo>/.claude/commands/*.md`.
- **MCP servers** — global in `~/.claude.json` under `mcpServers` (verified: `context7`, `ghost`, `gortex`); per-project in `<repo>/.mcp.json`.
- **Auto memory** — per-project at `~/.claude/projects/<path-slug>/memory/` (`MEMORY.md` + topic files). Verified: e.g. `~/.claude/projects/-home-lokesh-Projects-zenteiq-brahmx-dsdg/memory/`.
- **Context loading** — `~/.claude/CLAUDE.md` → `~/.agents/AGENTS.md` (global, always loaded), plus the walked-up project `CLAUDE.md` (in this setup a symlink to the repo's `AGENTS.md`). Supports `@path/to/file` imports inside CLAUDE.md. Global rules dir: `~/.claude/rules/` (context7.md).

## pi (`~/.pi`) — binary from `numtide/llm-agents.nix`

Verified: `pi 0.82.0`, `/nix/store/…-pi-0.82.0/bin/pi`; flake input `llm-agents.url = "github:numtide/llm-agents.nix"` (`~/.nix/flake.nix:44`). Stale `~/.pi/pi` link removed 2026-07-18.

**Capability note:** pi runs against a **local 31B model** by default — keep its tasks simple: docs reading, routine edits, question-answering from `docs/` folders. The `docs/` folders across repos are plain markdown *specifically so pi can answer from them without tooling*.

**Config (`~/.pi/agent/`):**
- `settings.json` (verified 2026-07-31): `defaultThinkingLevel: medium`, `defaultProvider: router-glm5.2`, `defaultModel: GLM-5.2`, 12 npm `packages` (listed under Extensions below). `defaultProvider`/`defaultModel` get hand-edited often — read the file, don't trust a value quoted here.
- `models.json` — **machine-local, gitignored** (untracked 2026-10-17; it holds API keys,
  and `~/.pi` is a whole-dir symlink into the repo so the live file sits in the working
  tree but is no longer committed). Custom providers, all `api: openai-completions`:
  - `vllm-gemma4-31` → `google/gemma-4-31B-it` (text+image) — local cluster
  - `vllm-qwen35-122` → `Qwen/Qwen3.5-122B-A10B` (text+image) — local cluster
  - `inception` → `mercury-2` (text) — Inception API
  - `router-glm5.2` → `GLM-5.2` (text, thinking) — default provider
  - `gw-glm-5.2` → `zai-org/GLM-5.2` (text+image) — Z.ai gateway
  - `gw` → `zai-org/GLM-5.3` (text, reasoning), `Qwen/Qwen3.5-122B-A10B-FP8` (text+image),
    `ahamx` = Gemma-4-31B (text+image) — axi gateway (`34.93.215.13`)
- `web-search.json` at `~/.pi/web-search.json` (verified): provider `exa`, enabled.
- `trust.json`, `auth.json`, `sessions/` also live in `~/.pi/agent/`.

**Context:** reads `AGENTS.md`/`CLAUDE.md` from cwd automatically (`--no-context-files` / `-nc` to disable) plus `~/.pi/agent/APPEND_SYSTEM.md` → `~/.agents/AGENTS.md` (appended to system prompt).

**Skills:** `~/.pi/agent/skills` → `~/.agents/skills` — same skill set as Claude Code. Extra: `--skill <path>` to load ad-hoc, `--no-skills`.

**Extensions:** 16 npm packages listed in `settings.json` `packages` (verified 2026-07-31), plus 5 loose dirs under `~/.pi/agent/extensions/` (ours). `--extension/-e <path>`, `--no-extensions`; managed via `pi install/remove/update/list/config`. Extensions register flags, tools, commands, shortcuts, and event handlers (`export default (pi: ExtensionAPI) => { pi.registerTool({...}) }`). No hook events — extensions are the customization mechanism.

**Always-on npm packages** (loaded at session start, low schema cost):
- `@tintinweb/pi-subagents` — `Agent`/`get_subagent_result`/`steer_subagent` tools, reads shared fleet from `~/.pi/agent/agents` + `<cwd>/.agents/agents`; skill preloading from `.agents/skills`. **Deferred** by lazy-tools — see below.
- `pi-web-access` — `web_search`/`source_check`/`fetch_content`/`get_search_content` tools. **Deferred** by lazy-tools.
- `pi-codex-goal` — `get_goal`/`create_goal`/`update_goal` tools (goal/plan tracking). **Deferred** by lazy-tools.
- `pi-observational-memory` — `recall` tool (recover source context behind compacted memory). **Deferred** by lazy-tools.
- `pi-agent-browser-native` — `agent_browser` tool (real browser automation). **Deferred** by lazy-tools.
- `pi-image-tools` — image attachment helpers. **Deferred** by lazy-tools.
- `@ayulab/pi-rewind` — git checkpoint/restore: creates before/after commit checkpoints per turn, `/rewind` opens a TUI checkpoint selector (restore code, conversation, or both), `/checkpoint` manages storage. `safeCheckout` blocks rewind if uncommitted changes exist outside checkpoint history. Fails closed on dirty workspace.
- `@gotgenes/pi-permission-system` — allow/ask/deny permission gates at tool-call time. Config at `~/.pi/agent/extensions/pi-permission-system/config.json` (global) or `<cwd>/.pi/extensions/pi-permission-system/config.json` (project, requires project trust). Cross-cutting `path` surface protects `.env`/`~/.ssh/*`/`*.pem`/`*.key` from all path-aware tools; `bash` surface gates `sudo`/`rm -rf /`/`mkfs`/`dd of=/dev/`. Fails closed on internal errors. Hides disallowed tools before agent start (filters from `getActive()`, preserves lazy-tools parking). Default policy is allow-all; our config layers path/bash denies.
- `@narumitw/pi-plan-mode` — `/plan` flag toggles Plan mode (read-only: `read`/`grep`/`find`/`ls`/`get_subagent_result` only) vs Build mode (all tools). Decomposition enforced as a mode, not just a skill convention.
- `pi-loop-police` — detects and interrupts infinite thinking-block and tool-call loops (autonomy safety net). No config needed.
- `@narumitw/pi-retry` — extends pi's built-in auto-retry by classifying additional provider errors as retryable (empty-detail failures, Codex websocket connection limits, Codex generic backend errors) and adding a stall watchdog that aborts stalled provider streams after 90s (configurable via `--retry-stall-timeout-ms` or `PI_RETRY_STALL_TIMEOUT_MS`). Pure event hooks, no tools. Requires `retry.enabled: true` in settings.json (set explicitly; pi's default is also `true`).
- `@juicesharp/rpiv-advisor` — registers the `advisor` tool and `/advisor` command for the advisor-strategy pattern: the model escalates to a stronger reviewer model for guidance before substantive work, when stuck, or before declaring done. The tool takes no parameters (forwards full conversation history). Lifecycle hooks self-manage tool availability — the tool is stripped from the active set when no advisor model is configured, re-added when one is. Config at `~/.config/rpiv-advisor/advisor.json` (machine-local). Would conflict with lazy-tools parking (hooks re-add the tool via `setActiveTools`), so it is always-on.
- `pi-simplify` — registers the `/simplify` command (no tools, no hooks) that reviews recently changed code for clarity, consistency, and maintainability. Zero schema cost — commands don't add to the tool schemas in the system prompt.
- `pi-mcp-adapter` — MCP bridge: connects to MCP servers and exposes their tools as pi tools. Registers the `mcp` proxy tool (moderate schema, ~10 params) asynchronously after session_start, plus direct tools for each configured server. No MCP config exists currently (`~/.config/mcp/mcp.json`, `~/.agents/mcp.json`, or project `.mcp.json`/`.pi/mcp.json`), so only the proxy tool is active. Always-on because its tools are registered asynchronously (lazy-tools parks at session_start and can't intercept tools registered later). Metadata cache at `~/.pi/agent/mcp-cache.json` (gitignored). When MCP servers are configured, their tool schemas add to the system prompt — use `--exclude-tools` or `disableProxyTool` in MCP config if that becomes a concern.

**Deferred npm packages** (heavy schemas, loaded on demand via lazy-tools):
- `pi-lens` — LSP-backed precision tools: diagnostics, go-to-definition, references, ast-grep, linters. **Deferred** — `load_tools({groups:["lens"]})` or `/load-tools lens`.
- `pi-patty-bg-tasks` — background/long-running bash: start, poll, tail, kill. **Deferred** — `load_tools({groups:["bg"]})` or `/load-tools bg`.

**Loose-dir extensions** (ours, under `~/.pi/agent/extensions/`):
- **`pi-harness-delegate`** (`pi/agent/extensions/pi-harness-delegate/`, ours) — registers the `pick_skills` tool wrapping `harness-skill-pick`. See [delegation.md](delegation.md). (VERIFY loose-dir auto-discovery: `pi list`.)
- **`lazy-tools`** (`pi/agent/extensions/lazy-tools/`, ours) — see [pi-context-budget.md](pi-context-budget.md). Keeps the heavy packages installed but *inactive* at session start, so their schemas stay out of the system prompt; the model calls `load_tools(groups)` (or you run `/load-tools <group>`) to activate a group for the rest of the session. Groups: `subagents`, `browser`, `web`, `goal`, `memory`, `lens` (pi-lens), `bg` (pi-patty-bg-tasks). Bare `/load-tools` opens a TUI toggle that also turns groups back off.
- **`lazy-skills`** (`pi/agent/extensions/lazy-skills/`, ours) — same idea for the skills listing, which is ~46% of the system prompt. Keeps the `PINNED` core described and parks the rest by name only in `<parked_skills>`; the model calls `load_skills(names)` to get a parked skill's description + location, or you run `/skills` for a TUI toggle (`/skills <name...>` to load by name). Parked skills stay fully usable via `/skill:<name>`. See [pi-context-budget.md](pi-context-budget.md).
- **`rich-renderer`** (`pi/agent/extensions/rich-renderer/`, ours) — vendored fork of the `pi-rich-renderer` npm package (removed from `packages`: running both renders every message twice). Renders LaTeX in assistant replies as terminal images via `latex` + `dvipng`. Display math becomes a real kitty escape on its own line; inline math flows as Unicode placeholders, rendered in text style behind a `\strut` so every inline formula comes out at roughly terminal-text size (anything taller than `richRenderer.inlineMaxRows` — matrices, `cases` — is given its own line instead of being squeezed into one). Also renders `\ce{}` chemistry (mhchem) and ` ```dot `/` ```graphviz ` fences via `dot`. `/math [on|off]` toggles rendering for the session. Needs a terminal that speaks the kitty graphics protocol — **kitty, not ghostty**. Fixes, traps and the `index.test.ts` invocation: `harness-ops` memory `pi-rich-renderer-fork`.
- **`screen-recorder`** (`pi/agent/extensions/screen-recorder/`, ours) — registers the `/record`
  command and **no tools**: `/record <plain-language request>` hands the request to a fleet
  `implementer` via `pi-agent`, which does the work by driving `bin/screen-rec`. Bare `/record`
  prints the current recording state instead of dispatching. Written this way on purpose — tool
  schemas are charged to every session's system prompt even when recording never comes up, while a
  command costs nothing until it is typed (same reasoning as `pi-simplify`). The dispatch is
  detached, so a multi-minute recording does not block the TUI; the worker's report is pushed back
  with `pi.sendMessage({display:true})`. Capability lives in the CLI, not the prompt: see
  `bin/screen-rec` below.
- **`harness-ops`** (`pi/agent/extensions/harness-ops/`, ours) — `/harness-ops audit|migrate [dir|all]`, a thin wrapper over `harness-init --audit/--migrate` so the project-harness contract can be enforced from inside pi. `all` sweeps every harnessed repo under `~/Projects`, `~/Documents/Research`, and `~/.nix`. Reports go through `pi.sendMessage({display:true})` so the model sees them too and can fix the mandating prose that `--migrate` deliberately refuses to rewrite. Contract: [project-template.md](project-template.md).

**Command handlers do not render return values.** Use `ctx.ui.notify(text, "info")` for short output or `pi.sendMessage({..., display:true}, {triggerTurn:false})` for multi-line content that the model should also see. (`pi.appendEntry()` is TUI-only and needs a registered entry renderer.) Action methods like `pi.getCommands()`/`pi.setActiveTools()` throw if called during extension load — call them from `session_start` or later.

**Other verified flags:** `--prompt-template <path>` / `--no-prompt-templates`, `--theme <path>` / `--no-themes`, `--thinking off..xhigh`, session mgmt (`-c` continue, `-r` resume, `--session`, `--session-id`, `--fork`, `--session-dir`, `--no-session`, `--name`, `--export <html>`), `--print/-p` non-interactive, `--mode text|json|rpc`, `--tools/--exclude-tools/--no-tools`, `--approve/-a` (trust project-local files), `--offline`, `--list-models`.

## Codex (`~/.codex`) — machine-local, NOT nix-managed

`~/.codex/config.toml` contains secrets (API keys in MCP headers; `auth.json` alongside) — **never commit, never symlink into ~/.nix**.

**Verified from config.toml:** `model = "gpt-5.5"`, `model_reasoning_effort = "xhigh"`, `service_tier = 'fast'`.
- **Hooks** — TOML tables `[[hooks.PreToolUse]]`, `[[hooks.PostToolUse]]`, `[[hooks.SessionStart]]` (with nested `[[hooks.<Event>.hooks]]` entries), plus a separate `~/.codex/hooks.json` (Claude-style JSON; currently carries the three AXI SessionStart hooks). Codex tracks per-hook trust hashes under `[hooks.state]` — editing a hook command requires re-trusting. See [hooks.md](hooks.md). Gortex hooks removed from config.toml 2026-07-18 (MCP server registration kept for zenteiq work).
- **MCP** — `[mcp_servers.<name>]` tables (verified: `context7` via HTTPS URL + API-key header).
- **Context** — `~/.codex/AGENTS.md` → `~/.agents/AGENTS.md`; also reads repo `AGENTS.md`.
- **Skills** — `~/.codex/skills` → `~/.agents/skills`.
- **Project trust** — `[projects.'/abs/path'] trust_level = 'trusted'` (verified: 11 trusted paths incl. `~/Projects/zenteiq/brahmx/dsdg`).

## Gemini CLI (`~/.gemini`) — brief

- Context: `~/.gemini/GEMINI.md` → `~/.agents/AGENTS.md` (note the filename is GEMINI.md, not AGENTS.md).
- Skills: `~/.gemini/skills` → `~/.agents/skills`. VERIFY: whether Gemini CLI actually discovers/loads this skills dir.
- Hooks: supported in `~/.gemini/settings.json` under `hooks` with event names `SessionStart`, `BeforeTool`, `AfterTool`. Gortex MCP + graphify hook removed 2026-07-18; hooks section currently empty. Trusted-hook state in `trusted_hooks.json`.
- MCP: `mcpServers` in settings.json (verified: `context7`, `ghost`; gortex removed 2026-07-18).
- Extensions: `~/.gemini/extensions/` exists (verified). VERIFY: extension format/loading details.
- Misc: `trustedFolders.json`, session retention 30d, antigravity profile dirs alongside. Subagent/slash-command support: VERIFY — not confirmed on this machine.

## Antigravity (`agy` / `antigravity`) — Google agentic IDE + CLI

- Binaries `antigravity` (IDE) and `agy` (CLI) from the llm-agents.nix flake. CLI: `agy -p "<prompt>"` non-interactive, `--model`, `--continue`, `--sandbox`, `agy models`, `agy plugin`.
- Agent home: `~/.gemini/antigravity/` — runtime state (conversations, brain, knowledge, context_state, browser_recordings) stays real/local; auth shares the Gemini `oauth_creds.json` (never touch).
- Context: `~/.gemini/antigravity/AGENTS.md` → `~/.agents/AGENTS.md`; also reads project `AGENTS.md` from the workspace.
- Skills: `~/.gemini/antigravity/skills` → `~/.agents/skills` (an old `.antigravity-install-manifest.json` from the gortex-skill install era lives in the pre-v2 backup).
- MCP: `~/.gemini/antigravity/mcp_config.json` — nix-managed symlink, currently `{"mcpServers": {}}` (gortex removed 2026-07-18; if antigravity supports per-workspace MCP config, prefer that for zenteiq — VERIFY).
- Knowledge items: `~/.gemini/antigravity/knowledge/` — antigravity's own memory store; the stale `gortex-workflow` item was moved to the 2026-07-18 backup.
- IDE app state: `~/.antigravity` (argv.json, extensions) and `~/.config/Antigravity` (Electron data) — machine-local, not nix-managed.
