# N64 Function Discovery and Classification

Read this before large-scale symbol naming, N64Recomp metadata, runtime patching, handwritten C conversion, or subsystem rewrites.

Do not restart an in-progress project. Preserve existing splat config, symbols, overlays, and notes unless evidence proves them wrong.

## Boundary Evidence Priority

```text
1. Matching ELF symbols, map files, debug symbols (version-matched, lawful)
2. splat/spimdisasm/rabbitizer boundaries confirmed by ROM/VROM/VRAM mapping
3. Ghidra/GhidraMCP with correct arch, endianness, segment base
4. Entry, boot/init, thread entrypoints, scheduler callbacks
5. Direct jal/bal/branch-and-link targets in executable ranges
6. jalr/jr $t9, vtables, function-pointer tables
7. Switch/jump-table targets
8. Overlay loaders, relocations, dynamic code ranges
9. libultra signatures, hardware register patterns
10. Emulator traces, N64Recomp logs, crash PCs
11. Manual recovery only when above sources fail
```

Verify delay slots, tail calls, inline data, jump-table data, overlay boundaries, alignment padding, and code adjacent to RSP/RDP/audio data.

## Classification Categories

```text
boot_entry_startup
libultra_runtime
custom_runtime
scheduler_threading
interrupt_exception_timer
pi_dma_rom_loader
overlay_loader_relocator
asset_loader
resource_decompression
rsp_task_builder
rdp_display_list_producer
graphics_scene_renderer
audio_task_builder
audio_sequence_or_sfx
vi_framebuffer_present
si_pif_controller_input
save_eeprom_sram_flash_controllerpak
memory_allocator
math_matrix_vector
ui_menu_frontend
game_state_machine
entity_actor_logic
physics_collision
camera
script_event_mission_logic
recomp_runtime_boundary
hardware_mmio_boundary
unknown_internal
```

Categories are evidence labels, not permanent names.

## Function Inventory (`docs/function_ledger.md`)

Cross-link to `docs/address_ledger.md`, `docs/runtime_boundaries.md`, `docs/overlay_ledger.md`, and splat/N64Recomp config.

```text
Function:
VRAM start / end / size:
ROM/VROM range:
Segment / overlay:
Current / proposed name:
Discovery source:
Callers / callees:
Direct / indirect call evidence:
libultra or custom-runtime calls:
Hardware registers:
Strings/assets/globals:
Jump-table/vtable involvement:
RSP/RDP/audio/DMA/save involvement:
Likely category:
Track impact: splat / N64Recomp / runtime / handwritten C / unknown
Evidence:
Confidence: Known / Likely / Tentative / Unknown
Next proof needed:
```

## Conservative Naming

Prefer candidates until proven:

```text
pi_dma_load_candidate
overlay_load_candidate
rsp_graphics_task_build_candidate
rdp_display_list_submit_candidate
audio_task_build_candidate
controller_poll_candidate
save_eeprom_write_candidate
asset_decompress_candidate
entity_update_candidate
game_state_dispatch_candidate
```

Record tool/source for every generated name; keep confidence separate from readability.

## Cross-Check Before Promoting to Known

```text
Call graph position
MIPS prologue/epilogue and saved registers
Branch-delay-slot effects
jal targets and fallthrough
jalr/jr $t9 / function-pointer evidence
ROM/VROM/VRAM/overlay mapping
libultra or custom-runtime calls
MMIO constants and DMA/cache behavior
RSP/RDP/audio task fields
Save/controller/PI/SI paths
Strings, assets, compression headers
Runtime traces, crash PCs
Original-vs-rebuilt behavior when shimming
```

## Report Groups

```text
Definitely not game logic:
Runtime/libultra/hardware support:
Likely game systems:
Overlay-specific functions:
Unknown internal functions:
High-priority for decompilation:
High-priority for runtime tracing:
High-risk indirect-control-flow:
Missing from Ghidra/splat/N64Recomp metadata:
```

## Summary Report Format

```text
Evidence proves:
Likely:
Tentative:
Unknown:
Functions discovered:
Functions missing from metadata:
Likely game functions:
Likely runtime/platform functions:
High-risk indirect control-flow sites:
Recommended next pass:
```

This pass is for evidence and planning — do not rewrite code or change splat/N64Recomp metadata unless the user asks for implementation after the inventory is complete.
