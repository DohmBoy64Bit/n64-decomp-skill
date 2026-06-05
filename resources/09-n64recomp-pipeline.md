# N64Recomp Static Recompilation Workflow

Read this for native recompilation/PC ports: N64Recomp, N64ModernRuntime, Zelda64Recomp-style projects, RT64, static recompilation.

**Not** the same as matching decomp:

- **splat/decomp** → matching ROM, symbols, splits, optional ELF
- **N64Recomp** → consumes ROM/ELF/symbols, emits C/C++ compiled with a host runtime

A finished port still needs runtime glue, renderer, input, audio, saves, overlays, and patches.

## Prerequisites

Before N64Recomp:

1. Known-good `baserom.z64` (never committed)
2. Correct splat entrypoint, `vram`, BSS, major boundaries
3. Enough symbols for indirect calls, libultra/custom runtime, overlays, scheduler/audio/graphics
4. ELF or symbol metadata N64Recomp can consume
5. Generated folders treated as artifacts — fix YAML/symbols/metadata first

Raw ROM only → guide through `02-splat-setup.md` first.

## Build N64Recomp

```bash
git clone --recursive https://github.com/N64Recomp/N64Recomp.git external/N64Recomp
cmake -S external/N64Recomp -B external/N64Recomp/build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build external/N64Recomp/build --config Release
```

Requires CMake 3.20+ and C++20. Windows: VS x64 dev shell or Clang/Ninja.

## N64ModernRuntime

```bash
git clone --recursive https://github.com/N64Recomp/N64ModernRuntime.git external/N64ModernRuntime
```

Provides:

- **ultramodern** — threads, controllers, audio, queues, timers, RSP, VI timing
- **librecomp** — bridge to N64Recomp output, overlays, PI DMA/ROM, saves

Prefer `add_subdirectory(...)` in CMake. Project still provides platform callbacks and renderer. **RT64** is the default renderer for N64Recomp-style PC ports unless intentionally custom. Keep RT64 separate from generated CPU code.

## Optional Host / Frontend Libraries

Only when building launcher, settings, mod menu, or modern input — not minimal bring-up:

- **RmlUi** — host UI (launcher, settings, controller config, debug overlays)
- **lunasvg** — SVG in RmlUi (icons/logos)
- **FreeType** — RmlUi fonts (unless custom font engine)
- **moodycamel queues** — host MPMC/event queues (not direct `OSMesgQueue` replacement unless shim maps them)
- **Gamepad Motion Helpers** — optional gyro aiming (not required for original input)

```text
Launcher/settings UI?     → RmlUi
SVG icons?                → RmlUi + lunasvg
Fonts for RmlUi?          → FreeType (or custom engine)
Host thread queues?       → moodycamel
Gyro aiming?              → Gamepad Motion Helpers + SDL/JoyShock
```

## Input Metadata (TOML)

Verify functions before blaming N64Recomp:

```bash
readelf -Ws build/<game>.elf | rg "FUNC|OBJECT|entry|_start"
```

Workflows:

- **ELF**: `elf_path` when splat/decomp emits ELF with valid function symbols
- **Symbol file**: `symbols_file_path` + `rom_file_path` (Zelda64Recomp-style)

Minimal skeleton:

```toml
[input]
entrypoint = 0x80000000
output_func_path = "RecompiledFuncs"
elf_path = "build/<game>.elf"
# rom_file_path = "baserom.z64"
# symbols_file_path = "symbols/<game>.syms.toml"
# relocatable_sections_path = "overlays.txt"

[patches]
stubs = []
ignored = []
```

Use the real entrypoint from splat YAML, symbols, and boot flow — not a guess.

## Code Generation

```bash
external/N64Recomp/build/N64Recomp <game>.recomp.toml
```

Windows:

```powershell
.\external\N64Recomp\build\Release\N64Recomp.exe .\<game>.recomp.toml
```

Treat `RecompiledFuncs/` as generated — fix TOML, symbols, stubs, relocations, not hand-edits.

## Indirect Control Flow

