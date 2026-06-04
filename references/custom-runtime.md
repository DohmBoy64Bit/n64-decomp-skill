# Custom Runtime / No-Libultra Games

Read this when n64sym, ultralib comparison, or `os*` hunting does not reveal a clear libultra block, or the game uses a custom engine, modified SDK, or direct hardware access.

Do not force libultra names without proof. Identify runtime services by behavior.

## Runtime Boundaries (Replace "Find libultra")

Classify functions by behavior:

- boot/entry, BSS clear, stack/thread setup
- scheduler loop, message/event queues
- ROM/PI DMA, overlay loading
- graphics/audio task submission
- VI/framebuffer swap
- controller/SI/PIF, save EEPROM/SRAM/Flash/Controller Pak
- RSP/RDP status polling, interrupt/timer handling

Goal: find where CPU game logic crosses into hardware behavior.

## Direct Hardware Register Search

```text
0xA4040000 SP
0xA4100000 DP/RDP
0xA4300000 MI
0xA4400000 VI
0xA4500000 AI
0xA4600000 PI
0xA4800000 SI
```

Name by behavior:

```text
custom_pi_start_dma
custom_rsp_submit_task
custom_vi_swap_buffer
custom_ai_submit_buffer
custom_si_read_controllers
custom_save_read / custom_save_write
custom_wait_for_sp / custom_wait_for_pi
custom_overlay_load
```

## Per-Function Treatment

1. **Recompile normally** — gameplay, math, actors, camera, collision, menus, animation, decompression, state machines
2. **Host shim** — PI DMA, controllers, saves, audio buffers, VI swap, RSP tasks, overlay registration
3. **Narrow patch** — hardware busy-waits, irrelevant cache ops, CIC waits, RCP polling that hangs, impossible timing loops

Do not add broad null guards without guest proof.

## N64Recomp Naming

Accurate boundaries matter more than libultra names:

```text
good: custom_pi_dma_copy, engine_submit_rsp_task, game_wait_for_vi
bad:  maybe_osPiStartDma, unknown_libultra_func, random_guard_func
```

## Debugging Questions

```text
Where does this function touch hardware?
Which MMIO register?
Does it start DMA or submit an RSP task?
Does it wait on SP/PI/VI/AI status?
Does it signal a queue or completion flag?
Does the host runtime already model this?
```

If not, add a host shim or narrow patch. Keep original CPU/game logic recompiled when possible.
