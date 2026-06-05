# RMG MCP Debug Bridge (Optional)

**Optional** runtime debugging — use when static analysis (GhidraMCP, splat, logs) is not enough and you need **live** RDRAM, VR4300 registers, breakpoints, or original-vs-recomp trace comparison.

**Not required** for matching decomp, splat setup, or first N64Recomp bring-up. Prefer `04-ghidra-mcp.md` (with [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV) ROM load) and build/log evidence first.

**MCP client wiring:** `15-mcp-client-setup.md` — same autoconfig doc as Ghidra; server id `rmg-n64-debugger`.

Upstream fork: [thebardockgames/RMG](https://github.com/thebardockgames/RMG) (Mupen64Plus-based **RMG** + Qt6 WebSocket bridge + Python MCP `server.py`). Based on [Rosalie241/RMG](https://github.com/Rosalie241/RMG).

---

## When to load this file

| Situation | Use RMG MCP? |
|-----------|----------------|
| Jump table / boundary proof in ROM | **No** — GhidraMCP (`04-ghidra-mcp.md`) |
| Overlay `jalr` crash, guest PC known | **Maybe** — after TOML/runtime checklist (`09-n64recomp-pipeline.md`) |
| Verify RDRAM value at runtime | **Yes** |
| A/B: retail ROM vs native recomp build | **Yes** — `capture_instruction_trace` + `compare_trace_files` |
| User has no RMG MCP build | **No** — fall back to logs, `readelf`, emulator manual |

Record status in `N64_PROJECT_STATE.md` → **RMG MCP Status** (connected / ROM loaded / symbols loaded).

---

## Architecture

```text
MCP client (Cursor, Claude Desktop, VS Code)
    → python server.py  (stdio MCP, FastMCP)
    → WebSocket 127.0.0.1:8765 (default)
    → RMG.exe (MCP_BRIDGE=ON) + mupen64plus debugger
    → Running N64 ROM (user-owned)
```

Symbols: load `.map` from matching decomp / linker (`load_symbols`) — not a substitute for `docs/function_ledger.md`.

---

## Prerequisites (user provides)

- **Windows 10/11** — build docs target MSYS2 `ucrt64` (see fork README)
- **Python 3.12+** — `pip install mcp websockets`
- **RMG built with** `-DMCP_BRIDGE=ON`
- **Lawful ROM** — user loads in RMG; agent must not request or distribute ROMs

Environment (defaults from fork README):

| Variable | Default |
|----------|---------|
| `RMG_MCP_HOST` | `127.0.0.1` |
| `RMG_MCP_PORT` | `8765` |
| `RMG_MCP_TIMEOUT_SECONDS` | `2.0` |

---

## Setup checklist

```text
[ ] RMG MCP fork built (MCP_BRIDGE=ON) and RMG.exe launches
[ ] pip install mcp websockets (for server.py)
[ ] ROM loaded in RMG (correct region/revision)
[ ] python server.py running (or MCP client spawns it via stdio)
[ ] bridge_status succeeds
[ ] MCP client entry — see 15-mcp-client-setup.md (server id rmg-n64-debugger)
[ ] Optional: load_symbols(path/to/game.map) for symbol-aware tools
```

---

## MCP client configuration

**Canonical:** `15-mcp-client-setup.md` §4.3 and `examples/mcp-servers.template.json`.

Do not assume Cursor — discover the user's MCP host and merge the `rmg-n64-debugger` block with the same absolute `RMG_MCP_SERVER` path and `RMG_MCP_HOST` / `RMG_MCP_PORT` env vars.

RMG GUI must stay open with the ROM loaded while the bridge is used.

---

## Tool catalog (from fork README)

Verify names against your checkout's `server.py` if the fork updates.

**Memory / CPU**

- `read_rdram`, `write_rdram`
- `read_symbol`, `write_symbol`
- `read_mips_register`, `write_mips_register`
- `debugger_state`, `cpu_snapshot`
- `translate_address`
- `resolve_symbol_name`, `resolve_symbol`, `lookup_symbol`
- `disassemble_rdram`, `disassemble_symbol`

**Execution control**

- `pause_emulation`, `resume_emulation`
- `reset_emulation`, `restart_rom`
- `step_instruction`, `step_over`, `step_out`
- `run_until_address`, `run_until_symbol`

**Breakpoints / symbols**

- `add_breakpoint`, `add_watchpoint`
- `add_symbol_breakpoint`, `add_symbol_watchpoint`
- `remove_breakpoint`, `remove_symbol_breakpoint`, `remove_symbol_watchpoint`
- `list_breakpoints`, `clear_breakpoints`
- `load_symbols`, `clear_symbols`, `symbol_status`

**Traces / health**

- `get_debug_events`
- `capture_instruction_trace`
- `compare_trace_files`
- `bridge_status`

---

## Agent workflow recipes

### 1. Confirm bridge before debugging

```text
bridge_status
```

If failing: RMG not running, ROM not loaded, `server.py` not connected, or wrong port.

### 2. Inspect guest state at crash PC

```text
pause_emulation
cpu_snapshot
read_mips_register  # per tool schema in server.py
disassemble_rdram     # at guest PC from crash log
```

Map guest PC through `12-n64-hardware-subsystems.md` (segment/overlay), not host pointers.

### 3. Watchpoint on known global (symbols loaded)

```text
load_symbols("path/to/game.map")
add_symbol_watchpoint("D_8010ADA0", access="write", size_bytes=4)
resume_emulation()
get_debug_events(limit=16, event_types="debugger.watchpoint_hit")
```

### 4. Original vs recomp trace (advanced)

Capture on retail in RMG, compare against recomp run per fork docs:

```text
capture_instruction_trace(duration_ms=2000, output_path="trace_original.jsonl")
compare_trace_files(trace_a_path="trace_original.jsonl", trace_b_path="trace_recompiled.jsonl")
```

Use for **evidence**, not as a substitute for fixing yaml/TOML/runtime layers (`10-agent-guardrails.md`).

---

## Relationship to other skill resources

| Resource | Role |
|----------|------|
| `04-ghidra-mcp.md` | Static boundaries, xrefs, jump tables — **default** |
| `09-n64recomp-pipeline.md` | Overlay/runtime fixes before emulator patching |
| `12-n64-hardware-subsystems.md` | Address spaces (RDRAM vs VRAM vs host) |
| `14-rmg-mcp-playbook.md` | **Optional** live CPU/RDRAM when static path stalls |

**NEVER ask the user to read RMG for you** if RMG MCP is connected — use tools. **NEVER** treat emulator memory writes as the primary fix for metadata bugs.

---

## Limitations (honest)

- Fork maturity and platform support follow [thebardockgames/RMG](https://github.com/thebardockgames/RMG) — not bundled with this skill.
- No substitute for N64ModernRuntime/librecomp overlay registration on static recomp ports.
- RSP microcode / RDP display lists are not fully modeled through this bridge; CPU/RDRAM focus.
- User must own the ROM and run the emulator locally.

---

## Full build (Windows / MSYS2 ucrt64)

From [thebardockgames/RMG](https://github.com/thebardockgames/RMG) README — one-time user setup:

```bash
# Inside MSYS2 UCRT64 shell — install deps per fork README (Qt6, cmake, ninja, etc.)
git clone https://github.com/thebardockgames/RMG.git
cd RMG

cmake -S . -B build-mcp-ucrt -G "MSYS Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DMCP_BRIDGE=ON \
  -DPORTABLE_INSTALL=ON \
  -DNETPLAY=OFF -DVRU=OFF -DUSE_ANGRYLION=OFF -DUPDATER=OFF

cmake --build build-mcp-ucrt --config Release -j 8
cmake --install build-mcp-ucrt
```

**Python MCP server:**

```bash
pip install mcp websockets
cd /path/to/RMG
python server.py
# Or let MCP host spawn server.py — 15-mcp-client-setup.md
```

**Bring-up order:**

```text
1. Launch RMG.exe from install dir
2. File → Open ROM (user-owned lawful copy)
3. Start server.py (manual or via MCP stdio spawn)
4. Wire MCP client (15-mcp-client-setup.md)
5. bridge_status → load_symbols(optional) → debug tools
```

Record RMG install path, `server.py` path, and WebSocket host:port in `N64_PROJECT_STATE.md`.
