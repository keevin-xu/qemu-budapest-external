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

## Hardware Basis

The emulated peripherals should be based on the Infineon TLE9854 family.

The user will provide hardware documents as needed. Primary references are:

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
