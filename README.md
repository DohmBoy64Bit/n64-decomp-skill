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
| `resources/` — phased playbooks (01–17, `db-n64-index.md`) | N64Recomp / Ghidra / CDB / Mupen64MCP / RMG installs |
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
| Ghidra + N64LoaderWV + GhidraMCP | A & B (static: baserom, overlays, boundaries) | `04-ghidra-mcp.md`, `15-mcp-client-setup.md` |
| CDB + PowerShell wrappers | B (native `.exe`, `.cdb.txt` traces, Windows) | `16-cdb-debug-playbook.md` |
| Mupen64MCP guest debug | B (live **guest** breakpoints/RDRAM, when stuck) | `17-mupen64mcp-playbook.md` |
| RMG MCP debug bridge | B (alternative guest runtime) | `14-rmg-mcp-playbook.md` |

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
- **Ghidra 12.x** (e.g. 12.0.4) + [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV) + [bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp) — static baserom analysis, overlay dispatch tables, pre-recomp boundaries (`04-ghidra-mcp.md`)
- **CDB** (Windows SDK / Debugging Tools) + project `tools/*cdb*.ps1` wrappers — native recomp EXE breakpoints and `.cdb.txt` trace logs (`16-cdb-debug-playbook.md`)
- **MCP client wiring:** `resources/15-mcp-client-setup.md` + `examples/mcp-servers.template.json` — client-agnostic `ghidra` + optional `n64-debug-mcp` and/or `rmg-n64-debugger` (Cursor, Claude, Codex, VS Code, …)
- **Optional guest runtime MCP:** [DohmBoy64Bit/Mupen64MCP](https://github.com/DohmBoy64Bit/Mupen64MCP) — clone + MSYS2 build — `resources/17-mupen64mcp-playbook.md`
- **Alternative runtime MCP:** [thebardockgames/RMG](https://github.com/thebardockgames/RMG) — `resources/14-rmg-mcp-playbook.md`; not bundled or required
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

### Host recomp debug with CDB (Track B, Windows)

```
Read resources/16-cdb-debug-playbook.md and resources/04-ghidra-mcp.md.
Project root: [PATH]. List tools/*cdb*.ps1 wrappers and the last .cdb.txt trace if any.
I need to prove whether [SYMBOL or PATH] is hit or bypassed in the native recomp EXE (or diagnose [e.g. std::thread abort]).
Propose breakpoint changes only after reading the wrapper script. Archive trace evidence using examples/cdb-trace-evidence-template.txt.
```

### Guest runtime MCP setup (Mupen64MCP)

```
Read resources/17-mupen64mcp-playbook.md and resources/15-mcp-client-setup.md.
Clone https://github.com/DohmBoy64Bit/Mupen64MCP to [PATH]. Walk MSYS2 MINGW64 build steps
(core DEBUGGER, n64-debug-daemon, uv sync in mcp/python), then wire Cursor MCP server id n64-debug-mcp.
Verify n64_status with my ROM at [PATH] (do not commit ROM path to shared config).
```

> **Why this works:** The prompts force *read first, detect second, ask third, act last* — same pattern as [ps2-recomp-Agent-SKILL](https://github.com/hkmodd/ps2-recomp-Agent-SKILL). The agent cannot skip boot files, assume paths, or start wide yaml/TOML/runtime edits without your go-ahead.

---

## How to collaborate (human-in-the-loop)

N64 matching decomp and static recomp still need your eyes on hardware and metadata:

- **Monitor `N64_PROJECT_STATE.md`** — open it in split-screen. The agent should update phase, paths, mapping table, and triage rows after major actions. If it hallucinated an address or phase, correct the Markdown directly; the agent re-reads it on the next boot or context refresh (`SKILL.md` §6).
- **Beware context degradation** — long sessions can make the agent ask obvious questions or forget BSS-in-yaml rules. Stop, open a **new chat**, and use **Quick resume** above. The skill’s degradation canary (every 15 tool calls) is in `SKILL.md` §6.
- **Prepare Ghidra yourself** — the agent drives GhidraMCP, but you import the ROM with [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV), confirm **MIPS N64** (not another arch), leave CodeBrowser open, and wire MCP per `resources/15-mcp-client-setup.md`.
- **Optional guest runtime MCP** — [Mupen64MCP](https://github.com/DohmBoy64Bit/Mupen64MCP) (`resources/17-mupen64mcp-playbook.md`) or RMG (`resources/14-rmg-mcp-playbook.md`) for live guest PC/register evidence when static triage stalls. Not required for matching decomp or first recomp bring-up.
- **Let builds finish** — splat split, `configure.py --build`, and N64Recomp codegen can take time. The agent should read full log output before claiming success (`SKILL.md` §3 prohibition 8).
- **Two workspaces** — skill install (playbook) vs your game/decomp root (ROM, yaml, asm, TOML). Game files are often a **sibling folder**; tell the agent the project root once and ensure it lands in `N64_PROJECT_STATE.md`.

---

## Troubleshooting

| Problem | Tell the agent |
|---------|----------------|
| It asks you to hand-edit `asm/*.s` or `RecompiledFuncs/` first | *"Read your skill §3 — fix yaml/TOML/symbols/runtime before generated trees."* |
| It keeps guessing the same crash | *"Circuit breaker — stop patching. Update `N64_PROJECT_STATE.md` and use `13-decisional-brain.md` debug format with evidence."* |
| It forgot phase, track, or an address | *"Context refresh — read `N64_PROJECT_STATE.md` and `11-operational-phases.md`."* |
| It wants you to look in Ghidra manually | *"Use GhidraMCP yourself — see `04-ghidra-mcp.md`. Confirm N64LoaderWV MIPS program is loaded."* |
| It claims match/recomp success without logs | *"Show the actual `configure.py --diff` or N64Recomp/build output before we continue."* |
| It mixes matching yaml fixes with recomp runtime patches | *"Phase-correct triage only — separate splat from TOML/runtime per `10-agent-guardrails.md`."* |
| MCP tools fail or wrong arch in Ghidra | See **Troubleshooting** in `resources/15-mcp-client-setup.md` (connection, N64LoaderWV import, server paths). |

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
│   ├── 14-rmg-mcp-playbook.md   # Optional RMG guest runtime MCP
│   ├── 15-mcp-client-setup.md   # Ghidra + guest runtime MCP autoconfig
│   ├── 16-cdb-debug-playbook.md # CDB native EXE traces (Windows)
│   ├── 17-mupen64mcp-playbook.md # Mupen64MCP clone/build + guest debug
│   └── db-n64-index.md      # Master router
├── scripts/
│   ├── configure_min.py
│   ├── project-state-template.md
│   └── package_release.ps1  # Dev packaging (not in .skill)
├── examples/
│   ├── cdb-trace-evidence-template.txt
│   ├── mcp-servers.template.json
│   ├── recomp-toml-skeleton.toml
│   └── splat-bss-subsegment.yaml
└── evals/                   # Dev only (not in .skill)
```

---

## Development / evals

Skill-creator evals under `evals/`; benchmark runs in `n64-decomp-workspace/` (gitignored).

| Iteration | Skill | Method | with_skill | without_skill | Δ | Notes |
|-----------|-------|--------|------------|---------------|---|-------|
| **14** | **v1.4.0** | Live subagents (Auto) | **100%** | **34.3%** | **+65.7%** | Mupen64MCP + `mcp-full-setup` 7/7 vs 2/7 |
| 13 | v1.3.0 | Live subagents (Auto) | 100% | 33.3% | +66.7% | CDB + Ghidra overlay stable |
| 12 | v1.3.0 | Live subagents (Auto) | 100% | 31.9% | +68.1% | First live subagent run |

Package after eval passes: `powershell -File scripts/package_release.ps1` → `dist/n64-decomp.skill`.

---

## License

MIT — see [LICENSE](LICENSE). You must **own** any N64 software you analyze. No ROM distribution.

---

## Links

- **Releases:** https://github.com/DohmBoy64Bit/n64-decomp-skill/releases (current: **v1.4.0**)
- [splat](https://github.com/ethteck/splat) · [N64Recomp](https://github.com/N64Recomp/N64Recomp) · [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV) · [GhidraMCP](https://github.com/bethington/ghidra-mcp) · [Mupen64MCP](https://github.com/DohmBoy64Bit/Mupen64MCP) · [RMG MCP](https://github.com/thebardockgames/RMG)
- Related: [pcrecomp-skill](https://github.com/DohmBoy64Bit/pcrecomp-skill), [xboxrecomp-skill](https://github.com/DohmBoy64Bit/xboxrecomp-skill)
- Design inspiration: [ps2-recomp-Agent-SKILL](https://github.com/hkmodd/ps2-recomp-Agent-SKILL)
