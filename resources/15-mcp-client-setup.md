# MCP Client Setup — Ghidra + Guest Runtime MCP (Client-Agnostic)

Read this when wiring **GhidraMCP** (`04-ghidra-mcp.md`) and/or optional **guest runtime** MCP into any MCP host: Cursor, Claude Desktop, VS Code, Codex, OpenCode, Windsurf, or other stdio/HTTP MCP clients.

**Guest runtime (pick one if any):** [Mupen64MCP](https://github.com/DohmBoy64Bit/Mupen64MCP) (`17-mupen64mcp-playbook.md`, server id `n64-debug-mcp`) or [RMG MCP](https://github.com/thebardockgames/RMG) (`14-rmg-mcp-playbook.md`, server id `rmg-n64-debugger`).

**Goal:** one mental model — discover the client, set absolute paths once, use the same server names everywhere.

---

## Server names (use consistently)

| MCP server id | Stack | Required? |
|---------------|-------|-----------|
| `ghidra` | bethington/ghidra-mcp bridge → Ghidra HTTP plugin | Recommended for static analysis |
| `n64-debug-mcp` | [DohmBoy64Bit/Mupen64MCP](https://github.com/DohmBoy64Bit/Mupen64MCP) `n64-debug-mcp` → TCP daemon → Mupen64Plus | Optional guest runtime (preferred when user has this build) |
| `rmg-n64-debugger` | thebardockgames/RMG `server.py` → WebSocket bridge | Optional guest runtime (alternative to Mupen64MCP) |

Do not rename these in docs unless the user's client forbids a name — then document the alias in `N64_PROJECT_STATE.md`.

---

## Phase 0 — Discover the MCP client (before writing config)

Ask or infer **one** host; do not guess config paths.

```text
[ ] Which MCP host? (Cursor / Claude Desktop / VS Code / Codex / OpenCode / other)
[ ] Project-level or user-global config?
[ ] stdio (spawn process) or HTTP (URL) for Ghidra?
[ ] Absolute paths recorded in N64_PROJECT_STATE.md?
```

### Known config locations

| Host | Typical config file | Format |
|------|---------------------|--------|
| **Cursor** | `.cursor/mcp.json` (workspace) or `%USERPROFILE%\.cursor\mcp.json` | JSON `mcpServers` |
| **Claude Desktop** | `%APPDATA%\Claude\claude_desktop_config.json` (Win) / `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) | JSON `mcpServers` |
| **VS Code** (MCP extension) | User/workspace `mcp.json` per extension docs | JSON |
| **Codex** | `~/.codex/config.toml` or project `.codex/config.toml` | TOML `[mcp_servers.name]` |
| **OpenCode** | `opencode.json` / host-specific MCP section | JSON (varies by version) |
| **Generic HTTP** | Any client supporting `url` transport | JSON `url` field |

If the user already has a working MCP entry for another project, **mirror its shape** — only swap `command`/`args`/`env`/`url`.

---

## Phase 1 — Ghidra stack (static analysis)

Order matters: **ROM loader → analyze → GhidraMCP plugin → bridge → MCP client**.

### 1.1 Ghidra + N64 ROM loader ([N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV))

N64LoaderWV is the recommended Ghidra extension for `.z64` / `.n64` / `.v64`:

- Fixes endianness (big / little / mixed) at import
- Maps ROM, RAM, and boot regions for MIPS analysis
- Optional signature/pattern file for **symbol hints** (treat like n64sym — not proof)

**Install (release ZIP — preferred):**

```text
1. Download latest release ZIP from https://github.com/zeroKilo/N64LoaderWV/releases
   (match Ghidra major version when possible — e.g. Ghidra 12.1 release)
2. Ghidra → File → Install Extensions… → + → select ZIP
3. Restart Ghidra
4. File → Configure → Configure All Plugins → enable N64LoaderWV if needed
```

**Build from source (when no matching release):**

```bash
# Requires JDK 17+ and Gradle; set GHIDRA_INSTALL_DIR to your Ghidra root
export GHIDRA_INSTALL_DIR=/path/to/ghidra_12.1_PUBLIC
cd N64LoaderWV
gradle
# Install ZIP from dist/ via File → Install Extensions
```

**Load ROM:**

```text
1. File → Import File → baserom.z64 (or .n64 / .v64)
2. Format: N64 ROM (N64LoaderWV) — not raw binary / wrong arch
3. Run auto-analysis; confirm Language = MIPS:BE:64:default (or LE for rare titles)
4. Confirm segment bases match your splat yaml (KSEG0 vs ROM mapping)
```

**Optional symbol hints file:** N64LoaderWV can consume a pattern/signature file (see repo `example_n64sym.txt`, `example_signatures.txt`). **Hints only** — still require ledger + raw MIPS before `symbol_addrs` (`05-function-discovery.md`, `06-libultra.md`).

Record in state file: Ghidra version, N64LoaderWV version, program name, language/endianness.

### 1.2 GhidraMCP plugin ([bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp))

Full build/deploy: `04-ghidra-mcp.md`. Short sequence:

```text
1. Build or install GhidraMCP extension ZIP into the same Ghidra
2. Open the N64 program in CodeBrowser
3. File → Configure → Configure All Plugins → GhidraMCP → enabled
4. Tools → GhidraMCP → Start MCP Server
5. curl http://127.0.0.1:8089/check_connection  → must succeed
6. Run Python bridge (stdio or HTTP) — see §2 below
```

**Blocker check:** GhidraMCP on a **non-N64** program (wrong loader, XEX, raw binary) produces useless evidence at VRAM `0x80xxxxxx`. Fix N64LoaderWV import first.

---

## Phase 2 — Mupen64MCP stack (optional guest runtime)

Only when static path stalls or user needs live guest RDRAM/registers/breakpoints. Full clone + build: `17-mupen64mcp-playbook.md`.

```text
1. git clone https://github.com/DohmBoy64Bit/Mupen64MCP.git
2. MSYS2 MINGW64: build mupen64plus.dll (DEBUGGER, NO_ASM=1) → n64-debug-daemon.exe → optional input-inject DLL
3. cd mcp/python && uv sync  (or pip install -e .)
4. Wire MCP client server id n64-debug-mcp — §4.4
5. n64_start_daemon (tool) or manual daemon on port 9876 → n64_status succeeds
```

---

## Phase 2b — RMG stack (optional guest runtime — alternative)

Only if the user has RMG built instead of (or in addition to) Mupen64MCP. Full build: `14-rmg-mcp-playbook.md`.

```text
1. Build RMG fork with -DMCP_BRIDGE=ON (Windows MSYS2 ucrt64 per fork README)
2. pip install mcp websockets
3. Launch RMG.exe → load user's ROM (lawful copy only)
4. python server.py  (or let MCP client spawn it — §4.3)
5. MCP tool bridge_status → connected
```

Do not require both Phase 2 and Phase 2b — one guest runtime MCP is enough.

---

## Phase 3 — Path variables (client-agnostic)

Set **absolute paths** once; reuse in every host's config. Suggested env vars (user shell or MCP `env` block):

| Variable | Example | Purpose |
|----------|---------|---------|
| `GHIDRA_MCP_ROOT` | `C:/tools/ghidra-mcp` | Clone root (contains `bridge_mcp_ghidra.py`) |
| `GHIDRA_MCP_BRIDGE` | `C:/tools/ghidra-mcp/bridge_mcp_ghidra.py` | Stdio bridge script |
| `GHIDRA_MCP_HTTP_URL` | `http://127.0.0.1:8081/mcp` | Only if using HTTP transport |
| `RMG_MCP_ROOT` | `C:/tools/RMG` | Fork root (contains `server.py`) |
| `RMG_MCP_SERVER` | `C:/tools/RMG/server.py` | Stdio MCP server |
| `RMG_MCP_HOST` | `127.0.0.1` | WebSocket target (RMG GUI) |
| `RMG_MCP_PORT` | `8765` | WebSocket port |
| `RMG_MCP_TIMEOUT_SECONDS` | `5.0` | Bridge timeout |
| `MUPEN64MCP_ROOT` | `C:/tools/Mupen64MCP` | Clone root |
| `MUPEN64MCP_PYTHON_DIR` | `C:/tools/Mupen64MCP/mcp/python` | `uv --directory` target for `n64-debug-mcp` |
| `MUPEN64MCP_DAEMON` | `C:/tools/Mupen64MCP/native/n64_debug_daemon/build/n64-debug-daemon.exe` | Manual daemon launch |
| `MUPEN64MCP_CORE_DLL` | `C:/tools/Mupen64MCP/build/mupen64plus/lib/mupen64plus.dll` | Core with DEBUGGER |
| `N64_DAEMON_PORT` | `9876` | TCP port (Mupen64MCP default) |

**Python launcher:** prefer `python` on PATH, or `uv run` / `uv --directory` if the user standardizes on uv — match what works in a bare terminal first.

---

## Phase 4 — Canonical server definitions

### 4.1 Ghidra — stdio (default)

```json
{
  "mcpServers": {
    "ghidra": {
      "command": "python",
      "args": ["<GHIDRA_MCP_BRIDGE>"],
      "env": {}
    }
  }
}
```

Replace `<GHIDRA_MCP_BRIDGE>` with absolute path. On Windows use forward slashes or escaped backslashes in JSON.

**uv variant (when user uses uv for the bridge venv):**

```json
"ghidra": {
  "command": "uv",
  "args": ["run", "--script", "<GHIDRA_MCP_BRIDGE>"]
}
```

### 4.2 Ghidra — HTTP (when bridge runs streamable-http)

Start bridge manually:

```bash
python bridge_mcp_ghidra.py --transport streamable-http --mcp-host 127.0.0.1 --mcp-port 8081
```

Client entry:

```json
"ghidra": {
  "url": "http://127.0.0.1:8081/mcp"
}
```

Ghidra plugin HTTP (`8089`) and MCP HTTP (`8081`) are **different** layers — both must be up for HTTP mode.

### 4.3 RMG — stdio

```json
{
  "mcpServers": {
    "rmg-n64-debugger": {
      "command": "python",
      "args": ["<RMG_MCP_SERVER>"],
      "env": {
        "RMG_MCP_HOST": "127.0.0.1",
        "RMG_MCP_PORT": "8765",
        "RMG_MCP_TIMEOUT_SECONDS": "5.0"
      }
    }
  }
}
```

RMG GUI must stay open with ROM loaded while tools run.

### 4.4 Mupen64MCP — stdio (uv)

```json
{
  "mcpServers": {
    "n64-debug-mcp": {
      "command": "uv",
      "args": [
        "--directory",
        "<MUPEN64MCP_PYTHON_DIR>",
        "run",
        "n64-debug-mcp"
      ]
    }
  }
}
```

Daemon may be started via `n64_start_daemon` MCP tool or manually (`17-mupen64mcp-playbook.md`). ROM path stays in user workspace — do not commit ROM paths to shared MCP config.

**pip variant (no uv):**

```json
"n64-debug-mcp": {
  "command": "python",
  "args": ["-m", "n64_debug_mcp.server"],
  "env": {
    "PYTHONPATH": "<MUPEN64MCP_PYTHON_DIR>"
  }
}
```

Verify module name against upstream `pyproject.toml` if the entry point changes.

### 4.5 All servers (combined JSON fragment)

```json
{
  "mcpServers": {
    "ghidra": {
      "command": "python",
      "args": ["C:/tools/ghidra-mcp/bridge_mcp_ghidra.py"]
    },
    "n64-debug-mcp": {
      "command": "uv",
      "args": [
        "--directory",
        "C:/tools/Mupen64MCP/mcp/python",
        "run",
        "n64-debug-mcp"
      ]
    },
    "rmg-n64-debugger": {
      "command": "python",
      "args": ["C:/tools/RMG/server.py"],
      "env": {
        "RMG_MCP_HOST": "127.0.0.1",
        "RMG_MCP_PORT": "8765",
        "RMG_MCP_TIMEOUT_SECONDS": "5.0"
      }
    }
  }
}
```

Include only servers the user has built. Typical: **ghidra** + one guest runtime (`n64-debug-mcp` *or* `rmg-n64-debugger`).

Copy `examples/mcp-servers.template.json` and fill paths — do not commit secrets or ROM paths.

---

## Phase 5 — Per-host wiring (same servers, different file shape)

### Cursor / Claude Desktop / VS Code (JSON)

Merge §4.5 into the host's `mcpServers` object (subset OK). Restart the host or reload MCP after save.

### Codex (TOML)

```toml
[mcp_servers.ghidra]
command = "python"
args = ["C:/tools/ghidra-mcp/bridge_mcp_ghidra.py"]

[mcp_servers.rmg-n64-debugger]
command = "python"
args = ["C:/tools/RMG/server.py"]

[mcp_servers.rmg-n64-debugger.env]
RMG_MCP_HOST = "127.0.0.1"
RMG_MCP_PORT = "8765"
RMG_MCP_TIMEOUT_SECONDS = "5.0"

[mcp_servers.n64-debug-mcp]
command = "uv"
args = ["--directory", "C:/tools/Mupen64MCP/mcp/python", "run", "n64-debug-mcp"]
```

### HTTP-only clients

If the host only supports `url` and not stdio, run both bridges as long-lived processes and point:

- Ghidra → `GHIDRA_MCP_HTTP_URL`
- RMG → only stdio in upstream fork today — spawn `server.py` via wrapper script or use a host that supports stdio

---

## Phase 6 — Verify end-to-end

### Ghidra path

```bash
curl http://127.0.0.1:8089/check_connection
curl http://127.0.0.1:8089/get_version
```

From MCP client (after connect): `check_connection` / `instances_list` — confirm **MIPS N64** program name matches state file.

### Mupen64MCP path

From MCP client: `n64_status` — core connected, ROM loaded, PC/frame reported. If daemon not auto-started: verify `n64-debug-daemon.exe` on port 9876 (`17-mupen64mcp-playbook.md`).

### RMG path

From MCP client: `bridge_status` — must report bridge ready with ROM loaded.

### State file updates

Update `N64_PROJECT_STATE.md`:

```text
GhidraMCP: extension version / HTTP port / bridge path / MCP server id "ghidra"
N64LoaderWV: version / program name / language
Mupen64MCP: clone path / daemon+core DLL paths / MCP server id "n64-debug-mcp" / ROM loaded
RMG MCP (if used): RMG build / server.py path / host:port / symbols map path
MCP host: Cursor|Claude|… / config file path used
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| MCP tools missing | Client not restarted after config edit | Reload MCP / restart IDE |
| Ghidra connects but wrong bytes at `0x80xxxxxx` | Non-N64 program loaded | Re-import with N64LoaderWV |
| `check_connection` fails | Plugin not started | Tools → GhidraMCP → Start MCP Server |
| Bridge starts, MCP empty | Wrong `bridge_mcp_ghidra.py` path | Absolute path in `args` |
| `n64_status` fails | Daemon down or wrong `uv` path | Build per `17-mupen64mcp-playbook.md`; check port 9876 |
| Mupen64MCP BP never hits | Dynarec enabled | Core must use interpreter (`R4300Emulator=0`, `NO_ASM=1` build) |
| RMG `bridge_status` fails | GUI closed or no ROM | Open RMG, load ROM, check port |
| stdio works in terminal, not in IDE | Different `python`/`uv` on PATH | Use full path in `command` |
| Only one server needed | User doing splat-only | Install **ghidra** only; skip guest runtime MCP |

---

## Agent rules

1. **Discover client** before emitting config — do not assume Cursor.
2. **Use absolute paths** — never `~/` without resolving on the user's OS.
3. **N64LoaderWV before GhidraMCP** — correct MIPS program is prerequisite.
4. **Ghidra default, guest runtime optional** — do not require Mupen64MCP or RMG for matching decomp or first recomp triage.
5. **One guest runtime** — prefer Mupen64MCP when the user has cloned/built it; otherwise RMG if available.
6. **Record working config** in `N64_PROJECT_STATE.md` + optional `AGENTS.md` for the team.

Evidence protocols: `04-ghidra-mcp.md` (static), `17-mupen64mcp-playbook.md` or `14-rmg-mcp-playbook.md` (guest runtime).
