# n64-decomp — description review

## Current description (summary)

**Strengths**

- Explicit “use whenever” + casual trigger phrases (`split my ROM`, `N64Recomp won't boot`).
- Broad coverage: splat, libultra, custom runtime, N64Recomp/RT64, GhidraMCP, address discipline.
- Keyword tail for retrieval: N64, splat, overlays, RSP, DMA, etc.

**Weaknesses**

| Issue | Impact |
|--------|--------|
| **Too long** (~120 words + duplicate keyword list) | Harder for the model to scan; tail repeats “Triggers on …” after already listing coverage |
| **Missing high-signal phrases** from evals | `configure_min`, `bss_size`, `first matching ROM`, `asm/` after split, `matching build`, `symbol_addrs`, `bethington` |
| **Weak negative boundary** | Only implicit; near-misses (Dolphin “Mario 64”, MIPS router, RetroArch VI) not ruled out |
| **“assistant” + encyclopedic list** | Reads like docs, not a trigger hook |
| **Unicode em dashes in YAML** | Can corrupt in tooling (`â€"` in JSON export) — use ASCII `-` in frontmatter |

## Automated trigger test

`scripts.run_eval` was run with `evals/eval_set_trigger.json` (15 should-trigger, 10 should-not-trigger).

- **Result:** 10/25 “passed” — **misleading**
- All queries hit `[WinError 10038]` (socket); trigger rate = 0 for every query
- Should-**not**-trigger cases “passed” only because 0% &lt; 50% threshold
- **Do not treat** `trigger_eval_current.json` as real trigger scores

Re-run when: `claude -p` works from `e:\SkillDev\N64decomp` with `--num-workers 1`, or use `run_loop.py` on a machine without the socket issue.

## Eval set for your review

- **JSON:** `evals/eval_set_trigger.json` (25 queries)
- **HTML editor:** `evals/description_review.html` — open in browser, edit toggles, Export Eval Set

## Recommended description (replace frontmatter)

See updated `SKILL.md` frontmatter — changes:

1. Lead with **matching decomp + N64Recomp ports** (the two main workflows).
2. Front-load **configure_min**, **BSS/yaml**, **first matching ROM**, **asm/ after split**.
3. One short **Not for** line (Xbox/pcrecomp, SNES/GC emu, generic MIPS, RetroArch-only).
4. Drop redundant trailing “Triggers on …” keyword dump (covered by inline phrases).

## Next steps

1. Open `evals/description_review.html` and adjust queries if anything looks wrong.
2. Re-run `run_eval` / `run_loop` when CLI trigger tests work (optional).
3. Install skill where agents load skills; confirm it appears in `available_skills`.

```powershell
cd C:\Users\SeanS\.agents\skills\skill-creator
cd e:\SkillDev\N64decomp
python -m scripts.run_eval `
  --eval-set evals\eval_set_trigger.json `
  --skill-path e:\SkillDev\N64decomp `
  --runs-per-query 3 --num-workers 1 --timeout 120 --verbose `
  | Out-File evals\trigger_eval_rerun.json -Encoding utf8
```
