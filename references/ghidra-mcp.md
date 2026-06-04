# GhidraMCP Setup and Evidence Protocol

Read this when function boundaries, XREFs, hardware accesses, overlays, or jump targets need Ghidra evidence, or when setting up bethington/ghidra-mcp for Cursor, Codex, OpenCode, Claude, or other MCP clients.

Preferred implementation: https://github.com/bethington/ghidra-mcp

## Setup Checklist

```text
[ ] Ghidra installed — which version?
[ ] Target N64 ROM/program imported and analyzed?
[ ] GhidraMCP extension installed?
[ ] Plugin enabled in CodeBrowser?
[ ] MCP server started in Ghidra?
[ ] http://127.0.0.1:8089/check_connection responds?
[ ] Python bridge installed and runnable?
[ ] MCP client identified (Cursor, Codex, OpenCode, Claude, other)?
[ ] Client has ghidra MCP server entry?
```

If GhidraMCP is running, use it for focused evidence. If not, install only missing pieces.

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

Use the format and path for the user's editor. Do not invent config paths.

Generic stdio:

```json
{
  "mcpServers": {
    "ghidra": {
      "command": "python",
      "args": ["C:/path/to/ghidra-mcp/bridge_mcp_ghidra.py"]
    }
  }
}
```

Cursor-style (`~/.cursor/mcp.json` or workspace MCP):

```json
{
  "mcpServers": {
    "ghidra": {
      "command": "uv",
      "args": ["run", "--script", "C:/path/to/ghidra-mcp/bridge_mcp_ghidra.py"]
    }
  }
}
```

Codex TOML:

```toml
[mcp_servers.ghidra]
command = "python"
args = ["C:/path/to/ghidra-mcp/bridge_mcp_ghidra.py"]
```

HTTP transport:

```bash
python bridge_mcp_ghidra.py --transport streamable-http --mcp-host 127.0.0.1 --mcp-port 8081
```

```json
{
  "mcpServers": {
    "ghidra-mcp-http": {
      "url": "http://127.0.0.1:8081/mcp"
    }
  }
}
```

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
