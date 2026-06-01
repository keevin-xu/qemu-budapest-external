#include <stdint.h>

#define FAKE_RESET_REASON (*(volatile uint32_t *)0x40000000)
#define FAKE_BOOT_MODE    (*(volatile uint32_t *)0x40000004)

void bootrom_main(void)
{
    uint32_t reset = FAKE_RESET_REASON;
    uint32_t mode = FAKE_BOOT_MODE;

    (void)reset;
    (void)mode;

    while (1) {
    }
}