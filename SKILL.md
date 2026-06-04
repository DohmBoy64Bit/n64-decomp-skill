---
name: n64-decomp
description: |
  Nintendo 64 matching decompilation and N64Recomp static PC ports. Use whenever the user mentions splat, splat64, uv, baserom, matching ROM, configure_min, emit-configure, first asm build, bss_size, wrong BSS in asm, libultra, ultralib, m2c, decomp.me, custom runtime, direct MMIO, N64Recomp, N64ModernRuntime, RT64, relocatable overlays, jalr or indirect-call crashes, GhidraMCP, bethington/ghidra-mcp, symbol_addrs, VRAM or RDRAM mapping, RSP, RDP, PI DMA, cache writeback, function boundaries, or Zelda64Recomp-style recomp - even for casual asks like "split my ROM", "fix splat yaml", or "port crashes after boot". Covers splat setup, configure_min matching builds, libultra or no-libultra paths, Ghidra evidence, and phase-based triage. Not for Xbox or PC x86 recomp (xboxrecomp/pcrecomp), SNES or GameCube emulation-only help, RetroArch or Dolphin playability tweaks, or generic embedded MIPS with no N64 ROM context.
metadata:
  mcpmarket-version: 1.0.0
---
# N64 Decompilation

## When to Read Which Reference

Load bundled references only for the active phase — do not read everything up front.

| Phase / topic | Reference |
|---------------|-----------|
| Tool install, uv, Ghidra, N64Recomp clones | [references/environment-setup.md](references/environment-setup.md) |
| New splat project, yaml, split | [references/splat-setup.md](references/splat-setup.md) |
| First matching ROM build, BSS, symbols | [references/build-system.md](references/build-system.md), [references/configure_min.py](references/configure_min.py) |
| GhidraMCP install, MCP config, evidence | [references/ghidra-mcp.md](references/ghidra-mcp.md) |
| Function inventory before naming/recomp | [references/function-discovery.md](references/function-discovery.md) |
| Standard libultra block | [references/libultra.md](references/libultra.md) |
| No libultra / direct MMIO | [references/custom-runtime.md](references/custom-runtime.md) |
| decomp.me, asm→C | [references/compiler-and-c.md](references/compiler-and-c.md) |
| Native port, TOML, RT64, runtime | [references/n64recomp.md](references/n64recomp.md) |

**Matching decomp path:** environment → splat → **first asm match** → (Ghidra as needed) → function discovery → libultra *or* custom runtime → compiler → C.

### First matching build (assembly only)

After `uv run -m splat split <game>.yaml` produces `asm/`, use the bundled helper — do not jump to libultra, C, or complex configure examples yet:

```bash
python references/configure_min.py --status
python references/configure_min.py --emit-configure --game <game>
# Add splat/project linker script (<game>.ld), then:
python configure.py --clean && python configure.py --build
```

Details and BSS fixes: [references/build-system.md](references/build-system.md) — wrong BSS → fix `bss_size` / `.bss` in yaml from entry asm evidence, never patch `asm/*.s`. Compiler IDO/GCC matching comes **after** the ROM bytes match.

**Static recomp path:** splat/metadata clean first → [n64recomp.md](references/n64recomp.md) → runtime/renderer glue.

For IDO compiler build integration after compiler is identified, also use the `n64-decomp-ido` skill.

## Core Rules

These apply across splat, decompilation, N64Recomp, runtime, and host integration:

- Do not invent N64Recomp flags, TOML keys, runtime APIs, macros, symbol names, compiler behavior, or function boundaries.
- Do not treat guest VRAM/RDRAM addresses as host pointers without an explicit translation layer.
- Do not hand-edit generated output as the primary fix. Fix source metadata, TOML, symbols, overlays, stubs, patches, or runtime glue first.
- Do not provide or request copyrighted ROMs, game assets, BIOS files, SDK files, leaked headers, or redistributable copyrighted game data.
- Prefer user-provided evidence: ROM hash, logs, raw MIPS/RSP disassembly, Ghidra exports, generated C/C++, YAML/TOML, linker maps, symbol maps, runtime output.
- Every patch, hook, shim, or config edit should state why it is required, which address space it affects, and how to verify it.
- Keep generated code, handwritten runtime glue, hooks, patches, assets, and documentation in separate areas.
- If evidence is insufficient, state what is unknown and ask for the narrow artifact that would prove it.

