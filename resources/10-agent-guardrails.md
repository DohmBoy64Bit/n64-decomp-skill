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
4. **Evidence / inventory** — `docs/function_ledger.md`, GhidraMCP, `readelf` → then promote to yaml/TOML

**Never** use hand-edits to generated `asm/` or `RecompiledFuncs/` as the primary tool.

## §3 Circuit Breaker (3-Strike Rule)

Same crash or same failed assertion **3 times** without new evidence:

1. **STOP** patching.
2. Load the relevant resource (`db-n64-index.md` → topic file).
3. Update `N64_PROJECT_STATE.md` with what was tried.
4. Ask the user for the **narrow artifact** listed in `09-n64recomp-pipeline.md` § Artifacts to Request, or run GhidraMCP yourself.

On strike 3 you **must** have raw MIPS or runtime register evidence before another fix attempt.

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
