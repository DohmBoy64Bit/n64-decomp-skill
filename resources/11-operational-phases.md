# Operational Phases — Matching Decomp & Static Recomp

Use at **session start** and when the user asks "what's next?"

## Track A — Matching Decompilation

| Phase | Goal | Load | Exit criteria |
|-------|------|------|---------------|
| **0 — ROM recon** | Hash, byte order, entrypoint, save/RDRAM hints; optional Ghidra static + Mupen64MCP `n64_detect_os` / boot trace if MCP built | `12-n64-hardware-subsystems.md` § Phase 0, `04-ghidra-mcp.md`, optional `17-mupen64mcp-playbook.md` | Recorded in `N64_PROJECT_STATE.md` |
| **1 — Splat** | uv, `create_config`, split, gitignore | `02-splat-setup.md` | `asm/` exists; no `hardware_regs`/`libultra_symbols` day one |
| **2 — First asm match** | Byte-identical ROM from asm only | `03-matching-build.md`, `scripts/configure_min.py` | `configure.py --diff` clean; BSS in yaml not asm |
| **3 — Discovery** | Function ledger, boundaries, confidence; Ghidra static + optional guest MCP to confirm `jalr`/overlay targets | `05-function-discovery.md`, `04-ghidra-mcp.md`, optional `17-mupen64mcp-playbook.md` | `docs/function_ledger.md` before bulk `symbol_addrs` |
| **4 — Runtime block** | libultra **or** custom MMIO path | `06-libultra.md` **or** `07-custom-runtime.md` | Boundaries + symbols for OS layer |
| **5 — Compiler + C** | IDO/GCC match, m2c/decomp.me | `08-compiler-and-c.md`, `n64-decomp-ido` skill | Per-file or per-module match |

## Track B — N64Recomp Static Port

| Phase | Goal | Load | Exit criteria |
|-------|------|------|---------------|
| **B0 — Metadata clean** | splat/symbols/overlays trustworthy | `02-splat-setup.md`, `05-function-discovery.md` | Enough symbols for indirect calls |
| **B1 — Codegen** | N64Recomp emits C | `09-n64recomp-pipeline.md` | Entrypoint found; function count sane |
| **B2 — Runtime** | librecomp, ultramodern, overlays | `09-n64recomp-pipeline.md` § Runtime | `register_overlays` / load order before `jalr` use |
| **B3 — Renderer / host** | RT64, input, audio, saves | `09-n64recomp-pipeline.md` § Host | Boot past first indirect; VI/audio stable |
| **B4 — Polish** | RmlUi, gyro, launcher (optional) | `09-n64recomp-pipeline.md` § Optional host | Only if user requests |

**Rule:** Track A and B share Phase 0–3 evidence. Do not start B1 on a dirty splat yaml or tentative-only boundaries.

## Phase Detection (Boot)

Inspect workspace for:

- `baserom.z64` / `baserom.n64`, `<game>.yaml`
- `asm/` tree
- `configure.py`, `build/`, matching diff output
- `*.recomp.toml`, `RecompiledFuncs/`, `external/N64Recomp`
- `N64_PROJECT_STATE.md`, `docs/function_ledger.md`

Game files may live in a **sibling directory** — ask once, record path in state file.

## Checkpoints (Do Not Skip Verification)

After Phase 2: ROM sha256/cmp match. After yaml BSS fix: re-split + `--clean` rebuild. After N64Recomp: `readelf -Ws` on ELF before blaming runtime.
