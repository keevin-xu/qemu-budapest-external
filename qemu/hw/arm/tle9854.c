/*
 * TLE9854-like machine
 *
 * Based on QEMU's BBC micro:bit machine.
 * This is currently still using the nRF51 SoC model as a Cortex-M0 starting
 * point. Later, replace/remove nRF51-specific peripherals with TLE9854-like
 * mock peripherals.
 *
 * This code is licensed under the GPL version 2 or later. See
 * the COPYING file in the top-level directory.
 */

#include "qemu/osdep.h"
#include "qapi/error.h"
#include "hw/core/boards.h"
#include "hw/arm/boot.h"
#include "hw/arm/machines-qom.h"
#include "system/system.h"
#include "system/address-spaces.h"

#include "hw/arm/nrf51_soc.h"
#include "hw/i2c/microbit_i2c.h"
#include "hw/core/qdev-properties.h"
#include "qom/object.h"

struct TLE9854MachineState {
    MachineState parent;

    NRF51State nrf51;
    MicrobitI2CState i2c;
};

#define TYPE_TLE9854_MACHINE MACHINE_TYPE_NAME("tle9854")

OBJECT_DECLARE_SIMPLE_TYPE(TLE9854MachineState, TLE9854_MACHINE)

static void tle9854_init(MachineState *machine)
{
    TLE9854MachineState *s = TLE9854_MACHINE(machine);
    MemoryRegion *system_memory = get_system_memory();
    MemoryRegion *mr;

    /*
     * Temporary implementation:
     *
     * Use the existing nRF51 SoC because it already gives us a working
     * Cortex-M0 QEMU platform. This is NOT yet a real Infineon TLE9854 model.
     *
     * Later steps:
     *   - Replace Nordic memory layout with TLE9854-like ROM/SRAM/flash layout.
     *   - Remove Nordic-specific peripherals that the bootrom does not need.
     *   - Add fake TLE9854-like MMIO registers for bootrom validation.
     */
    object_initialize_child(OBJECT(machine), "nrf51", &s->nrf51,
                            TYPE_NRF51_SOC);

    qdev_prop_set_chr(DEVICE(&s->nrf51), "serial0", serial_hd(0));

    object_property_set_link(OBJECT(&s->nrf51), "memory",
                             OBJECT(system_memory), &error_fatal);

    sysbus_realize(SYS_BUS_DEVICE(&s->nrf51), &error_fatal);

    /*
     * Keep the microbit I2C stub for now because this copied machine still
     * depends on the nRF51/microbit structure. You can remove this later if
     * your bootrom does not touch this area.
     */
    object_initialize_child(OBJECT(machine), "microbit.twi", &s->i2c,
                            TYPE_MICROBIT_I2C);

    sysbus_realize(SYS_BUS_DEVICE(&s->i2c), &error_fatal);

    mr = sysbus_mmio_get_region(SYS_BUS_DEVICE(&s->i2c), 0);

    memory_region_add_subregion_overlap(&s->nrf51.container, NRF51_TWI_BASE,
                                        mr, -1);

    armv7m_load_kernel(s->nrf51.armv7m.cpu, machine->kernel_filename,
                       0, s->nrf51.flash_size);
}

static void tle9854_machine_class_init(ObjectClass *oc, const void *data)
{
    MachineClass *mc = MACHINE_CLASS(oc);

    mc->desc = "TLE9854-like machine (Cortex-M0)";
    mc->init = tle9854_init;
    mc->max_cpus = 1;
}

static const TypeInfo tle9854_info = {
    .name = TYPE_TLE9854_MACHINE,
    .parent = TYPE_MACHINE,
    .instance_size = sizeof(TLE9854MachineState),
    .class_init = tle9854_machine_class_init,
    .interfaces = arm_machine_interfaces,
};

static void tle9854_machine_init(void)
{
    type_register_static(&tle9854_info);
}

type_init(tle9854_machine_init);