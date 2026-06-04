# n64-decomp (Cursor Agent Skill)

Agent skill for **Nintendo 64 matching decompilation** and **N64Recomp static PC ports** — splat/uv setup, first assembly-only ROM match (`configure_min.py`), GhidraMCP evidence, libultra or custom-runtime paths, and phase-based recomp triage.

This skill is a **playbook and reference layer** for the AI agent. It does **not** include game ROMs, splat output, N64Recomp binaries, or your decomp project tree.

---

## What you get

| Included in the skill | Not included (you provide separately) |
|----------------------|----------------------------------------|
| `SKILL.md` — routing, core rules, ROM/address discipline, debug format | Your `baserom` / `baserom.z64` (you must own the game) |
| `references/` — splat, build, GhidraMCP, libultra, N64Recomp, env setup | Clones of [N64Recomp](https://github.com/N64Recomp/N64Recomp), Ghidra, ultralib |
| `references/configure_min.py` — starter matching `configure.py` emitter | Full game `asm/`, `code/`, or matching decomp repo |
| Eval prompts under `evals/` (development only) | Python 3.10+, uv, MIPS toolchain, IDO/GCC when matching C |

---

## Requirements

- **Cursor** (or compatible agent) with skills support
- **uv** + **splat64[mips]** for ROM split workflows
- **Matching:** MIPS assembler/linker, splat linker script, optional [decomp.me](https://decomp.me) for compiler ID
- **Recomp:** N64Recomp + N64ModernRuntime/librecomp (or Zelda64Recomp-style layout as reference)
- **Ghidra 11+** + [bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp) when using MCP evidence workflows

Pair with the **`n64-decomp-ido`** skill after you identify an IDO compiler for C matching.

---

## Installation

### Option 1: Skill folder

Copy or symlink this directory to a skills path Cursor reads:

| Scope | Path |
|-------|------|
| Personal (all projects) | `~/.cursor/skills/n64-decomp/` |
| Agents (Codex-style) | `~/.agents/skills/n64-decomp/` |
| Project (repo-only) | `.cursor/skills/n64-decomp/` |

The folder must contain `SKILL.md` at its root.

### Option 2: Download `n64-decomp.skill` (recommended for install)

**[GitHub Releases](https://github.com/DohmBoy64Bit/n64-decomp-skill/releases)** attach a pre-built **`n64-decomp.skill`** file.

| What it is | What it is for |
|------------|----------------|
| A **ZIP archive** (`.skill` extension) of this skill folder | **One-file install** in Cursor — import without cloning this repo |
| Contains `SKILL.md` + `references/` | Agent playbook and quickrefs |
| Does **not** contain your game ROM or decomp tree | You supply lawful ROM hashes and project files |

**Steps:**

1. Open [Releases](https://github.com/DohmBoy64Bit/n64-decomp-skill/releases) and download **`n64-decomp.skill`** from the latest tag.
2. Install through Cursor’s skill import UI (or unpack into `~/.cursor/skills/n64-decomp/`).

`evals/` and `n64-decomp-workspace/` are omitted from the package (development-only).

### Option 3: Build `.skill` yourself

From [skill-creator](https://github.com/anthropics/skills) `package_skill.py`:

```powershell
# Stage skill-only tree (no eval workspace)
$stage = "dist\n64-decomp"
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item SKILL.md, references -Destination $stage -Recurse -Force
cd path\to\skill-creator
python -m scripts.package_skill E:\SkillDev\N64decomp\dist\n64-decomp E:\SkillDev\N64decomp\dist
```

Produces `n64-decomp.skill`. The packager skips top-level `evals/` by default.

---

## How to use in Cursor

1. Open a workspace with your N64 decomp or recomp project (or create one with splat).
2. Start an **Agent** chat.
3. **Attach** the `n64-decomp` skill or describe a matching task (splat setup, BSS yaml, overlay `jalr` crash, Ghidra jump table, first asm match).
4. Example prompts:
   - *“I have baserom.n64 — walk me through splat setup and gitignore.”*
   - *“Splat split done — next step for first matching ROM before libultra?”*
   - *“N64Recomp found entrypoint but crashes on indirect call with overlays.”*
   - *“Ghidra put a function boundary in my jump table at 0x8012A400 — verify before symbol_addrs.”*

The agent should follow **your** ROM evidence and bundled `references/` — not invent TOML keys, APIs, or boundaries.

### Quick matching path (after split)

```bash
uv run -m splat create_config baserom.n64
uv run -m splat split <game>.yaml
python references/configure_min.py --emit-configure --game <game>
# Add <game>.ld from splat, then:
python configure.py --clean && python configure.py --build
```

Wrong BSS in `asm/1000.s`? Fix `bss_size` / `.bss` in yaml and re-split — **do not** hand-edit generated `asm/*.s`.

---

## Skill layout

```
n64-decomp/
├── README.md
├── LICENSE
├── SKILL.md
├── evals/
│   ├── evals.json
│   └── eval_set_trigger.json
├── references/
│   ├── splat-setup.md
│   ├── build-system.md
│   ├── configure_min.py
│   ├── environment-setup.md
│   ├── ghidra-mcp.md
│   ├── function-discovery.md
│   ├── libultra.md
│   ├── custom-runtime.md
│   ├── compiler-and-c.md
│   └── n64recomp.md
```

---

## Skill vs `.skill` vs your game repo

| Artifact | Purpose |
|----------|---------|
| **This Git repo** | Source for `SKILL.md`, references, README; clone to contribute |
| **Release `n64-decomp.skill`** | Pre-built ZIP for Cursor install |
| **Skill folder** (after install) | Live copy the agent reads |
| **Your decomp/recomp project** | ROM, yaml, asm, TOML, runtime — always separate |

---

## Development / evals

Built with the **skill-creator** workflow (iterations 1–6 under `n64-decomp-workspace/`, not shipped in `.skill`). Iteration 6: with_skill **100%**, baseline **85.7%** on heuristic assertions.

To improve: edit `SKILL.md` or `references/`, re-run evals, repackage with `package_skill.py`.

---

## License and legal

- Skill text: **MIT** (this repo).
- You must **own** any N64 software you analyze or recompile. Do not distribute copyrighted ROMs, SDK leaks, or redistributable game assets. The skill will not request ROM files.

---

## Links

- **Releases (`.skill` download):** https://github.com/DohmBoy64Bit/n64-decomp-skill/releases
- [splat / splat64](https://github.com/ethteck/splat)
- [N64Recomp](https://github.com/N64Recomp/N64Recomp)
- [bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp)
- Related: [pcrecomp-skill](https://github.com/DohmBoy64Bit/pcrecomp-skill), [xboxrecomp-skill](https://github.com/DohmBoy64Bit/xboxrecomp-skill)