## Reference Priority

1. User ROM hash, logs, disassembly, Ghidra exports, generated code, YAML/TOML, maps, runtime output.
2. N64Recomp, N64ModernRuntime, ultramodern, librecomp, RT64 source/README behavior.
3. N64brew, n64.dev, VR4300, RSP, RDP, libultra documentation.
4. Existing recomp projects as **structure** references only — not proof for the current ROM.
5. Emulator traces or hardware tests when docs and generated output disagree.

Separate: what the source says, what the user's artifact proves, what is inference, what still needs verification.

## Address-Space Discipline

Always distinguish:

- ROM / VROM offset
- VRAM, RDRAM/RAM, segment, overlay virtual address
- RSP IMEM/DMEM, RDP command buffer
- Generated C function pointer vs runtime host pointer
- DMA source and destination

Never blindly subtract `0x80000000`. Use the mapping for the specific segment or overlay.

```text
vram_delta = current_vram - segment_vram_start
rom_offset = segment_rom_start + vram_delta
rdram_offset = guest_address - rdram_base   # only when guest_address is RDRAM
```

For KSEG0/KSEG1, identify cached vs uncached RDRAM, MMIO, or host-mapped pointers. On the host, translate through the runtime — do not cast guest addresses.

## Hardware Subsystem Checklist

Classify the subsystem before proposing a fix:

| Area | Examples |
|------|----------|
| CPU / VR4300 / CP0 | exceptions, TLB, cache, count/compare, interrupts |
| SP/RSP | IMEM, DMEM, task boot, microcode, completion |
| DP/RDP | display lists, command buffers, framebuffer/depth |
| VI | retrace, presentation, frame pacing |
| AI | DMA audio, sample timing |
| PI | cart DMA, save hardware |
| SI/PIF | controllers, accessories, Controller Pak, Rumble |
| MI | CPU↔RCP interrupt masks |
| RI/RDRAM | 4 MiB vs Expansion Pak 8 MiB |
| Save | EEPROM, SRAM, FlashRAM, Controller Pak, none |

Most recomp failures are mapping/runtime problems: wrong ROM/VROM/VRAM, wrong DMA, missing cache ops, missing SP completion, bad VI timing, wrong save type, or treating RDRAM framebuffer as host image memory.

## Phase 0: ROM Reconnaissance

Before splitting or recompiling, record:

- Filename, size, byte order (`.z64` / `.n64` / `.v64`)
- Region/revision if known; SHA-1 or SHA-256
- Header entrypoint; likely main code VRAM base
- 4 MiB vs 8 MiB RDRAM; save type if known
- Evidence for compression, overlays, custom loaders, unusual boot code

```bash
sha256sum baserom.z64
xxd -g 4 -l 0x40 baserom.z64
```

Do not continue with guessed metadata — wrong revision or byte order poisons splat, symbols, and N64Recomp.

### Mapping Table

Maintain as evidence appears:

```text
Name        ROM Start   ROM End     VROM Start  VRAM Start  RAM Load   Notes
main        0x001000    0x0ABCDE    0x000000    0x80200000  0x80200000 main code
overlay_01  0x0ABCDE    0x0F1234    0x000000    0x80300000  dynamic    relocatable
```

Do not assume `0x80000000` is the project base, that entrypoint equals main segment start, that overlays are static, or that every branch target is a function.

## Expansion Pak and Save-Type

During recon and runtime bring-up:

