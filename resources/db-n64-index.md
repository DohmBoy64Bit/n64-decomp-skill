# N64 Knowledge Router (db-n64-index)

**Master router** — load one file per topic; never load all resources at session start.

| Encounter | Load |
|-----------|------|
| uv, splat install, toolchain | `01-environment-setup.md` |
| New splat project, yaml, split, gitignore | `02-splat-setup.md` |
| First matching ROM, BSS, `configure.py` | `03-matching-build.md` |
| Ghidra, N64LoaderWV, GhidraMCP evidence | `04-ghidra-mcp.md` |
| MCP client autoconfig (Ghidra + RMG) | `15-mcp-client-setup.md` |
| Function inventory, jump tables, `symbol_addrs` | `05-function-discovery.md` |
| libultra, n64sym, ultralib | `06-libultra.md` |
| No libultra, direct MMIO | `07-custom-runtime.md` |
| decomp.me, m2c, compiler ID | `08-compiler-and-c.md` |
| N64Recomp, TOML, overlays, RT64, runtime | `09-n64recomp-pipeline.md` |
| Repeated failure, circuit breaker | `10-agent-guardrails.md` |
| "What phase am I in?" | `11-operational-phases.md` |
| Wrong address, DMA, RSP, save, cache | `12-n64-hardware-subsystems.md` |
| Crash triage, debug format, stuck | `13-decisional-brain.md` |
| `configure_min.py` CLI | `scripts/configure_min.py` + `03-matching-build.md` |
| IDO asm-processor integration | **`n64-decomp-ido`** skill (separate) |
| Live RDRAM/registers, trace A/B (optional) | `14-rmg-mcp-playbook.md` |

**Rule:** If you are about to write a fix touching N64 hardware or generated output and have not loaded the row's file **this session** → stop and load it.

**Optional:** Load `14-rmg-mcp-playbook.md` only when the user has RMG MCP or asks for runtime emulator evidence — never instead of GhidraMCP for static boundaries.
