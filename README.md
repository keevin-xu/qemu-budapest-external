# qemu-tle9854

This project contains a QEMU-based bootrom testing environment for a TLE9854-like Cortex-M0 MCU.

The project layout is:

```text
qemu-tle9854/
├── qemu/              # QEMU source tree with custom TLE9854-like machine
└── bootrom_project/   # Bootrom test firmware
```

The current goal is not to fully emulate the Infineon TLE9854. The goal is to create a working QEMU test environment for bootrom-style firmware: reset flow, vector table behavior, GDB debugging, MMIO reads/writes, and eventually fake TLE9854-like peripherals.

---

## 1. Clone the Repository

```bash
git clone https://github.com/keevin-xu/qemu-tle9854.git
cd qemu-tle9854
```

---

## 2. Build QEMU

Go into the QEMU source folder:

```bash
cd qemu
```

Configure only the ARM system emulator:

```bash
./configure --target-list=arm-softmmu
```

Build QEMU:

```bash
ninja -C build
```

On macOS, the QEMU binary may be:

```text
qemu/build/qemu-system-arm-unsigned
```

On Linux or some other setups, it may be:

```text
qemu/build/qemu-system-arm
```

---

## 3. Check That the TLE9854 Machine Exists

From inside `qemu-tle9854/qemu/`:

```bash
build/qemu-system-arm-unsigned -M help | grep tle
```

or, if the normal binary exists:

```bash
build/qemu-system-arm -M help | grep tle
```

Expected output should include:

```text
tle9854          TLE9854-like machine (Cortex-M0)
```

---

## 4. Build the Bootrom Project

From the project root:

```bash
cd bootrom_project
make clean
make
```

Expected outputs:

```text
bootrom.elf
bootrom.bin
```

If you are currently inside `qemu/`, use:

```bash
cd ../bootrom_project
make clean
make
```

---

## 5. Run the Bootrom in QEMU

From inside `qemu-tle9854/bootrom_project/`:

```bash
../qemu/build/qemu-system-arm-unsigned \
  -M tle9854 \
  -kernel bootrom.elf \
  -nographic \
  -S -s
```

or oneline-version:

```bash
../qemu/build/qemu-system-arm-unsigned -M tle9854 -kernel bootrom.elf -nographic -S -s
```

If your QEMU binary is named normally:

```bash
../qemu/build/qemu-system-arm \
  -M tle9854 \
  -kernel bootrom.elf \
  -nographic \
  -S -s
```

Command meanings:

```text
-M tle9854          use the custom TLE9854-like QEMU machine
-kernel bootrom.elf load the bootrom ELF
-nographic          run without GUI
-S                  pause CPU at startup
-s                  open GDB server on localhost:1234
```

---

## 6. Attach GDB

Open a second terminal:

```bash
cd qemu-tle9854/bootrom_project
arm-none-eabi-gdb bootrom.elf
```

Inside GDB:

```gdb
target remote localhost:1234
break Reset_Handler
break bootrom_main
continue
```

Useful GDB commands:

```gdb
next
step
print/x reset
print/x mode
x/wx 0x40000000
x/wx 0x40000004
quit
```

---

## 7. Stop QEMU and GDB

In GDB:

```gdb
quit
```

If asked to confirm:

```text
y
```

In the QEMU terminal:

```text
Ctrl + A, then X
```

Or use:

```text
Ctrl + C
```

---

## 8. Typical Full Run

From a clean clone:

```bash
git clone https://github.com/keevin-xu/qemu-tle9854.git
cd qemu-tle9854

cd qemu
./configure --target-list=arm-softmmu
ninja -C build

cd ../bootrom_project
make clean
make

../qemu/build/qemu-system-arm-unsigned \
  -M tle9854 \
  -kernel bootrom.elf \
  -nographic \
  -S -s
```

Then in a second terminal:

```bash
cd qemu-tle9854/bootrom_project
arm-none-eabi-gdb bootrom.elf
```

