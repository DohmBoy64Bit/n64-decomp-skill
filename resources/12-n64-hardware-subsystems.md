# N64 Hardware & Address Discipline

Load when crashes touch DMA, overlays, RSP, saves, cache, or "wrong address" bugs.

## Phase 0 — ROM Reconnaissance

Before split or recomp, record in `N64_PROJECT_STATE.md`:

- Filename, size, byte order (`.z64` / `.n64` / `.v64`)
- SHA-256 (or SHA-1); header entrypoint
- Likely main code VRAM base; 4 MiB vs 8 MiB RDRAM
- Save type: EEPROM, SRAM, FlashRAM, Controller Pak, none
- Compression, overlays, custom loaders, unusual boot

```bash
sha256sum baserom.z64
xxd -g 4 -l 0x40 baserom.z64
```

Wrong revision or byte order poisons splat, symbols, and N64Recomp.

**Optional runtime recon** (when [Mupen64MCP](https://github.com/DohmBoy64Bit/Mupen64MCP) is built and connected): `n64_detect_os` for libultra vs custom boot hints; exec breakpoint at header entrypoint; compare to Ghidra static map (`04-ghidra-mcp.md`). Runtime enriches Phase 0 — it does not replace hash/header checks or splat yaml.

## Address Spaces — Never Collapse

| Space | Examples |
|-------|----------|
| ROM / VROM offset | Cart file offsets |
| VRAM | Segment virtual addresses in code |
| RDRAM / RAM | Loaded addresses, BSS |
| Overlay virtual | Dynamic code windows |
| RSP IMEM / DMEM | Microcode, task buffers |
| RDP | Display lists, command buffers |
| Host | Runtime-translated pointers only |

```text
vram_delta = current_vram - segment_vram_start
rom_offset = segment_rom_start + vram_delta
rdram_offset = guest_address - rdram_base   # only when guest is RDRAM
```

Never blindly subtract `0x80000000`. For KSEG0/KSEG1, identify cached vs uncached vs MMIO. On host, **translate through runtime** — do not cast guest addresses.

## Mapping Table (Maintain as Evidence Appears)

```text
Name        ROM Start   ROM End     VROM Start  VRAM Start  RAM Load   Notes
main        0x001000    0x0ABCDE    0x000000    0x80200000  0x80200000 main code
overlay_01  0x0ABCDE    0x0F1234    0x000000    0x80300000  dynamic    relocatable
```

## Subsystem Checklist

| Area | Examples |
|------|----------|
| CPU / VR4300 / CP0 | exceptions, TLB, cache, count/compare |
| SP/RSP | IMEM, DMEM, task boot, microcode, completion |
| DP/RDP | display lists, framebuffer/depth |
| VI | retrace, presentation, frame pacing |
| AI | DMA audio |
| PI | cart DMA, save hardware |
| SI/PIF | controllers, accessories |
| MI | CPU↔RCP interrupt masks |
| RI/RDRAM | 4 MiB vs Expansion Pak 8 MiB |
| Save | EEPROM, SRAM, FlashRAM, Controller Pak |

Most recomp failures are **mapping/runtime**, not opcode translation: wrong ROM/VROM/VRAM, wrong DMA, missing cache ops, missing SP completion, bad VI timing, wrong save type, framebuffer in RDRAM treated as host image memory.

## Expansion Pak & Save

- Probe for 8 MiB usage vs 4 MiB-only assumptions
- Save access via libultra, custom PI/SI, or direct MMIO
- Model completion/polling if the original game depends on it

## Cache / DMA Hazards

Check expectations around: PI DMA into RDRAM, overlay load/relocation, RSP task reads, framebuffer/depth, audio buffers, streamed assets.

Common mistakes: wrong DMA endpoints, missing writeback/invalidate, stale RSP reads, overlay loaded but not registered for lookup, collapsed KSEG0/KSEG1.

## Reference Priority

1. User ROM hash, logs, disassembly, Ghidra exports, yaml/TOML, maps, runtime output
2. N64Recomp, N64ModernRuntime, librecomp, RT64 README/source
3. N64brew, n64.dev, VR4300, RSP, RDP, libultra docs
4. Other recomp projects as **structure only**
5. Emulator traces when docs disagree with artifacts

Separate: source says / artifact proves / inference / unknown.
