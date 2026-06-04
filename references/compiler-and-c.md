# Compiler Identification and C Conversion

## Identifying Compiler Version

Compiler type is in splat yaml under `options.compiler`.

### decomp.me Workflow

1. Find a small linear function outside libultra
2. `uv run m2c asm/<file>.s`
3. Guide user to https://decomp.me/new with target assembly, m2c output, called-function signatures, typedefs (s32, u32, etc.)
4. User tries presets until one matches

Prefer simple control flow — fewer branches means fewer equivalent C variants.

### IDO

If compiler is IDO (most common), use the `n64-decomp-ido` skill for asm-processor and build integration.

Compiler downloads: https://github.com/decompme/compilers/blob/main/values.yaml

## Converting to C

Change file type from `asm` to `c` in splat yaml. This generates C stubs and separate `.s` files per function.

Can convert the "identification function" earlier to give the user a single target `.asm` file.
