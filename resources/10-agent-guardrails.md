# Agent Guardrails — N64 Decomp & Recomp

Load this for **any crash, build error, repeated failure**, or when you catch yourself guessing.

## §1 Mistake Taxonomy

| Pattern | Symptom | Correct layer |
|---------|---------|---------------|
| **Symptom patch** | Editing `RecompiledFuncs/` or `asm/*.s` first | Fix yaml, TOML, symbols, overlays, runtime |
| **Address fantasy** | `0x80000000` subtract everywhere | Segment/overlay-specific ROM↔VRAM↔RDRAM map |
| **Decompiler truth** | Ghidra C output = final boundary | Raw MIPS, delay slots, jump-table proof |
| **Codegen blame** | "N64Recomp is wrong" when entrypoint found | Host runtime, overlay registration, `jalr` lookup |
| **Tool invention** | Made-up TOML keys, runtime APIs, symbol names | User artifact + upstream README/source |
| **Phase bleed** | splat yaml fix during recomp crash | Phase-correct triage (see `13-decisional-brain.md`) |

## §2 Fix Taxonomy — Four Fix Tools

1. **Splat yaml** — segments, `bss_size`, `.bss`, overlays, `symbol_addrs` → re-split
2. **Metadata / TOML** — `relocatable_sections_path`, symbols, patches, stubs → re-run N64Recomp
3. **Host runtime glue** — librecomp overlays, PI DMA, saves, RSP/VI callbacks → handwritten C++
4. **Evidence / inventory** — `docs/function_ledger.md`, GhidraMCP (static), optional Mupen64MCP/RMG (guest runtime), `readelf` → then promote to yaml/TOML

**Never** use hand-edits to generated `asm/` or `RecompiledFuncs/` as the primary tool.

### Evidence pairing (general analysis & troubleshooting)

When the question is *what does the ROM actually do at this address?* use both layers when available:

| Layer | Tool | Answers |
|-------|------|---------|
| **Static** | GhidraMCP + N64LoaderWV (`04-ghidra-mcp.md`) | Boundaries, xrefs, overlay tables, jump tables, MMIO sites |
| **Guest runtime** | Mupen64MCP (`17-mupen64mcp-playbook.md`) or RMG (`14-rmg-mcp-playbook.md`) | RDRAM at PC, breakpoints hit, PI DMA, `n64_detect_os`, boot flow |

Ghidra **names** the hypothesis; guest MCP **proves** it in emulation. Neither replaces yaml/TOML fixes. CDB (`16-cdb-debug-playbook.md`) is for **host** recomp `.exe` — not guest RDRAM.

## §3 Circuit Breaker (3-Strike Rule)

Same crash or same failed assertion **3 times** without new evidence:

1. **STOP** patching.
2. Load the relevant resource (`db-n64-index.md` → topic file).
3. Update `N64_PROJECT_STATE.md` with what was tried.
4. Gather **new** evidence before strike 4 — do not repeat the same fix class:
   - **Static (always try first):** GhidraMCP raw MIPS / xrefs / overlay table (`04-ghidra-mcp.md`)
   - **Guest runtime (if user has Mupen64MCP or RMG connected):** one narrow call — `n64_status`, `n64_read_memory` at hypothesized VRAM, exec breakpoint + hit proof, or `n64_detect_os` for OS/boot questions (`17-mupen64mcp-playbook.md`)
   - **Host recomp EXE (Track B, Windows):** read `tools/*cdb*.ps1`, archive `.cdb.txt` (`16-cdb-debug-playbook.md`)
   - Otherwise ask for the **narrow artifact** in `09-n64recomp-pipeline.md` § Artifacts to Request

On strike 3 you **must** have **new** evidence — raw MIPS from Ghidra, guest registers/memory from Mupen64MCP/RMG, or host trace from CDB — matched to the failing layer. Decompiler-only or log-less guesses do not count.

**Do not require** Mupen64MCP if the user has not built it; do not skip Ghidra because guest MCP is connected.

## §4 Root Cause Protocol

```text
1. Which phase? (splat / matching asm / libultra / C / N64Recomp / runtime)
2. Which subsystem? (see 12-n64-hardware-subsystems.md)
3. What address space? (ROM / VRAM / RDRAM / overlay / host)
4. What proves the hypothesis? (hash, log line, disasm, readelf row)
5. Smallest fix at the correct layer
6. Verification command
7. Next expected failure
```

## §5 Red Flags — Stop and Re-read State

- Confident without reading build/recomp log output
- Mixing matching-decomp advice into a recomp port (or vice versa)
- Citing bundled docs without reading user's yaml/TOML
- 15+ tool calls without refreshing `N64_PROJECT_STATE.md`
- GhidraMCP connected but wrong program/arch loaded

## §6 Lawful Use

- Do not request or distribute copyrighted ROMs, SDK leaks, or redistributable game assets.
- Ask for hashes, logs, yaml/TOML snippets, `readelf` output, crash PCs.
