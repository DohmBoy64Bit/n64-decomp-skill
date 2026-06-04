# Identifying libultra

Read this when n64sym or ultralib comparison suggests a standard libultra block in the ROM.

## Find Version

Check `asm/header.s` for revision:

```asm
.word 0x00001448       /* Revision */
```

The byte (0x48 = 'H') encodes SDK version as ASCII (E=2.0E … L=2.0L). See https://n64brew.dev/wiki/Libultra

## Setup

```bash
git clone https://github.com/decompals/ultralib
rm -rf ultralib/.git
uv add git+https://github.com/matt-kempster/m2c
```

Download ultralib into the project and commit it (remove `.git` — not a submodule). Do not add ultralib to `.gitignore`.

Update `configure.py` includes:

```python
INCLUDES = "-I include -I ultralib/include -I ultralib/include/PR"
```

## n64sym Hints First

Ask the user to run n64sym and paste output: https://shygoo.github.io/n64sym/web/

Use output to estimate where libultra might start/end and which functions might be present.

**n64sym is unreliable** — pattern-matches known binaries. Never add symbols directly; use only as location hints.

## Find Boundaries

Do not read raw asm files — use m2c:

```bash
uv run m2c asm/<file>.s
```

1. **Start**: From n64sym hints, m2c candidates and compare to ultralib. When matched, rename in yaml: `[0xA0CD0, asm, libultra/A0CD0]`
2. **End**: Same for last libultra function
3. **Rename all files** in the libultra range in yaml subsegments
4. **Rebuild** to verify match

Libultra is typically one continuous block.

## Identify Called Functions

```bash
rg "jal.*0x800[a-f]" asm/
```

Identify every unique libultra function called from game code — game code needs their signatures.

## Add Symbols Module-by-Module

For each called function:

1. m2c the file at that address
2. Match to ultralib source
3. Add symbol to `symbol_addrs.txt` (text symbols before data)
4. Rebuild and verify

Symbol syntax: https://github.com/ethteck/splat/wiki/Adding-Symbols

Do not stop until all proven libultra calls are identified. If libultra is missing or unrecognizable, switch to [custom-runtime.md](custom-runtime.md).

Checkpoint: verify match, commit, then compiler identification or custom-runtime boundary mapping.
