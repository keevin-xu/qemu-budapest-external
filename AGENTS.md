# AGENTS.md

## Project Goal

This repository is part of the Budapest MCU emulation effort. The long-term goal
is to build an emulator that can validate real bootrom behavior before running on
hardware.

The intended QEMU workflow is:

1. Externally compile the real bootrom into an ELF/bin/o file.
2. Load binary into the custom QEMU machine.
3. Run it against a firmware-visible MCU model.
4. Validate reset, boot, flash/NVM access, protection, and handoff behavior.

Do not treat this as only a Cortex-M CPU emulation task. The CPU core is the
easy part. The useful work is modeling the MCU-specific memory map, boot
environment, flash controller behavior, protection state, and peripherals closely
enough that bootrom decisions are meaningful.

## Project Overview

This is a QEMU-based Budapest MCU model used to run and validate real bootrom
code before hardware is available. The emulator should behave like firmware sees
the MCU, especially during reset, boot configuration, flash/NVM access,
protection checks, and handoff to user firmware.

The project is not trying to be a perfect electrical or cycle-accurate model at
this stage. The priority is a bootrom-useful machine:

- load a compiled bootrom or firmware image
- expose the expected memory map and reset state
- model flash, EEPROM, NVR, and protection behavior accurately enough for
  bootrom decisions
- provide register-level peripheral behavior where bootrom or early firmware
  reads, writes, polls, or depends on it
- keep placeholders explicit when hardware behavior is not yet known

The source tree may be used from an outer QEMU checkout with `hw/arm/budapest`
as a nested Budapest implementation. Treat the nested Budapest directory as the
authoritative place for the custom machine code, and check both the outer repo
and nested repo status before committing.

## QEMU Direction

There is already a base QEMU version in this repository. A fresh Codex
instance working on QEMU should focus on the QEMU machine/device implementation,
not on porting every Renode detail line-for-line.

Use this repository mainly as context for:

- the intended Budapest MCU bootrom validation workflow
- current assumptions about flash and EEPROM behavior
- the kind of register-level peripheral models we want
- test expectations that may later be mirrored in QEMU

Avoid overfitting to Renode-specific structure. QEMU implementation should use
normal QEMU machine, memory region, device, MMIO, reset, IRQ, and migration
patterns.

## Current QEMU Handoff Notes

Fresh Codex instances should first inspect the current Budapest implementation
before proposing a design. The Budapest code is intentionally local to
`hw/arm/budapest` and currently uses this shape:

- `core/` contains the board and SoC glue.
- `peripherals/` contains individual MMIO device models and headers.
- `meson.build` is the source list for the Budapest machine.
- `README.md` records the current modeled status and known gaps.

The SoC is the central composition point. It creates child devices, maps their
MMIO windows, connects IRQs to the Cortex-M NVIC, and wires the few modeled
cross-peripheral relationships. Most peripherals are still self-contained MMIO
models with local register state. Do not assume that a register write in one
peripheral already affects another peripheral unless the connection is explicit
in `core/tle9855_soc.c` or the relevant peripheral source.

Currently modeled cross-peripheral behavior is concentrated in flash, EEPROM,
NVR, and EFC:

- EFC commands operate on the flash and NVR models.
- Flash protection, passwords, and BSL/CL/DL/DN layout are derived from NVR.
- NVR direct access is gated by the CL password token.
- EEPROM is modeled as the final 8 KB DN subrange of the same flash array.

Many other cross-peripheral effects are placeholders or local approximations:

- Peripheral IRQs are mostly wired directly to NVIC instead of through a full
  SCU interrupt aggregation model.
- SCU clock changes do not yet dynamically retime all dependent peripherals.
- ADC values, SPI/SSC external transfers, pin muxing, and analog behavior are
  not complete hardware models unless a source file clearly says otherwise.
- Stub MMIO regions may return fixed values or ignore writes.

When taking over a context handoff, check the implementation state with
`git status`, inspect `hw/arm/budapest/README.md`, and read the touched source
files instead of relying only on previous chat summaries.

## Current Budapest Memory Model

The current model includes these bootrom-relevant memory areas:

- Flash: `0x11000000-0x1101ffff`, 128 KB.
- EEPROM emulation: `0x1101e000-0x1101ffff`, final 8 KB of flash.
- NVR register sector: `0x11020000-0x110207ff`, 2 KB.
- SRAM: modeled by the SoC memory map.

Flash and EEPROM are not a generic QEMU pflash device. They are a custom
Budapest flash model so project-specific protection, password, erase, and
EEPROM protected-word behavior can be represented.

Important caveat: runtime flash read protection affects instruction fetches.
Bytes loaded with `-kernel` can exist in the flash backing array but still read
as erased-looking data until the modeled protection state allows access. If a
firmware smoke test unexpectedly fails at reset, check whether the test needs a
bootrom/unlock path, a loader bypass, or different protection defaults.

## Hardware Basis

The emulated peripherals should be based on the Infineon TLE9854 family.

### Highest-Priority Address Sources

Before using a datasheet, user manual, SDK header, Renode model, or existing
QEMU constant for an address, inspect these project files:

