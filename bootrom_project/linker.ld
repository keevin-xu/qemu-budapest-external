ENTRY(Reset_Handler)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 4K
}

_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    .isr_vector :
    {
        KEEP(*(.isr_vector))
    } > ROM

    .text :
    {
        *(.text*)
        *(.rodata*)
    } > ROM

    .data :
    {
        *(.data*)
    } > RAM AT > ROM

    .bss :
    {
        *(.bss*)
        *(COMMON)
    } > RAM
}