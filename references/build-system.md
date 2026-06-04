# Build System (Matching ROM)

Read this when `asm/` exists after splat split and you need the **first byte-matching ROM** before libultra, decomp.me, or C.

## Initial Setup

Use [configure_min.py](configure_min.py) — the skill-bundled helper for status, splat commands, and emitting a starter `configure.py`.

If the script lives under `references/` in the skill repo, run it from the **decomp project root** (copy the script or invoke by path). Do not skip `--emit-configure` and hand-write a Pokemon Snap-style multi-target configure on day one.

```bash
# From project root (after uv + baserom present)
python references/configure_min.py --status
python references/configure_min.py --create-config --rom baserom.n64
python references/configure_min.py --split --yaml <game>.yaml
python references/configure_min.py --emit-configure --game <game>
```

`--emit-configure` writes a starter `configure.py` + ninja rules for all `asm/**/*.s`. You still need a linker script (from splat or project docs) and MIPS toolchain paths. Do not use complex multi-target configure examples until C compilation is needed.

After `configure.py` exists: `chmod +x configure.py` (Unix) or run with `python configure.py`.

Goal: matching ROM with all assembly objects. Compiler version does not matter at this stage.

## BSS Mismatch

Never edit asm files for address mismatches — splat regenerates them.

If entrypoint references `main_BSS_START` with wrong value, calculate `bss_size` from entry asm (usually `asm/1000.s` — splat names by ROM offset):

```asm
lui  $t0, 0x800e        # BSS_START high
lui  $t1, (0x7DAC0 >> 16)
addiu $t0, $t0, 0x2e00  # BSS_START = 0x800e2e00
ori  $t1, $t1, (0x7DAC0 & 0xFFFF)  # BSS_SIZE = 0x7DAC0
```

Add to YAML:

```yaml
- name: main
  type: code
  start: 0x1050
  vram: 0x80001050
  bss_size: 0x7DAC0
  subsegments:
    - [0x1050, asm]
    - { start: 0xB1BD0, type: .bss, vram: 0x800E2E00 }
```

`.bss` vram must match BSS_START from entrypoint. Then `python configure.py --clean` and rebuild.

## After First Match

1. Add suggested splits from splat output to yaml
2. Rebuild and verify still matches
3. Checkpoint: verify match, commit
4. Proceed to libultra identification

Checkpoints are good verification points — do not wait for user input at checkpoints.

## Symbol Confidence Labels

```text
Known       ELF symbol, clean map, confirmed call target
Likely      prologue/control-flow/XREF evidence
Tentative   Ghidra, n64sym, pattern matching only
Unknown     needs raw assembly, trace, or better mapping
```

Never feed tentative boundaries into N64Recomp without checking raw disassembly, branch targets, delay slots, data boundaries, and segment/overlay mapping.

Export columns:

```text
Name, VRAM Start, VRAM End, Size, ROM/VROM, Type, Confidence, Evidence
```