- 4 MiB vs 8 MiB probes and high-RDRAM use
- Save type, address ranges, access path (libultra vs custom PI/SI vs direct MMIO)
- Whether completion/polling/interrupts must be modeled on host

Wrong RDRAM size or save backend can crash in ways that look unrelated to boot or input.

## Cache / DMA Hazards

Check cache expectations around PI DMA, overlay load, RSP tasks, framebuffer/depth, audio buffers, streamed assets.

Common mistakes: wrong DMA endpoints, missing writeback/invalidate, stale RSP reads, unloaded overlay not registered, collapsed KSEG0/KSEG1 behavior.

## Project Documentation (`AGENTS.md`)

Create or update `AGENTS.md` once commands and conventions are repeatable. Document only verified facts:

- Purpose and lawful-use boundary
- ROM hash, byte order, region, revision
- Generated vs handwritten folder layout
- Build, split, analysis, recomp, run, verify commands
- Tool versions / pinned commits
- GhidraMCP setup if used (version, path, bridge, MCP client config)
- Address conventions (ROM, VROM, VRAM, RDRAM, overlays, RSP DMEM, host)
- Overlay, hook, patch, renderer, audio, input, save conventions
- Known failure triage and next expected failures

If evidence is missing, write a TODO naming the exact artifact needed.

## Recomp Project Templates

Kirby64Recomp, Zelda64Recomp-style projects, Dinosaur Planet Recompiled, etc. are useful for CMake layout, N64ModernRuntime integration, generated source organization, RT64, launcher patterns.

Do not copy game-specific symbols, overlays, hooks, save behavior, scheduler, renderer, microcode, or asset paths. Templates are structure references, not proof for the current ROM.

## Ghidra / GhidraMCP (Summary)

When boundaries, XREFs, MMIO, overlays, or jump targets are unclear, use GhidraMCP or offline fallbacks. Full setup and evidence protocol: [references/ghidra-mcp.md](references/ghidra-mcp.md).

Prefer narrow evidence requests over broad decompilation. Raw MIPS and control flow beat decompiler output for final decisions.

## Function Discovery (Summary)

Before large-scale naming, N64Recomp metadata, or subsystem rewrites, run a classification pass. Full inventory fields and report format: [references/function-discovery.md](references/function-discovery.md).

Preserve existing project state unless evidence proves it wrong. Use conservative `*_candidate` names until multiple sources agree.

## Symbol Confidence

```text
Known       ELF symbol, clean map, confirmed call target
Likely      prologue/control-flow/XREF evidence
Tentative   Ghidra, n64sym, pattern matching only
Unknown     needs raw assembly, trace, or better mapping
```

Never feed tentative boundaries into N64Recomp without raw disassembly, branch targets, delay slots, data boundaries, and segment/overlay checks.

## Debug Response Format

For logs, crashes, TOML, YAML, generated C, asm, maps, or runtime failures, use:

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

Keep fixes phase-correct — do not mix splat config, N64Recomp TOML, generated output, runtime callbacks, and host build unless evidence crosses boundaries.

## Quick Command Index

```bash
# ROM
sha256sum baserom.z64

# Splat (see splat-setup.md)
uv run -m splat create_config baserom.n64
uv run -m splat split <game>.yaml

# First matching ROM (asm only — see build-system.md)
python references/configure_min.py --emit-configure --game <game>
python configure.py --clean && python configure.py --build

# m2c (libultra / identification)
uv run m2c asm/<file>.s

# ELF symbols before N64Recomp
readelf -Ws build/<game>.elf | rg "FUNC|OBJECT|entry|_start"

# N64Recomp (see n64recomp.md)
external/N64Recomp/build/N64Recomp <game>.recomp.toml

# GhidraMCP health
curl http://127.0.0.1:8089/check_connection
```

Do not ask for ROM files or copyrighted assets. Ask for hashes, logs, TOML/YAML snippets, `readelf` output, and crash PCs instead.
