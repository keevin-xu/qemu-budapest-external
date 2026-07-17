# Budapest QEMU Context Handoff

Last updated: 2026-07-15

## Read First

1. Read the root `AGENTS.md` and `hw/arm/budapest/AGENTS.md`.
2. Read `hw/arm/budapest/peripherals/budapest.repl` for authoritative block
   locations and base addresses.
3. Read `hw/arm/budapest/peripherals/peripherals.txt` for authoritative
   register names and offsets.
4. Read `hw/arm/budapest/docs/implementation/address-map-audit.md` for the
   completed comparison and unresolved discrepancies.
5. Check both repositories before editing:

   ```sh
   git status --short
   git -C hw/arm/budapest status --short
   ```

The outer QEMU repository and nested `hw/arm/budapest` repository have separate
Git state. The nested repository is authoritative for Budapest machine code.

## Source Priority

Use the following order:

1. `budapest.repl` for block placement, peripheral bases, memory regions, and
   stub locations.
2. `peripherals.txt` for register names, ordering, and offsets.
3. Budapest digital design specifications and project model documents.
4. User-provided TLE985x/TLE9854 manual sections for reset values, masks,
   access types, side effects, functional behavior, and cross-peripheral rules.
5. SDK/DFP material only as supporting evidence.

The two map files override generic manual addresses. They do not supply enough
information to invent field behavior. Keep unknown behavior explicit.

## Current Implementation State

The machine and SoC composition are in `hw/arm/budapest/core/`. Peripheral MMIO
models are in `hw/arm/budapest/peripherals/`.

Recent source-backed work includes:

- UART, PMU, GPIO, LIN, GPT12E, CCU6, SSC1/2, SCU-DM, SCU-PM, WDT, and WDT1
  register-level behavior and documentation.
- UART/GPIO and PMU/GPIO cross-peripheral qtest scaffolding.
- SCU password protection for selected protected clock, reset, and watchdog
  fields.
- CCU6 software interrupt set/clear and SR0-SR3 `INP` routing.
- SSC register masks, 16-bit buffers, error clearing, and local SSI transfer.
- Centralized test-state dump helpers in
  `hw/arm/budapest/tests/utils/budapest-test-utils.h`.
- External P0/P1 pad inputs, GPIO-to-PMU rising/falling wake generation,
  per-pin/summary status, and Port 2 wake isolation.
- Abstract LIN bus-wake routing through `PMU_LIN_WAKE_EN` into the sourced
  read-clear `PMU_WAKE_STATUS.LIN_WAKE` bit.
- `SCU_PMCON` clock-disable wiring for CCU6, SSC1/2, Timer2, and Timer21.
  CCU6 run bits stop immediately; Timer2/21 freeze and resume; SSC transfers
  are suppressed while gated.
- Source-backed CCU6 `TCTR4` run/reset/shadow commands and hardware-owned
  `TCTR0` run state.

The most recent address-map pass corrected project offsets for:

- CCU6 `PISEL2`, `T12`, `T13`, and `CMPSTAT`.
- PMU registers from `SLEEP` through `WAKE_CNF_GPIO1`.
- PORT P1 and P2 registers.
- SCU registers from `CMCON2` through `IRCON5CLR`.
- SCUPM registers after `AMCLK_CTRL`.

`SCU_MODPISEL3` at `0xb4` is deliberately a zero-read/write-ignored placeholder
because only its location is known.

## Important Remaining Discrepancies

- QEMU now maps the `budapest.repl` 24 KB boot ROM at `0x00000000` and treats
  `-kernel` as the external boot-ROM ELF/raw image. A separate
  `user-firmware=` machine property populates flash at `0x11000000`, while
  `direct-firmware=on` retains the former flash-at-zero compatibility path.
- UART2 is commented out in the REPL body but instantiated in QEMU.
- Flash, NVR, and EFC have REPL locations but no register layouts in
  `peripherals.txt`; retain their project-specific models and specifications.
- APB0 unknown, LS1, LS2, MTIMER, TPTM, LINMAC, and AHB WDT regions have no
  register maps and remain QEMU stubs.
- `CPU_Type` in `peripherals.txt` is handled by QEMU's native Cortex-M/NVIC
  model rather than a custom MMIO device.
- REPL IRQ assignments disagree with current QEMU for ADC1, CCU6, HS, BDRV,
  MATH, LIN, UART1, and SCU. Do not change these without confirming whether the
  REPL is also intended as IRQ authority. Full details are in the address audit.

## Modeling Boundaries

Prioritize firmware-visible functional behavior. The model is not intended to
be electrically or cycle accurate unless bootrom behavior requires timing.

Known broad gaps include:

- real boot-ROM behavior and observed bootrom-to-user-firmware handoff (the
  mapping and external image-loading infrastructure are implemented);
