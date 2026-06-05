# n64-decomp (Cursor Agent Skill)

Agent skill for **Nintendo 64 matching decompilation** and **N64Recomp static PC ports** — structured like a behavioral constraint system ([ps2-recomp-Agent-SKILL](https://github.com/hkmodd/ps2-recomp-Agent-SKILL) design): decision router, boot sequence, persistent `N64_PROJECT_STATE.md`, circuit breakers, and on-demand `resources/`.

This skill is a **playbook** for the AI agent. It does **not** include game ROMs, splat output, or N64Recomp binaries.

---

## How to treat the agent

1. **Autonomous within guardrails** — let it run splat, configure, and read logs; it should fix yaml/TOML/runtime before generated trees.
2. **Persistent memory** — the agent maintains `N64_PROJECT_STATE.md` in your project (external hippocampus). Resume weeks later by pointing at that file.
3. **Circuit breakers** — after repeated failures on the same crash, it should stop guessing and ask for narrow evidence (see `resources/10-agent-guardrails.md`).

---

## What you get

| Included | Not included |
|----------|----------------|
| `SKILL.md` — router, boot, prohibitions, state protocol | Your ROM or decomp tree |
| `resources/` — phased playbooks (01–15, `db-n64-index.md`) | N64Recomp / Ghidra / RMG installs |
| `scripts/configure_min.py` — first asm match helper | Matching game `code/` |
| `examples/` — TOML + BSS yaml templates | |

---

## Tracks — matching decomp vs static recomp

The skill runs two related workflows. Both start from the same ROM/splat metadata; they diverge after you have trustworthy splits and boundaries. Full phase tables live in `resources/11-operational-phases.md`.

| | **Track A — Matching decompilation** | **Track B — N64Recomp static port** |
|---|----------------------------------------|-------------------------------------|
| **Goal** | Reproduce the original ROM byte-for-byte | Lift game logic to native C/C++ with a PC host runtime |
| **Success** | `configure.py --diff` clean; later per-file C match | Boot past indirect calls; stable VI/audio/input/saves |
| **Primary tools** | splat, MIPS asm/linker, m2c/decomp.me, IDO/GCC | N64Recomp, N64ModernRuntime, librecomp, RT64 |
| **Do not edit as first fix** | splat-generated `asm/*.s` | `RecompiledFuncs/` and other generated recomp output |
| **Fix order** | yaml → re-split → rebuild | yaml/TOML/symbols → runtime overlays → host glue |

**Shared foundation (both tracks):** Phase 0 ROM recon, splat split, first asm match or clean metadata, function ledger with evidence (`04-ghidra-mcp.md`, `05-function-discovery.md`). Do not start N64Recomp codegen on a dirty yaml or tentative-only boundaries.

### Track A — Matching decompilation (phases 0–5)

| Phase | Goal | Key resources | Exit criteria |
|-------|------|---------------|---------------|
| **0 — ROM recon** | Hash, byte order, entrypoint, save/RDRAM hints | `12-n64-hardware-subsystems.md` | Recorded in `N64_PROJECT_STATE.md` |
| **1 — Splat** | uv, `create_config`, split, gitignore | `02-splat-setup.md` | `asm/` exists; no `hardware_regs` / `libultra_symbols` on day one |
| **2 — First asm match** | Byte-identical ROM from asm only | `03-matching-build.md`, `scripts/configure_min.py` | `--diff` clean; BSS in yaml, not hand-patched asm |
| **3 — Discovery** | Function ledger, boundaries, confidence | `05-function-discovery.md`, `04-ghidra-mcp.md` | `docs/function_ledger.md` before bulk `symbol_addrs` |
| **4 — Runtime block** | libultra **or** custom MMIO path | `06-libultra.md` **or** `07-custom-runtime.md` | OS-layer boundaries and symbols identified |
| **5 — Compiler + C** | IDO/GCC match, m2c / decomp.me | `08-compiler-and-c.md`, **`n64-decomp-ido`** skill | Per-file or per-module match |

### Track B — N64Recomp static port (phases B0–B4)

| Phase | Goal | Key resources | Exit criteria |
|-------|------|---------------|---------------|
| **B0 — Metadata clean** | Trustworthy splat/symbols/overlays | `02-splat-setup.md`, `05-function-discovery.md` | Enough symbols for indirect calls |
| **B1 — Codegen** | N64Recomp emits C | `09-n64recomp-pipeline.md` | Entrypoint found; function count sane |
| **B2 — Runtime** | librecomp, overlays, DMA | `09-n64recomp-pipeline.md` § Runtime | `register_overlays` / load order before `jalr` use |
| **B3 — Renderer / host** | RT64, input, audio, saves | `09-n64recomp-pipeline.md` § Host | Boot past first indirect; VI/audio stable |
| **B4 — Polish** | Launcher, UI, extras (optional) | `09-n64recomp-pipeline.md` § Optional host | Only if you request it |

Reference recomp ports (**Zelda64Recomp**, **Kirby64Recomp**, **Dinosaur Planet Recompiled**) are cited for **CMake/layout patterns only** — not for copying symbols, overlays, or assets (`13-decisional-brain.md`).

### Optional cross-track tooling

| Tool | Track | Resource |
|------|-------|----------|
| Ghidra + N64LoaderWV + GhidraMCP | A & B (static evidence) | `04-ghidra-mcp.md`, `15-mcp-client-setup.md` |
| RMG MCP debug bridge | B (live guest state, when stuck) | `14-rmg-mcp-playbook.md` |

### Which track am I on?

Inspect the workspace (game root may be a **sibling folder** of the skill install):

| Signal | Likely track |
|--------|----------------|
| `configure.py`, matching `--diff`, no `*.recomp.toml` | **Track A** |
| `*.recomp.toml`, `RecompiledFuncs/`, `external/N64Recomp` | **Track B** |
| Only `baserom` + fresh yaml | **A** from phase 0, or **B** only after metadata is clean |

The agent should report **track + phase + one next step** before wide refactors (`SKILL.md` §2 boot sequence).

---

## Prerequisites

- **Cursor** (or compatible agent) with skills support
- **uv** + **splat64[mips]** for split workflows
- **MIPS** assembler/linker for matching; **N64Recomp** + **N64ModernRuntime** for static ports
- **Ghidra 11+** + [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV) (N64 ROM loader) + [bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp) for static MCP evidence (optional but recommended)
- **MCP client wiring:** `resources/15-mcp-client-setup.md` + `examples/mcp-servers.template.json` — client-agnostic `ghidra` + optional `rmg-n64-debugger` servers (Cursor, Claude, Codex, VS Code, …)
- **Optional runtime MCP:** [thebardockgames/RMG](https://github.com/thebardockgames/RMG) MCP Debug Bridge — `resources/14-rmg-mcp-playbook.md`; not bundled or required
- Pair **`n64-decomp-ido`** after IDO compiler identification

---

## Installation

### Option 1: Skill folder

| Scope | Path |
|-------|------|
| Personal | `~/.cursor/skills/n64-decomp/` |
| Agents | `~/.agents/skills/n64-decomp/` |
| Project | `.cursor/skills/n64-decomp/` |

### Option 2: Download `n64-decomp.skill` (recommended)

**[GitHub Releases](https://github.com/DohmBoy64Bit/n64-decomp-skill/releases)** — one-file Cursor import (`SKILL.md` + `resources/` + `scripts/` + `examples/`; no `evals/`).

### Option 3: Build `.skill`

**Fast path** (~3s, ~40 KB artifact):

```powershell
powershell -File scripts/package_release.ps1
```

**Manual stage** — package **`dist/n64-decomp` only**, not the repo root:

```powershell
# Do NOT run package_skill on the repo root — it walks dist/ and n64-decomp-workspace/ too.
$stage = "dist\n64-decomp"
# ... copy SKILL.md, resources/, scripts/, examples/ into $stage ...
cd path\to\skill-creator
python -m scripts.package_skill E:\SkillDev\N64decomp\dist\n64-decomp E:\SkillDev\N64decomp\dist
```

Output: `dist/n64-decomp.skill`. If a prior run created a multi-GB `*.skill` in `dist/`, delete it before repackaging.

---

## Start a session

### Universal starter prompt

```
Read n64-decomp/SKILL.md and execute the §2 BOOT SEQUENCE.

Load resources/11-operational-phases.md and the boot files for my track
(matching: 02-splat-setup.md + 03-matching-build.md;
 recomp: 02-splat-setup.md + 09-n64recomp-pipeline.md).

1. INSPECT my workspace for N64_PROJECT_STATE.md, baserom, yaml, asm/, configure.py,
   RecompiledFuncs/, *.recomp.toml. Game files may be in a sibling folder — ask if missing.
2. REPORT phase, track, and one concrete next step. Wait for my go-ahead on wide changes.
```

### Quick resume (new chat)

```
Read n64-decomp/SKILL.md, then N64_PROJECT_STATE.md in my project. Resume from there.
```

### Fresh matching decomp (Track A)

```
Read n64-decomp/SKILL.md boot sequence. I have baserom.n64 at [PATH].
Project root: [PATH]. Start Phase 0–1 (ROM recon + splat). Report before editing yaml.
```

### Fresh static recomp (Track B)

```
Read n64-decomp/SKILL.md boot sequence and resources/11-operational-phases.md.
Project root: [PATH]. I want a N64Recomp PC port.
Inspect baserom, yaml, asm/, symbols, and any existing *.recomp.toml.
Report track B phase (B0–B4), gaps, and one next step before editing TOML or RecompiledFuncs/.
```

### Stuck / crash triage (either track)

```
Read n64-decomp/SKILL.md and resources/13-decisional-brain.md.
Classify track and phase, then answer in the mandatory debug format (Phase, Structural Cause, Evidence, Fix, Verification).
```

---

## Skill layout

```
n64-decomp/
├── README.md
├── SKILL.md                 # Behavioral constraint hub (read first)
├── resources/
│   ├── 01-environment-setup.md … 09-n64recomp-pipeline.md
│   ├── 10-agent-guardrails.md
│   ├── 11-operational-phases.md
│   ├── 12-n64-hardware-subsystems.md
│   ├── 13-decisional-brain.md
│   ├── 14-rmg-mcp-playbook.md   # Optional live emulator MCP
│   ├── 15-mcp-client-setup.md   # Ghidra + RMG MCP autoconfig
│   └── db-n64-index.md      # Master router
├── scripts/
│   ├── configure_min.py
│   ├── project-state-template.md
│   └── package_release.ps1  # Dev packaging (not in .skill)
├── examples/
│   ├── mcp-servers.template.json
│   ├── recomp-toml-skeleton.toml
│   └── splat-bss-subsegment.yaml
└── evals/                   # Dev only (not in .skill)
```

---

## Development / evals

Skill-creator evals under `evals/`; benchmark runs in `n64-decomp-workspace/` (gitignored). Latest (iteration 9, v1.2.0): with_skill **100%**, baseline **78.6%**, Δ **+21.4%** across 10 evals.

---

## License

MIT — see [LICENSE](LICENSE). You must **own** any N64 software you analyze. No ROM distribution.

---

## Links

- **Releases:** https://github.com/DohmBoy64Bit/n64-decomp-skill/releases (current: **v1.2.0**)
- [splat](https://github.com/ethteck/splat) · [N64Recomp](https://github.com/N64Recomp/N64Recomp) · [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV) · [GhidraMCP](https://github.com/bethington/ghidra-mcp) · [RMG MCP](https://github.com/thebardockgames/RMG)
- Related: [pcrecomp-skill](https://github.com/DohmBoy64Bit/pcrecomp-skill), [xboxrecomp-skill](https://github.com/DohmBoy64Bit/xboxrecomp-skill)
- Design inspiration: [ps2-recomp-Agent-SKILL](https://github.com/hkmodd/ps2-recomp-Agent-SKILL)
