.syntax unified
.cpu cortex-m0
.thumb

.global vector_table
.global Reset_Handler

.section .isr_vector, "a", %progbits
vector_table:
    .word _estack
    .word Reset_Handler

.text
.thumb_func
Reset_Handler:
    bl bootrom_main

Loop:
    b Loop