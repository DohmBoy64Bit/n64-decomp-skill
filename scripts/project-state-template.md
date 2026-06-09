# ⛔ QUICK RULES (mandatory re-read)

1. **Generated output:** NEVER hand-edit `asm/*.s` or `RecompiledFuncs/` as the primary fix — fix yaml, TOML, symbols, overlays, runtime.
2. **Addresses:** NEVER subtract `0x80000000` blindly — use segment/overlay mapping (`12-n64-hardware-subsystems.md`).
3. **Evidence:** NEVER promote Ghidra decompiler-only boundaries — raw MIPS + delay slots.
4. **Lawful use:** NEVER request or distribute ROMs or copyrighted assets — hashes and logs only.
5. **Phase:** NEVER mix splat fixes with recomp runtime patches in one undifferentiated change list.

---

# N64 Project — State
> Auto-maintained by agent. DO NOT DELETE. Read at session start; update after every major action.

## Boot Status
- [ ] Located skill `resources/` directory
- [ ] Loaded `11-operational-phases.md` (or confirmed resume phase)
- [ ] Loaded boot references for active track (matching: `02`+`03` / recomp: `02`+`09`)

## Project Info
- **Game / project**:
- **Track**: matching-decomp | static-recomp | both
- **ROM hash (SHA-256)**:
- **Byte order / region**:
- **Entrypoint (header)**:
- **RDRAM**: 4 MiB | 8 MiB (Expansion Pak) | unknown
- **Save type**: EEPROM | SRAM | FlashRAM | Controller Pak | none | unknown

## Workspace Paths
- **Decomp / game root**:
- **Skill install path** (if known):
- **baserom path** (not committed):
- **splat yaml**:
- **N64Recomp TOML** (if recomp):
- **Ghidra program** (version e.g. 12.0.4 + name + arch + N64LoaderWV version):
- **CDB wrappers** (paths under `tools/*cdb*.ps1`, if any):
- **Last CDB trace** (`.cdb.txt` path + HIT/BYPASS/ABORT):

## Current Phase
`PHASE_SETUP` — see `11-operational-phases.md`

## Build / Tooling
- **uv / splat**: 
- **Matching**: `configure.py` present? linker script?
- **N64Recomp build**: 
- **GhidraMCP**: bridge path / HTTP port / MCP server id `ghidra` / correct MIPS N64 program?
- **MCP host**: Cursor|Claude|VS Code|Codex|… / config file path (`15-mcp-client-setup.md`)
- **Mupen64MCP (optional)**: clone path / `n64-debug-daemon.exe` / core DLL / MCP id `n64-debug-mcp` / `n64_status` / ROM loaded?
- **RMG MCP (optional)**: `server.py` path / host:port / bridge_status / ROM loaded / symbols `.map`?

## Active Commands
```bash
# Record verbatim commands that work — do not reconstruct from memory
```

## Mapping Table
```text
Name        ROM Start   ROM End     VRAM Start  RAM Load   Notes
```

## Crashes & Triage
| Guest PC / context | Phase | Structural cause | Fix layer | Status |
|--------------------|-------|------------------|-----------|--------|
| | | | | |

## Function Ledger Status
- **Ledger path**: `docs/function_ledger.md`
- **Last promoted to symbol_addrs**:

## Learned Patterns
> Session close: write patterns (`X causes Y, fix with Z`), not raw event logs.

- 

## Known Issues / TODOs
- [ ] 
