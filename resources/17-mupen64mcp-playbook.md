# Mupen64MCP — Guest Runtime Debug (Optional)

**Optional** live N64 ROM debugging via the Model Context Protocol — use when static analysis (GhidraMCP, splat, logs) is not enough and you need **guest** RDRAM, GPRs, breakpoints, PI DMA traces, display-list decode, or OS detection in a running ROM.

**Not required** for matching decomp, splat setup, or first N64Recomp bring-up. Prefer `04-ghidra-mcp.md` (with [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV)) and build/log evidence first.

**Host native EXE on Windows:** If the project uses **CDB** + PowerShell wrappers (`tools/*cdb*.ps1`) and `.cdb.txt` traces, use `16-cdb-debug-playbook.md` for breakpoints on the **recompiled executable** — Mupen64MCP answers **guest** RDRAM in Mupen64Plus emulation, not MSVC host stacks.

**MCP client wiring:** `15-mcp-client-setup.md` — server id `n64-debug-mcp`.

Upstream: [DohmBoy64Bit/Mupen64MCP](https://github.com/DohmBoy64Bit/Mupen64MCP) (Python FastMCP + native `n64-debug-daemon` + Mupen64Plus core built with `DEBUGGER`).

**Alternative runtime MCP:** [thebardockgames/RMG](https://github.com/thebardockgames/RMG) WebSocket bridge — `14-rmg-mcp-playbook.md`, server id `rmg-n64-debugger`. Use whichever the user has built; do not require both.

---

## When to load this file

| Situation | Use Mupen64MCP? |
|-----------|-----------------|
| Jump table / boundary proof in ROM | **No** — GhidraMCP (`04-ghidra-mcp.md`) |
| Overlay `jalr` crash, guest PC known | **Maybe** — after TOML/runtime checklist (`09-n64recomp-pipeline.md`) |
| Verify RDRAM value at runtime | **Yes** |
| PI DMA / overlay load routine proof in emulation | **Yes** |
| OS type detection (libultra vs custom) at runtime | **Yes** — `n64_detect_os` |
| Display-list / RSP task inspection | **Yes** (interpreter mode; dummy gfx → zero framebuffer pixels) |
| User has no Mupen64MCP build | **No** — fall back to Ghidra, logs, RMG if available, or manual emu |

Record status in `N64_PROJECT_STATE.md` → **Mupen64MCP Status** (daemon running / ROM loaded / MCP connected).

---

## Architecture

```text
MCP client (Cursor, Claude Desktop, VS Code)
    → n64-debug-mcp  (Python FastMCP, stdio)
    → TCP 127.0.0.1:9876  (JSON-RPC, one connection per request)
    → n64-debug-daemon.exe  (loads mupen64plus.dll dynamically)
    → Mupen64Plus core (DEBUGGER, Pure Interpreter R4300Emulator=0)
    → Running N64 ROM (user-owned)
```

**Key design (from upstream README):**
- Two-layer: Python MCP server + native C++ daemon — no emulator logic in the MCP layer
- Interpreter mode (`NO_ASM=1` / `R4300Emulator=0`) for reliable debugger callbacks
- Read-only memory by default; writes require daemon `--allow-write-memory`
- Optional `mupen64plus-input-inject.dll` for `n64_set_controller`

---

## Prerequisites (user provides)

- **Windows** — MSYS2 **MINGW64** environment recommended (per upstream build docs)
- **CMake ≥ 3.16**, **gcc** (MSYS2) or MSVC
- **Python ≥ 3.11** with `uv` or `pip`
- **pkg-config**, **libopcodes**, **libbfd** (for Mupen64Plus core build)
- **Lawful ROM** — user path only; agent must not request or distribute ROMs

Default daemon port: **9876** (TCP).

---

## Clone (one-time)

```bash
git clone https://github.com/DohmBoy64Bit/Mupen64MCP.git
cd Mupen64MCP
```

Record clone path as `MUPEN64MCP_ROOT` in `N64_PROJECT_STATE.md`. Pin commit after a successful build.

**Examples in upstream repo:** `examples/cursor_mcp.json`, `examples/claude_desktop_config.json`.

---

## Build checklist

Run from MSYS2 MINGW64 shell unless your fork documents MSVC. Order matters.

```text
[ ] 1. Mupen64Plus core (DEBUGGER, interpreter)
[ ] 2. n64-debug-daemon.exe
[ ] 3. mupen64plus-input-inject.dll (optional, for controller injection)
[ ] 4. Python package n64-debug-mcp (uv sync or pip install -e .)
[ ] 5. MCP client entry n64-debug-mcp — 15-mcp-client-setup.md
[ ] 6. n64_status or n64_start_daemon succeeds with user ROM
```

### 1. Build Mupen64Plus core

```bash
cd build
cmake -G "MSYS Makefiles" .. -DCMAKE_BUILD_TYPE=Debug -DNO_ASM=1
make -j$(nproc)
```

Produces `build/mupen64plus/lib/mupen64plus.dll` with debugger API enabled.

### 2. Build native daemon

```bash
cd native/n64_debug_daemon
cmake -B build -DMUPEN64PLUS_DIR=../../build/mupen64plus
cmake --build build
```

Produces `native/n64_debug_daemon/build/n64-debug-daemon.exe`.

### 3. Build input inject plugin (optional)

Upstream `build.bat` builds daemon + input plugin together. Manual:

```bash
cd native/input_inject
cmake -B build -DMUPEN64PLUS_DIR=../../build/mupen64plus
cmake --build build
```

Output: `native/input_inject/build/mupen64plus-input-inject.dll`

### 4. Install Python MCP server

```bash
cd mcp/python
uv sync
# or: pip install -e .
```

Entry point: `n64-debug-mcp`.

---

## Bring-up order

### Option A — MCP tool starts daemon (preferred when wired)

1. Wire MCP client (`15-mcp-client-setup.md` §4.5) — server id `n64-debug-mcp`
2. From MCP: `n64_start_daemon` with ROM path, core DLL, datadir, configdir (see tool schema in upstream `server.py`)
3. `n64_status` → ROM loaded, PC, paused state
4. Debug with breakpoints / memory / trace tools

### Option B — Manual daemon, then MCP

```powershell
native\n64_debug_daemon\build\n64-debug-daemon.exe ^
  --core build\mupen64plus\lib\mupen64plus.dll ^
  --rom roms\myrom.z64 ^
  --datadir build\mupen64plus\share ^
  --configdir build\mupen64plus\config ^
  --gfx dummy --audio dummy ^
  --input native\input_inject\build\mupen64plus-input-inject.dll ^
  --rsp dummy ^
  --port 9876
```

Then start MCP client (spawns `n64-debug-mcp` only — daemon already listening on 9876 per upstream client behavior; verify against your checkout's `daemon_client.py`).

**Input:** pass `--input` path to `mupen64plus-input-inject.dll` for `n64_set_controller`; omit or use `dummy` for read-only inspection.

---

## MCP client configuration

**Canonical:** `15-mcp-client-setup.md` §4.5 and `examples/mcp-servers.template.json`.

**Cursor / Claude (uv):**

```json
"n64-debug-mcp": {
  "command": "uv",
  "args": [
    "--directory",
    "<MUPEN64MCP_ROOT>/mcp/python",
    "run",
    "n64-debug-mcp"
  ]
}
```

Use absolute paths. On Windows, forward slashes in JSON are fine.

Do not assume Cursor — discover the user's MCP host first (`15-mcp-client-setup.md` Phase 0).

---

## Tool catalog (38 tools — verify against checkout)

Grouped from upstream README. Names may change — grep `server.py` if a tool 404s.

**Lifecycle:** `n64_start_daemon`, `n64_stop_daemon`

**Emulation:** `n64_status`, `n64_load_rom`, `n64_close_rom`, `n64_pause`, `n64_resume`, `n64_step_instruction`, `n64_step_frame`

**CPU:** `n64_get_pc`, `n64_get_registers`

**Memory:** `n64_read_memory`, `n64_write_memory` (writes off by default), `n64_dump_rdram`, `n64_translate_address`

**Breakpoints:** `n64_add_exec_breakpoint`, `n64_remove_breakpoint`, `n64_list_breakpoints`, `n64_wait_for_breakpoint`

**Tracing / analysis:** `n64_mark_game_state`, `n64_get_trace_events`, `n64_trace_rom_reads`, `n64_export_trace`, `n64_track_struct`, `n64_dl_decode`, `n64_trace_callchain`, `n64_trace_scheduler`, `n64_detect_os`

**Input:** `n64_set_controller` (requires input-inject plugin)

**Framebuffer:** `n64_read_framebuffer` (pixels zero with dummy gfx — needs real video plugin for rendered output)

**Assets / PI / RSP:** `n64_discover_assets`, `n64_export_manifest`, `n64_capture_pi_dma`, `n64_trace_pi_dma`, `n64_get_rsp_task`, `n64_trace_rsp_tasks`, `n64_read_sp_mem`, `n64_read_sp_regs`

**Optional UI:** `n64-viewer` — tkinter dashboard (upstream; game-specific panels vary)

---

## Agent workflow recipes

### 1. Confirm connectivity before debugging

```text
n64_status
```

If failing: daemon not running, wrong port, ROM not loaded, or MCP `uv` path wrong.

### 2. Inspect guest state at crash PC

```text
n64_pause
n64_get_registers
n64_get_pc
n64_read_memory  # at guest PC / global from Ghidra hypothesis
```

Map guest PC through `12-n64-hardware-subsystems.md` (segment/overlay), not host pointers.

### 3. Prove overlay load / `jalr` target in emulation

1. GhidraMCP: table + `jalr` site (`04-ghidra-mcp.md` § Overlay dispatch)
2. `n64_add_exec_breakpoint` at guest VRAM
3. `n64_resume` → `n64_wait_for_breakpoint`
4. `n64_get_registers` — confirm RA/A0–A3 at hit
5. Record in `docs/function_ledger.md` before yaml/TOML promotion

### 4. OS / boot flow discovery

```text
n64_detect_os
```

Use hints only — still require ledger + raw MIPS before `symbol_addrs` (`06-libultra.md`).

### 5. PI DMA / ROM read tracing

```text
n64_trace_rom_reads  # enable
n64_capture_pi_dma
n64_get_trace_events
```

Complements static overlay table work in Ghidra.

---

## Relationship to other skill resources

| Resource | Role |
|----------|------|
| `04-ghidra-mcp.md` | Static boundaries, xrefs, overlay tables — **default** |
| `16-cdb-debug-playbook.md` | Native recomp `.exe`, CDB, `.cdb.txt` hit/bypass (Windows) |
| `14-rmg-mcp-playbook.md` | **Alternative** guest runtime via RMG WebSocket bridge |
| `09-n64recomp-pipeline.md` | Overlay/runtime fixes before emulator patching |
| `12-n64-hardware-subsystems.md` | Address spaces (RDRAM vs VRAM vs host) |
| `17-mupen64mcp-playbook.md` | **This file** — Mupen64Plus MCP guest debug |

**NEVER ask the user to read the emulator for you** if Mupen64MCP is connected — use tools. **NEVER** treat emulator memory writes as the primary fix for metadata bugs (`10-agent-guardrails.md`).

---

## Limitations (honest)

- **Windows / MSYS2** focus in upstream build docs — verify other platforms in repo issues
- **Interpreter only** for reliable debugger callbacks — dynarec not supported for BP workflow
- **One TCP connection per JSON-RPC request** — `n64_wait_for_breakpoint` is client-side poll
- **Dummy gfx** → frame counter / framebuffer may be incomplete; CPU/RDRAM/PI focus still works
- **Input injection** requires `--input mupen64plus-input-inject.dll` at daemon start
- Not a substitute for N64ModernRuntime/librecomp overlay registration on static recomp ports
- User must own the ROM and run the stack locally

---

## Escalation ladder (guest runtime)

```text
1. GhidraMCP static (boundaries, overlay tables) — 04
2. Mupen64MCP or RMG MCP (this file or 14) — guest live proof
3. CDB on native EXE (16) — host runtime proof after recomp
```

Pick **one** guest runtime MCP if the user has only one built. Ghidra remains mandatory for static work.
