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

```powershell
$stage = "dist\n64-decomp"
New-Item -ItemType Directory -Force -Path "$stage\resources","$stage\scripts","$stage\examples" | Out-Null
Copy-Item SKILL.md $stage\
Copy-Item resources\* $stage\resources\
Copy-Item scripts\* $stage\scripts\
Copy-Item examples\* $stage\examples\
cd path\to\skill-creator
python -m scripts.package_skill E:\SkillDev\N64decomp\dist\n64-decomp E:\SkillDev\N64decomp\dist
```

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

### Fresh matching decomp

```
Read n64-decomp/SKILL.md boot sequence. I have baserom.n64 at [PATH].
Project root: [PATH]. Start Phase 0–1 (ROM recon + splat). Report before editing yaml.
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
│   └── db-n64-index.md      # Master router
├── scripts/
│   ├── configure_min.py
│   └── project-state-template.md
├── examples/
│   ├── recomp-toml-skeleton.toml
│   └── splat-bss-subsegment.yaml
└── evals/                   # Dev only (not in .skill)
```

---

## Development / evals

Skill-creator evals under `evals/`; benchmark runs in `n64-decomp-workspace/` (gitignored). Iteration 6: with_skill **100%**, baseline **85.7%**.

---

## License

MIT — see [LICENSE](LICENSE). You must **own** any N64 software you analyze. No ROM distribution.

---

## Links

- **Releases:** https://github.com/DohmBoy64Bit/n64-decomp-skill/releases
- [splat](https://github.com/ethteck/splat) · [N64Recomp](https://github.com/N64Recomp/N64Recomp) · [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV) · [GhidraMCP](https://github.com/bethington/ghidra-mcp) · [RMG MCP](https://github.com/thebardockgames/RMG)
- Related: [pcrecomp-skill](https://github.com/DohmBoy64Bit/pcrecomp-skill), [xboxrecomp-skill](https://github.com/DohmBoy64Bit/xboxrecomp-skill)
- Design inspiration: [ps2-recomp-Agent-SKILL](https://github.com/hkmodd/ps2-recomp-Agent-SKILL)