Inside GDB:

```gdb
target remote localhost:1234
break bootrom_main
continue
```

---

## 9. Changing Bootrom Code

Bootrom code lives in:

```text
bootrom_project/
```

After editing bootrom files:

```bash
cd bootrom_project
make clean
make
```

Then rerun QEMU:

```bash
../qemu/build/qemu-system-arm-unsigned \
  -M tle9854 \
  -kernel bootrom.elf \
  -nographic \
  -S -s
```

Commit bootrom changes from the project root:

```bash
cd ..
git status
git add bootrom_project
git commit -m "Update bootrom test program"
git push
```

---

## 10. Changing QEMU Code

QEMU source lives in:

```text
qemu/
```

The current custom machine file is:

```text
qemu/hw/arm/tle9854.c
```

If you modify QEMU code, rebuild from inside `qemu/`:

```bash
cd qemu
ninja -C build
```

Check that the custom machine still exists:

```bash
build/qemu-system-arm-unsigned -M help | grep tle
```

Commit QEMU changes from the project root:

```bash
git status
git add qemu/hw/arm/tle9854.c qemu/hw/arm/meson.build
git commit -m "Update TLE9854 QEMU machine"
git push
```

If you added more QEMU files later, such as fake MMIO peripherals, include them too:

```bash
git add qemu/hw/misc/tle9854_bootregs.c
git add qemu/include/hw/misc/tle9854_bootregs.h
git add qemu/hw/misc/meson.build
git commit -m "Add TLE9854 boot register MMIO device"
git push
```

---

## 11. Git Workflow

This repository stores both:

```text
qemu/
bootrom_project/
```

So QEMU changes and bootrom changes are committed in the same Git repo.

Check changes:

```bash
git status
```

Commit only bootrom changes:

```bash
git add bootrom_project
git commit -m "Update bootrom test program"
git push
```

Commit only QEMU changes:

```bash
git add qemu/hw/arm/tle9854.c qemu/hw/arm/meson.build
git commit -m "Update TLE9854 QEMU machine"
git push
```

Commit both QEMU and bootrom changes:

```bash
git add qemu bootrom_project
git commit -m "Update TLE9854 QEMU model and bootrom test"
git push
```

---

## 12. Files Not to Commit

Do not commit generated build outputs.

Recommended `.gitignore` entries:

```gitignore
qemu/build/
bootrom_project/*.elf
bootrom_project/*.bin
bootrom_project/*.o
bootrom_project/*.map
.DS_Store
```

---

## 13. Current Project Status

The custom QEMU machine is:

```text
-M tle9854
```

Current confirmed behavior:

```text
Cortex-M0 bootrom ELF loads in QEMU
Reset_Handler is reached
bootrom_main is reached
GDB debugging works
MMIO reads can be stepped through
```

Current limitation:

```text
The tle9854 machine is still based on QEMU's microbit/nRF51 model internally.
It is not yet a full Infineon TLE9854 emulator.
```

Future work:

```text
Add fake TLE9854-like MMIO peripherals
Map fake boot registers at controlled addresses
Replace/remove Nordic-specific behavior as needed
Model only the peripherals touched by the bootrom
```

Possible future files:

```text
qemu/hw/misc/tle9854_bootregs.c
qemu/include/hw/misc/tle9854_bootregs.h
qemu/hw/misc/tle9854_flash.c
qemu/hw/misc/tle9854_pmu.c
qemu/hw/misc/tle9854_watchdog.c
```

---

## 14. Conceptual Structure

```text
bootrom_project/
    bootrom firmware source
    builds bootrom.elf

qemu/
    emulator source
    contains custom -M tle9854 machine

bootrom.elf
    loaded by QEMU and executed on the fake Cortex-M0 machine
```

The bootrom is not compiled into QEMU. It is built separately and loaded with:

```bash
-kernel bootrom.elf
```