- `hw/arm/budapest/peripherals/budapest.repl` is the highest-priority source
  for Budapest block locations, peripheral base addresses, mapped memory
  regions, and intentionally retained stub regions.
- `hw/arm/budapest/peripherals/peripherals.txt` is the highest-priority source
  for Budapest peripheral register names, register ordering, and register
  offsets within each block.

These two files override generic TLE9854/TLE985x documentation and existing
implementation constants when addresses or register layouts disagree. Record
such conflicts in `hw/arm/budapest/docs/implementation/address-map-audit.md`.
They do not by themselves define reset values, field masks, access types, or
side effects; use Budapest design specifications and the supplied hardware
manual sections for those behaviors. Do not infer undocumented behavior from a
register name or location.

The user will provide hardware documents as needed. Use Budapest project design
specs as the first source of truth for implementation decisions. If no relevant
Budapest design spec or project-specific model exists for the behavior being
implemented, use the TLE9854/TLE985x references. If Budapest docs contradict
generic TLE documentation, follow the Budapest docs and document the
project-specific choice in the relevant spec, behavior doc, or code comment.

Primary references, in priority order:

- `hw/arm/budapest/peripherals/budapest.repl` for block locations and bases
- `hw/arm/budapest/peripherals/peripherals.txt` for register maps and offsets
- Budapest digital design specifications and project-specific model docs
- TLE9854 datasheet
- TLE985x/TLE9854 user manual
- TLE9854 firmware/user firmware documentation, if needed
- Infineon SDK/DFP files, if useful for register names, reset values, startup
  code, linker layout, or firmware-visible constants

When implementing a peripheral, prefer the hardware manuals over assumptions.
Match firmware-visible behavior first:

- register addresses and offsets
- reset values
- read-only/write-only behavior
- write-one-to-clear behavior
- reserved-bit behavior
- side effects on reads and writes
- busy/done/error status transitions
- IRQ/status behavior
- reset and clock dependencies where bootrom-visible
- memory protection and authentication behavior

Cycle accuracy, analog accuracy, and exact electrical behavior are not the first
goal unless a bootrom check depends on them.

## Bootrom Validation Priorities

The emulator should support the bootrom path first. Prioritize hardware features
that the bootrom reads, writes, polls, or depends on during startup.

High-priority areas:

- reset vector and initial memory map
- bootrom ROM/load region
- SRAM
- flash memory region
- flash controller / embedded flash controller
- NVR/config region
- EEPROM-emulation behavior
- password/protection registers
- boot mode / startup configuration registers
- reset and clock-control registers needed by early boot
- watchdog behavior needed to avoid false failures
- UART/LIN/GPIO only to the extent bootrom uses them

Lower-priority areas:

- detailed analog behavior
- complete peripheral signal routing
- full alternate-function pin muxing
- exact timing unless firmware polls timing-dependent status
- peripherals unused by the bootrom path

## Flash and EEPROM Model

Flash and EEPROM emulation are intentionally project-specific and should not be
blindly copied from generic TLE9854 behavior.

Current model expectations:

- Flash capacity is 128 KB.
- Erased flash bytes read as `0xFF`.
- Programming can only change bits from `1` to `0`.
- Erase changes bits back to `1`.
- Flash is divided into protected regions.
- Protected regions require the correct password before read/write/erase.
- Password attempts are one-shot for protected accesses where modeled.
- The last 8 KB of flash is used for EEPROM emulation.
- EEPROM emulation is divided into 16 sectors.
- Each EEPROM sector has 64 words.
- Each EEPROM word is 8 bytes.
- Words 62 and 63 in every EEPROM sector are protected and must reject
  read/write/erase access.

## Peripheral Modeling Style (can change)

- define named register offsets
- define named reset values and bit masks
- keep register backing state explicit
- make side effects obvious in helper functions
- separate raw register storage from modeled hardware behavior
- add tests for every behavior that bootrom depends on

## Testing Expectations (secondary focus)

Every new QEMU behavior should have a way to validate it.

Useful test layers:

- direct device/unit tests where practical
- QEMU qtests for MMIO register behavior
- bootrom smoke tests using a compiled ELF
- firmware-visible tests for flash read/write/erase/protection
- regression tests for invalid/protected access
- trace/log checks for bootrom handoff and fault paths

For bootrom validation, prefer tests that prove what firmware observes:

- register read values
- status transitions after commands
- memory contents after write/erase
- errors on protected access
- reset-state correctness
- expected PC/SP/vector behavior
- handoff to user firmware

## Working Notes for Future Agents

- Ask for or inspect the relevant manual section before implementing a new
  peripheral.
- Keep the model incremental and bootrom-driven.
- Do not invent undocumented behavior unless it is explicitly labeled as a
  placeholder.
- When using placeholder behavior, document what real dependency is missing.
- Keep flash/EEPROM protection rules centralized and tested.
- Keep bootrom ELF loading as a first-class workflow.
- Prefer QEMU-native design patterns over Renode-specific patterns.
- ask if you need more clarifaction (ex: ask for documents)