- remaining SCU reset/suspend effects and GPT12/ADC clock-gate behavior;
- SCU interrupt aggregation and several unresolved IRQ assignments;
- electrical GPIO behavior and complete alternate-function routing;
- CCU6 timer counting, compare/PWM/dead-time/trap output generation;
- SSC timing, slave mode, framing execution, and attached external devices;
- watchdog countdown/window timing and CPU reset generation;
- analog ADC and supply-monitor behavior.

Do not implement these from assumptions. Request the relevant Budapest or TLE
documents when firmware-visible behavior is not sourced.

## Next Peripheral Priorities

Prioritize the next peripheral work by what is needed for a functioning,
bootrom-useful emulator. Model firmware-visible functional behavior; do not
spend time on electrical characteristics, analog accuracy, signal waveforms, or
cycle-exact timing unless firmware depends on an observable timing transition.

1. **EFC / Flash / NVR / EEPROM**: complete command state transitions,
   busy/done/error status, MAPRAM and NVR initialization, protection,
   firmware-visible ECC errors, and startup-configuration loading. The Budapest
   eFlash controller specifications are already available in the external
   `important docs` directory; confirm the authoritative revision before use.
2. **SCU-DM / SCU-PM**: complete functional reset causes and propagation,
   peripheral clock enable/gating, startup configuration, wake status, and
   power-mode transitions. The relevant manual sections are already available.
3. **WDT / WDT1**: implement countdown, servicing, window violations, timeout
   status, interrupt/reset generation, and SCU/PMU reset interaction. QEMU
   virtual time is sufficient; exact hardware timing is not required. The
   relevant manual sections are already available.
4. **LIN MAC**: replace the `0xc0008000` stub with register-level transmit,
   receive, break/sync, status, error, interrupt, LIN-transceiver, and PMU-wake
   behavior. Request the Budapest LIN MAC register/behavior specification; the
   available LIN section primarily documents the transceiver.
5. **Timer2 / Timer21**: implement counting, reload, overflow, capture, status,
   and interrupts needed by LIN baud detection and timeouts. Request the
   TLE985x Timer2/Timer21 manual section and any Budapest BSL baud-detection
   specification.
6. **SCU interrupt routing**: route peripheral status through the documented
   SCU interrupt registers to NVIC instead of relying on direct placeholder
   wiring. Request the Budapest interrupt assignment/routing specification if
   SCU-DM does not define it completely.
7. **ADC1 / ADC2**: implement software-triggered conversion, configurable test
   inputs, result/status registers, completion, and interrupts. Do not model
   analog noise or electrical conversion details. Request the ADC1 and ADC2
   manual sections.
8. **GPT12E and CCU6**: add functional counting, compare/capture, overflow,
   status, and interrupt behavior using the already supplied documentation.
9. **SSC1 / SSC2**: add functional transfers, status transitions, loopback or
   attachable test devices, and interrupts without serial waveform accuracy.

Do not prioritize BDRV, HS, MF, detailed GPIO electrical behavior, or other
analog-facing functionality unless a real bootrom trace demonstrates a
firmware-visible dependency.

## Tests

Budapest qtests are registered through outer wrappers in `tests/qtest/` and
implemented under `hw/arm/budapest/tests/`.

The last complete ARM qtest run passed 51 binaries with one unrelated skip.
All eleven Budapest test binaries passed; the PMU Stop/Sleep exit scaffold
remains intentionally skipped.

From the outer repository root:

```sh
./build/pyvenv/bin/meson test -C build \
  qtest-arm/budapest-uart-test \
  qtest-arm/budapest-pmu-test \
  qtest-arm/budapest-gpio-test \
  qtest-arm/budapest-wdt-test \
  qtest-arm/budapest-ccu6-test \
  qtest-arm/budapest-ssc-test \
  qtest-arm/budapest-scu-dm-test \
  qtest-arm/budapest-uart-gpio-test \
  qtest-arm/budapest-pmu-gpio-wake-test \
  qtest-arm/budapest-lin-pmu-wake-test \
  qtest-arm/budapest-scu-peripheral-clock-test \
  --suite qtest-arm --verbose
```

Set `BUDAPEST_TEST_DUMP=1` to enable centralized machine-state dumps in tests
that call `budapest_maybe_dump_state()`.

## Dirty-Tree Cautions

At handoff time, both repositories contain uncommitted work. In particular:

- Outer qtest Meson registration and Budapest wrapper files are modified or
  untracked.
- The nested address-map corrections, tests, documentation, `budapest.repl`,
  and `peripherals.txt` are modified or untracked.
- `.DS_Store` and `docs/.obsidian/workspace.json` are unrelated local changes.
  Do not revert or include them unless explicitly requested.

Review actual status rather than assuming this list is exhaustive. Never reset
or discard existing changes when taking over.