```text
jr $ra        return only if stack/control flow confirm
jr $t9/$v0    function pointer, vtable, callback, jump table
jalr $reg     indirect call — needs target-set evidence
jr table      switch dispatch — validate table boundary
```

Required evidence: source register producer, possible targets, overlay state, delay slot, runtime lookup behavior.

Do not direct-call because the decompiler looked obvious.

## Overlays

1. Identify overlay tables and DMA/load routines in decomp first
2. Verify `relocatable_sections_path`
3. Confirm `jalr`/pointer targets resolve via runtime lookup
4. Debug load/unload order before blaming generated code

## RSP Microcode

Use `RSPRecomp` separately for supported microcode. Identify text/data addresses from DMA/task setup first.

```bash
external/N64Recomp/build/N64Recomp <game>.recomp.toml
external/N64Recomp/build/RSPRecomp <ucode-name>.toml
```

If unsupported instructions, verify blob boundaries and byte order before changing the tool.

## RT64 Integration

N64Recomp does not implement RSP/RDP rendering. Use RT64 after metadata + runtime scaffolding:

1. N64Recomp generation works
2. N64ModernRuntime linked
3. RDRAM, ROM reads, PI DMA, timing, callbacks exist
4. Graphics task submission path identified
5. Overlay registration if graphics code is in overlays

Before blaming RT64 for black screen / missing graphics:

- Valid graphics task and display-list pointer (guest RDRAM → runtime translation)
- PI DMA completed before display-list/matrices/textures/ucode
- Cache writeback/invalidate before RSP reads
- RSP submission and SP completion signaling
- VI origin, width, framebuffer, pacing
- Overlays with graphics code loaded and registered
- Supported or intentionally handled microcode

Boundaries:

```text
N64Recomp          → CPU static recompilation
N64ModernRuntime   → libultra-style bridge
RT64               → RSP/RDP/display-list path
project glue       → DMA, input, audio, saves, overlays, UI, patches
```

## Runtime Responsibility Audit

Host/runtime must cover:

- RDRAM allocation and guest↔host translation
- ROM reads, PI DMA, overlays, saves
- Queues, timers, VI timing, threading
- RSP tasks, RDP/display lists (usually RT64)
- Controllers, audio, host paths
- Custom-runtime shims when libultra is absent

Do not fake hardware behavior without understanding the original path and a verification plan.

## Host Integration Checklist

1. Add generated recomp files to build target
2. Add N64ModernRuntime via CMake
3. Platform callbacks: input, audio, ROM, saves, timing, window/events
4. Register renderer (RT64 default)
5. Entrypoint and runtime startup
6. Overlay section registration
7. Custom-runtime shims if needed
8. Optional RmlUi / motion helpers only when requested
9. Stubs/patches only after proving original cannot run on host

## Patches and Stubs

Document every patch: function, VRAM, original behavior, replacement, reason.

Prefer N64Recomp patch/single-file-output over editing generated output. Link patches before the generated library.

## Failure Modes

- **Entrypoint found but no boot** — host runtime/renderer/startup incomplete
- **Missing/tiny function count** — fix ELF/symbol export first
- **Indirect call crashes** — overlay lookup, pointer metadata, section state
- **RCP wait loops hang** — narrow patch after identifying expected behavior
- **Bad addresses** — KSEG0/KSEG1, translation, PI DMA, byte order
- **Generated C compile errors** — fix metadata first

## Artifacts to Request

- recomp TOML, N64Recomp console output
- splat YAML segment/overlay entries
- `readelf -Ws` for failing function/entrypoint
- crash log with guest PC/LR/registers
- function around failing `jal`, `jalr`, DMA, overlay load, RCP wait

Do not ask for ROM files or copyrighted assets.

## Optional: runtime emulator MCP

If static triage stalls and the user has [thebardockgames/RMG](https://github.com/thebardockgames/RMG) with MCP bridge: see **`14-rmg-mcp-playbook.md`** for `bridge_status`, guest PC/register inspection, and trace compare. This does not replace overlay registration or TOML fixes.
