# Development Environment Check and Dependency Setup

Read this when starting a new split, recompilation, Ghidra/N64LoaderWV/GhidraMCP session, or host build. Verify tools before installing. Install only what the current phase needs. MCP client wiring: `15-mcp-client-setup.md`.

## Core Tool Checks

Record important versions in `AGENTS.md` when the project becomes repeatable.

### Windows PowerShell

```powershell
git --version
cmake --version
ninja --version
python --version
py --version
uv --version
java -version
mvn -version
where git
where cmake
where ninja
where python
where uv
where java
where mvn
where clang
where cl
where ghidraRun
```

### Linux / WSL

```bash
git --version
cmake --version
ninja --version
python3 --version
uv --version
java -version
mvn -version
which git cmake ninja python3 uv java mvn clang gcc rg readelf objdump || true
which mips-linux-gnu-readelf mips-linux-gnu-objdump mips-linux-gnu-as mips-linux-gnu-ld || true
```

## Windows Dependency Setup

Use a Visual Studio x64 Developer PowerShell or Developer Command Prompt for MSVC C/C++ builds.

Example `winget` installs (if available):

```powershell
winget install --id Git.Git -e
winget install --id Kitware.CMake -e
winget install --id Ninja-build.Ninja -e
winget install --id Python.Python.3.12 -e
winget install --id EclipseAdoptium.Temurin.21.JDK -e
winget install --id Apache.Maven -e
winget install --id LLVM.LLVM -e
winget install --id Microsoft.VisualStudio.2022.BuildTools -e
```

After Visual Studio Build Tools, ensure **Desktop development with C++**, MSVC v143+, Windows 10/11 SDK, and optionally CMake tools for Windows.

For Ghidra, keep the install path explicit (e.g. `C:\ghidra_12.1_PUBLIC`) — GhidraMCP setup needs `--ghidra-path`.

## Linux / WSL Dependency Setup

```bash
sudo apt update
sudo apt install -y \
  build-essential git cmake ninja-build python3 python3-venv python3-pip pipx \
  curl jq unzip ripgrep openjdk-21-jdk maven clang lld \
  binutils-mips-linux-gnu gcc-mips-linux-gnu g++-mips-linux-gnu

python3 -m pipx ensurepath || true
python3 -m pipx install uv || true
```

MIPS cross-binutils help inspect MIPS ELFs and validate symbols. Linux MIPS ABI output is not the N64 runtime ABI — matching still needs the correct compiler, linker script, endianness, and section layout.

## Python Analysis Dependencies

Prefer a project-local `uv` environment:

```bash
uv init --bare
uv add "splat64[mips]" spimdisasm rabbitizer capstone pyelftools tomlkit
```

Without `uv`:

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# Linux/WSL: source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install "splat64[mips]" spimdisasm rabbitizer capstone pyelftools tomlkit
```

## Recompilation Stack Checks

```bash
git submodule status || true
cmake --version
ninja --version
python --version || python3 --version
```

Prefer recursive clones and record pinned commits:

```bash
git clone --recursive https://github.com/N64Recomp/N64Recomp.git external/N64Recomp
git clone --recursive https://github.com/N64Recomp/N64ModernRuntime.git external/N64ModernRuntime
git -C external/N64Recomp rev-parse HEAD
git -C external/N64ModernRuntime rev-parse HEAD
```

If cloned without submodules:

```bash
git -C external/N64Recomp submodule update --init --recursive
git -C external/N64ModernRuntime submodule update --init --recursive
```

## Dependency Documentation Rule

When setup works, document in `AGENTS.md`:

```text
OS and shell
Tool versions
Compiler and generator
Ghidra version and install path
N64LoaderWV extension version (https://github.com/zeroKilo/N64LoaderWV)
GhidraMCP repository path and plugin version/commit
MCP host and config path (15-mcp-client-setup.md)
RMG MCP path (optional, 14-rmg-mcp-playbook.md)
N64Recomp/N64ModernRuntime/RT64 commits
Python environment command
Build/split/recomp/run commands
```
