# GhidraMCP Setup and Evidence Protocol

Read this when function boundaries, XREFs, hardware accesses, overlays, or jump targets need Ghidra evidence, or when setting up bethington/ghidra-mcp.

**MCP client wiring (Cursor, Claude, Codex, VS Code, any host):** `15-mcp-client-setup.md` — client-agnostic autoconfig for `ghidra` + optional `rmg-n64-debugger`.

Preferred GhidraMCP implementation: https://github.com/bethington/ghidra-mcp

**Recommended N64 ROM loader:** [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV) — import `.z64` / `.n64` / `.v64` with correct endianness and RAM/ROM/boot layout before analysis or MCP evidence.

## N64LoaderWV — Load ROM First

Without a correct MIPS N64 program, GhidraMCP returns garbage (wrong arch, wrong segment base, or empty memory at guest VRAM).

### Install

```text
1. Download release ZIP from https://github.com/zeroKilo/N64LoaderWV/releases
   (pick a build matching your Ghidra major version when possible)
2. Ghidra → File → Install Extensions… → + → select ZIP → restart
3. File → Configure → Configure All Plugins → enable N64LoaderWV
```

Build from source (JDK 17+, Gradle): clone repo, set `GHIDRA_INSTALL_DIR`, run `gradle`, install ZIP from `dist/`. See [N64LoaderWV README](https://github.com/zeroKilo/N64LoaderWV).

### Import ROM

```text
1. File → Import File → baserom.z64 (or .n64 / .v64 from splat byteswap)
2. Loader: N64 ROM (N64LoaderWV) — NOT generic Binary / wrong platform
3. Auto-analyze; confirm Language = MIPS big-endian 64-bit (typical retail)
4. Cross-check segment map against splat yaml before trusting VRAM addresses
```

### Optional symbol hint files

N64LoaderWV supports pattern/signature files (`example_n64sym.txt`, `example_signatures.txt` in the repo). Treat output as **hints only** — same confidence gate as n64sym (`06-libultra.md`, `13-decisional-brain.md`). Ledger + raw MIPS before `symbol_addrs`.

Record Ghidra version, N64LoaderWV version, and program name in `N64_PROJECT_STATE.md`.

**Tested stack (example):** Ghidra **12.0.4** (or 12.1+) + N64LoaderWV + bethington/ghidra-mcp — pick N64LoaderWV build matching Ghidra major version when possible.

## Static Analysis Workflow — baserom, Overlays, Pre-Recomp Boundaries

Primary **static** tool before N64Recomp metadata and before promoting symbols. Complements CDB host traces (`16-cdb-debug-playbook.md`) and optional RMG guest debug (`14-rmg-mcp-playbook.md`).

### 1. Import and segment sanity

```text
1. Import baserom.z64 with N64LoaderWV (not generic Binary)
2. Compare memory block list / segment starts to splat yaml VRAM and ROM ranges
3. Record mismatches in N64_PROJECT_STATE.md mapping table before naming functions
```

### 2. Function boundaries (before recomp / symbol_addrs)

For each candidate function:

```text
1. Raw Listing disassembly — prologue, epilogue, control flow
2. Decompiler — structure hint only; not promotion evidence
3. Callers / callees / XREFs — who branches here?
4. Delay slots — branch+slot pairs intact?
5. Data end — next symbol is code or rodata?
```

Ledger entry in `docs/function_ledger.md` (`05-function-discovery.md`) before bulk yaml `symbol_addrs` or N64Recomp symbol files.

### 3. Overlay dispatch tables

High-value Ghidra targets for overlay games:

```text
- ROM/VROM tables mapping overlay id → load address / size
- DMA or PI routines that copy overlay segments into RDRAM
- jalr / indirect call sites fed by table lookups
- Functions that switch current overlay context (registration analog on host)
```

GhidraMCP recipe:

```text
1. get_xrefs_to on known table address (from splat segment or header)
2. disassemble at table entries — pointer pairs, not mistaken as separate functions
3. inspect_memory_content at VRAM where table points after documented load
4. Cross-link table row → overlay name in docs/overlay_ledger.md (create if missing)
```

Never feed tentative table parsing into N64Recomp TOML without delay-slot and load-routine proof.

### 4. Handoff to recomp and runtime

```text
Ghidra (static)     → boundaries, overlay tables, jump tables, MMIO sites
splat yaml          → segments, bss, symbol_addrs promotion
N64Recomp TOML      → codegen input
CDB (16)            → prove host recomp EXE hits/bypasses translated paths
RMG MCP (14)        → optional guest RDRAM proof
```

### 5. Ghidra session checklist (pre-MCP)

```text
[ ] baserom.z64 imported with N64LoaderWV
[ ] Language = MIPS BE 64-bit (typical retail)
[ ] Auto-analysis finished
[ ] Segment bases match splat yaml (or deltas documented)
[ ] Overlay tables bookmarked / labeled in program tree
[ ] GhidraMCP server started; check_connection OK
```

## Setup Checklist

```text
[ ] Ghidra installed — which version?
[ ] N64LoaderWV extension installed?
[ ] Target N64 ROM imported with N64LoaderWV (MIPS, correct endianness)?
[ ] Auto-analysis complete on the N64 program?
[ ] GhidraMCP extension installed?
[ ] Plugin enabled in CodeBrowser?
[ ] MCP server started in Ghidra?
[ ] http://127.0.0.1:8089/check_connection responds?
[ ] Python bridge installed and runnable?
[ ] MCP client identified — see 15-mcp-client-setup.md?
[ ] Client has `ghidra` MCP server entry (stdio or HTTP)?
[ ] MCP `check_connection` / `instances_list` shows this N64 program?
```

If GhidraMCP is running on the correct N64 program, use it for focused evidence. If not, install only missing pieces (loader before plugin).

## Install From Source

Prerequisites:

```text
Java 21 LTS
Apache Maven 3.9+
Ghidra 12.1 or compatible
Python 3.10+ with pip
```

Windows:

```powershell
git clone https://github.com/bethington/ghidra-mcp.git external/ghidra-mcp
cd external/ghidra-mcp

python -m tools.setup preflight --ghidra-path "C:\ghidra_12.1_PUBLIC"
python -m tools.setup ensure-prereqs --ghidra-path "C:\ghidra_12.1_PUBLIC"
python -m tools.setup build
python -m tools.setup deploy --ghidra-path "C:\ghidra_12.1_PUBLIC"
```

Linux / WSL:

```bash
git clone https://github.com/bethington/ghidra-mcp.git external/ghidra-mcp
cd external/ghidra-mcp

sudo apt update
sudo apt install -y openjdk-21-jdk maven python3 python3-pip curl jq unzip

python -m tools.setup preflight --ghidra-path ~/ghidra_12.1_PUBLIC
python -m tools.setup ensure-prereqs --ghidra-path ~/ghidra_12.1_PUBLIC
python -m tools.setup build
python -m tools.setup deploy --ghidra-path ~/ghidra_12.1_PUBLIC
```

Release ZIP path:

```text
1. Download matching GhidraMCP release ZIP.
2. Ghidra: File > Install Extensions > Add ZIP.
3. Restart Ghidra.
4. File > Configure > Configure All Plugins > GhidraMCP.
5. Tools > GhidraMCP > Start MCP Server.
6. python -m pip install -r requirements.txt
7. python bridge_mcp_ghidra.py
```

## Start and Verify

```text
File > Configure > Configure All Plugins > GhidraMCP
Edit > Tool Options > GhidraMCP HTTP Server
Tools > GhidraMCP > Start MCP Server
```

```bash
curl http://127.0.0.1:8089/check_connection
curl http://127.0.0.1:8089/get_version
```

If health checks fail, fix plugin/server/bridge/client before broad analysis.

## MCP Client Configuration

**Canonical guide:** `15-mcp-client-setup.md` — discover host (Cursor, Claude Desktop, VS Code, Codex, OpenCode, …), set absolute `GHIDRA_MCP_BRIDGE` path, server id `ghidra`, verify with `check_connection`.

**Template:** `examples/mcp-servers.template.json` (ghidra + optional rmg-n64-debugger).

Quick stdio shape (paths must be absolute on the user's machine):

```json
{
  "mcpServers": {
    "ghidra": {
      "command": "python",
      "args": ["<GHIDRA_MCP_BRIDGE>"]
    }
  }
}
```

HTTP transport (optional): start `bridge_mcp_ghidra.py --transport streamable-http --mcp-host 127.0.0.1 --mcp-port 8081`, then `"url": "http://127.0.0.1:8081/mcp"`. Ghidra plugin HTTP (`8089`) must still be running separately.

## Safe Usage

- Bind to loopback for local dev.
- Do not expose to LAN/internet without auth and file-root restrictions.
- Prefer read-only evidence before renaming, typing, or scripting.
- Document any write operations performed.

## Evidence Protocol

Do not trust decompiler output alone — use raw MIPS, XREFs, branch targets, delay slots, segment mapping, and runtime traces.

Narrow request template:

```text
GhidraMCP Evidence Needed:
Target:
Tool(s):
Expected evidence:
Why it matters:
Fallback if MCP unavailable:
```

Prefer: raw MIPS disassembly, decompiler for structure only, callers/callees/XREFs, delay-slot context, hardware register refs, jump tables, overlay loaders, ROM-to-RAM DMA sites, RSP IMEM/DMEM uploads.

Targets: boot/init, DMA, overlay loaders, RSP task builders, display-list producers, audio tasks, save, SI/PIF/controller, MMIO-touching functions.

Common Ghidra issues:

```text
Wrong function boundaries
Missed branch-delay-slot effects
Bad signedness / fake structs
Code/data confusion
Jump tables mistaken for pointers
Overlay calls treated as invalid
Hardware regs shown as globals
RSP/RDP data treated as CPU data
```

## Fallback Without GhidraMCP

Produce the same evidence shape with narrower tools:

- `readelf` — ELF headers, sections, symbols, relocations
- `objdump` / `mips-linux-gnu-objdump` — disassembly
- `pyelftools` — scripted ELF inspection
- `capstone` — raw-byte disassembly from ROM ranges
- `rabbitizer`, `spimdisasm`, `splat` — N64-aware disassembly and mapping
- `rg`, `xxd`, small Python scripts — constants, strings, patterns

Fallback output shape:

```text
Target:
Tool used:
Raw disassembly:
Function start/end:
Callers/callees:
Branch targets / delay slots:
Hardware constants:
ROM/VROM/VRAM/RDRAM mapping:
Confidence:
What still needs Ghidra or runtime trace:
```

Tool selection:

```text
GhidraMCP: boundaries, XREFs, jump tables, overlay loaders, hardware XREFs
Capstone: quick raw disassembly from ROM bytes
pyelftools: ELF metadata, FUNC/OBJECT symbols, relocations
readelf/objdump: shell-friendly checks
rabbitizer/spimdisasm/splat: N64 MIPS and split workflows
```

Fallback output is not stronger than raw MIPS control-flow proof.
