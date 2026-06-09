# Decisional Brain — Triage & Escalation

Load when stuck, circling, or answering crash/build questions.

## Debug Response Format (Mandatory)

```text
Phase:
Structural Cause:
Evidence:
Address Mapping:
Fix:
Commands or Patch:
Verification:
Next Failure to Expect:
```

Keep fixes **phase-correct** — do not mix splat yaml, N64Recomp TOML, generated output, and host runtime in one undifferentiated patch list.

## Five-Step Reasoning Loop

1. **Classify phase** — matching vs recomp; which operational phase (`11-operational-phases.md`)
2. **Classify subsystem** — CPU, PI DMA, overlay, RSP, save, etc. (`12-n64-hardware-subsystems.md`)
3. **Gather narrow evidence** — one GhidraMCP call, one `readelf` row, one log line — not broad decompile
4. **Hypothesis at correct layer** — yaml before asm; TOML/runtime before `RecompiledFuncs/`
5. **Verify with a command** — rebuild, re-split, re-run N64Recomp, or targeted runtime log

## Escalation Ladder

| Level | Action |
|-------|--------|
| 1 | User-provided log + skill resource for that phase |
| 2 | GhidraMCP raw MIPS / xrefs / overlay tables (`04-ghidra-mcp.md`) |
| 3 | `readelf -Ws`, splat yaml segment table, TOML overlay section |
| 4 | CDB on native recomp EXE + `.cdb.txt` trace (`16-cdb-debug-playbook.md`) if user has wrappers |
| 5 | Optional: Mupen64MCP or RMG MCP live **guest** state (`17-mupen64mcp-playbook.md`, `14-rmg-mcp-playbook.md`) if user has a build |
| 6 | Compare to Zelda64Recomp/Kirby64Recomp **structure** only |
| 7 | Ask user for specific artifact; update `N64_PROJECT_STATE.md` |

## Anti-Patterns

- Trusting Ghidra decompiler for final function boundaries
- Hand-editing splat-generated `asm/` for BSS or linker fixes
- Patching generated recomp C before overlay registration is proven
- Inventing symbol names or TOML keys not in upstream docs
- Requesting the ROM file instead of hash + snippet

## Symbol Confidence (Promotion Gate)

```text
Known       ELF symbol, clean map, confirmed call target
Likely      prologue/control-flow/XREF evidence
Tentative   Ghidra, n64sym, pattern matching only
Unknown     needs raw assembly, trace, or better mapping
```

Never feed **Tentative** into N64Recomp or `symbol_addrs` without delay-slot and overlay checks.

## When to Ask the User

Ask for (not ROM files):

- recomp TOML, N64Recomp console output
- splat YAML segment/overlay entries
- `readelf -Ws` for failing function/entrypoint
- crash log with guest PC/LR/registers
- context around failing `jal`, `jalr`, DMA, overlay load, RCP wait
- CDB `.cdb.txt` trace log path, wrapper script used, breakpoint hit/bypass result
- Ghidra export or GhidraMCP evidence for overlay dispatch table / boundary in question

## Recomp Templates (Structure Only)

Kirby64Recomp, Zelda64Recomp, Dinosaur Planet Recompiled — useful for CMake layout, RT64, launcher patterns.

Do **not** copy game-specific symbols, overlays, hooks, microcode, or asset paths.
