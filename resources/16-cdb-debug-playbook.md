# CDB Debug Playbook — Native Recomp Runtime (Windows)

**Primary dynamic analysis** for **Track B host executables** — the native `.exe` built from N64Recomp output + librecomp/RT64, not the original MIPS guest in isolation.

Use when static evidence (GhidraMCP, splat, logs) is not enough to prove **host-side** behavior: which recompiled function ran, whether a stub was bypassed, or why the port aborts (e.g. `std::thread::~thread` during teardown, bad indirect call glue, overlay lookup returning null).

**Not** a substitute for:
- **Ghidra + N64LoaderWV** — guest ROM/static boundaries (`04-ghidra-mcp.md`)
- **Mupen64MCP / RMG MCP** — live **guest** RDRAM/registers in emulation (`17-mupen64mcp-playbook.md`, `14-rmg-mcp-playbook.md`)

**MCP:** CDB is driven via **PowerShell wrapper scripts** in the user's project (typical `tools/run_*_cdb.ps1`), not via MCP. The agent runs or extends those scripts; it does not invent CDB command lines without reading an existing wrapper.

---

## When to Load This File

| Signal | Likely need CDB |
|--------|-----------------|
| Crash in native recomp `.exe` with host stack (MSVC, `std::`, SEH) | Yes |
| Need proof a **host** function was hit or **bypassed** after codegen | Yes |
| Overlay `jalr` wrong at **guest** PC only | Try Mupen64MCP/RMG or Ghidra first; CDB if debugging translated lookup in host code |
| Matching decomp asm-only phase | No — use matching build + Ghidra |
| Splat yaml / BSS wrong | No — fix yaml |

---

## Tooling

```text
cdb.exe          — Microsoft Console Debugger (Windows SDK / Debugging Tools for Windows)
PowerShell       — wrapper scripts that launch cdb with -c commands, log redirects
Project tools/   — user-maintained scripts, e.g. tools/run_<game>_retail_cdb.ps1, tools/run_<game>_layer_b_cdb.ps1
Trace logs       — *.cdb.txt (or project convention) capturing breakpoints, trace, !analyze
```

Record in `N64_PROJECT_STATE.md`:
- Path to working `cdb.exe` (or rely on wrapper)
- Wrapper script paths that work for this project
- Last trace log path and one-line result (hit / bypass / abort)

---

## Workflow (Agent)

### 1. Discover project wrappers

Inspect game/recomp root for `tools/*cdb*.ps1` (names vary by project — e.g. `run_b9_retail_cdb.ps1`, `run_b9_layer_b_cdb.ps1`). **Read the script** before changing breakpoints or flags; wrappers encode executable path, working directory, and symbol-friendly build (PDB).

Do not assume script names — list `tools/` once and record paths in state.

### 2. Static hypothesis first

Before CDB, have a **named host or guest target** from:
- Crash log / faulting module + offset (map to recomp symbol via PDB or map file)
- GhidraMCP overlay dispatch / function boundary (`04-ghidra-mcp.md`)
- N64Recomp TOML + `readelf -Ws` on ELF if symbols exist

CDB proves runtime; Ghidra names the target.

### 3. Set breakpoints and trace

Typical wrapper responsibilities (project-specific):

```powershell
# Pattern only — copy from user's tools/run_*_cdb.ps1, do not hand-wave paths
# - Launch: cdb.exe -o -G -c "<initial commands>" -c "g" .\build\GameRecompiled.exe
# - Initial commands: .sympath, bp module!symbol, bp address, sxe av, logopen trace.cdb.txt
```

Agent tasks:
- Add or adjust `bp` / `bm` / `sxe` only after reading the wrapper
- Prefer **symbol breakpoints** when PDB matches the built EXE
- Use **layered scripts** (e.g. retail vs layer_b) when the project splits bring-up stages — match the script to current phase (`11-operational-phases.md` B2–B3)

### 4. Generate and archive `.cdb.txt` trace logs

Wrappers should redirect CDB output to a trace file (project convention `*.cdb.txt`):

```text
logs/traces/2026-06-05_overlay_jalr_b9_retail.cdb.txt
```

**Evidence bar:** A trace log must show at least one of:
- Breakpoint hit with call stack (proves function entered)
- Explicit "breakpoint not hit" / run completed without stop (proves bypass — only valid if run path was correct)
- `!analyze -v` or fault summary for aborts (e.g. `std::thread::~thread`)

Update `N64_PROJECT_STATE.md` → Crashes & Triage with log path and conclusion.

### 5. Close the loop

```text
Hypothesis (from Ghidra/TOML) → CDB trace → hit/bypass/abort proof → fix at correct layer
```

| CDB result | Fix layer |
|------------|-----------|
| Guest logic never reached on host | Runtime registration, overlay table, TOML stubs |
| Wrong function at BP | Symbol/TOML boundary or codegen input |
| Host CRT/thread crash | Host glue, static init order, threading — not splat yaml |
| Bypass proved (intentional stub) | Document in ledger; adjust TOML `ignored` / stubs if correct |

Never patch `RecompiledFuncs/` as the first fix — same rule as `10-agent-guardrails.md`.

---

## Trace Log Evidence Template

When attaching or summarizing a `.cdb.txt` for triage (`13-decisional-brain.md`):

```text
Trace log:
Wrapper script:
Target EXE + PDB/build id:
Breakpoint(s) set:
Result: HIT | BYPASS | ABORT (fault)
Key stack (top 5 frames):
Guest-related symbol (if any):
Conclusion:
Next CDB run (if any):
```

---

## Recipes

### Prove overlay dispatch target runs on host

1. GhidraMCP: identify overlay table / `jalr` site in ROM (`04-ghidra-mcp.md` § Overlay dispatch).
2. Map to recomp symbol name from map/PDB.
3. Wrapper: `bp GameRecompiled!overlay_load_or_dispatch` (example — use real symbol).
4. Run; log to `*.cdb.txt`. Hit → runtime path OK; bypass → lookup/registration bug.

### Diagnose `std::thread::~thread` or similar host abort

1. Capture fault from log; note module + RVA.
2. CDB: `sxe av` or `bp` on last known good frame from `!analyze -v`.
3. Compare with static init / thread spawn in **host** project sources (not generated bulk).
4. Record whether crash is before or after first guest frame.

### A/B: recomp vs reference behavior

If the project maintains two wrappers (e.g. retail vs experimental layer):
- Same breakpoint set, two scripts, two `.cdb.txt` files
- Diff: hit count, stack depth, fault presence
- Do not claim parity without both logs

---

## Escalation Relative to Other Tools

```text
1. Build/log output + yaml/TOML
2. GhidraMCP static (boundaries, overlay tables)
3. CDB on native EXE (this file) — host runtime proof
4. Mupen64MCP or RMG MCP (optional) — guest live state
```

Load `17-mupen64mcp-playbook.md` or `14-rmg-mcp-playbook.md` when the question is **guest** PC in RDRAM, not host virtual address.

---

## Anti-Patterns

- Running CDB without a PDB/symbol-matched build
- Editing generated recomp C because CDB stopped somewhere unexpected — fix registration/TOML first
- Treating CDB guest-VRAM breakpoints in host process (addresses are **host** unless using a bridge that maps guest PC — verify in wrapper)
- Skipping archived `.cdb.txt` when claiming "function X is never called"
