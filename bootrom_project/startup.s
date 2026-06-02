  .syntax unified
  .cpu cortex-m0
  .thumb

  .global vector_table
  .global Reset_Handler

  .section .isr_vector, "a", %progbits
vector_table:
  /* ARM Cortex-M0 Core Exceptions */
  .word _estack            /* Top of Stack */
  .word Reset_Handler       /* Reset Handler */
  .word NMI_Handler         /* NMI Handler */
  .word HardFault_Handler   /* HardFault Handler */
  .word 0                   /* Reserved */
  .word 0                   /* Reserved */
  .word 0                   /* Reserved */
  .word 0                   /* Reserved */
  .word 0                   /* Reserved */
  .word 0                   /* Reserved */
  .word 0                   /* Reserved */
  .word SVC_Handler         /* SVCall Handler */
  .word 0                   /* Reserved */
  .word 0                   /* Reserved */
  .word PendSV_Handler      /* PendSV Handler */
  .word SysTick_Handler     /* SysTick Handler */

  /* External Peripheral Interrupts (IRQs 0 - 31) */
  .word IRQ0_Handler        /* IRQ0: GPT12 Node 0 / Timer 3 */
  .word IRQ1_Handler        /* IRQ1: CCU6 */
  .word IRQ2_Handler        /* IRQ2: SSC1 / SSC2 Serial */
  .word IRQ3_Handler        /* IRQ3: Bridge Driver / Charge Pump */
  .word IRQ4_Handler        /* IRQ4: LIN / UART / External Int 2 */
  .word IRQ5_Handler        /* IRQ5: ADC1 */
  .word IRQ6_Handler        /* IRQ6: ADC2 / Voltage & Temp Supervision */
  .word IRQ7_Handler        /* IRQ7: GPT12 Node 1 / Timer 21 */
  .word IRQ8_Handler        /* IRQ8: External Interrupt 0 */
  .word IRQ9_Handler        /* IRQ9: External Interrupt 1 */
  .word IRQ10_Handler       /* IRQ10: Mon Inputs Wakeup / Cyclic Sense */
  .word IRQ11_Handler       /* IRQ11: GPIO / Port 0 / Port 1 */
  .word IRQ12_Handler       /* IRQ12: DMA Controller */
  .word IRQ13_Handler       /* IRQ13: Math Divider Unit Completion */
  .word IRQ14_Handler       /* IRQ14: High-Side Switch Faults */
  .word IRQ15_Handler       /* IRQ15: Watchdog Timer Window / Prewarning */
  .word IRQ16_Handler       /* IRQ16: Reserved / Peripheral Slot */
  .word IRQ17_Handler       /* IRQ17: Reserved / Peripheral Slot */
  .word IRQ18_Handler       /* IRQ18: Reserved / Peripheral Slot */
  .word IRQ19_Handler       /* IRQ19: Reserved / Peripheral Slot */
  .word IRQ20_Handler       /* IRQ20: Reserved / Peripheral Slot */
  .word IRQ21_Handler       /* IRQ21: Reserved / Peripheral Slot */
  .word IRQ22_Handler       /* IRQ22: Reserved / Peripheral Slot */
  .word IRQ23_Handler       /* IRQ23: Reserved / Peripheral Slot */
  .word IRQ24_Handler       /* IRQ24: Reserved / Peripheral Slot */
  .word IRQ25_Handler       /* IRQ25: Reserved / Peripheral Slot */
  .word IRQ26_Handler       /* IRQ26: Reserved / Peripheral Slot */
  .word IRQ27_Handler       /* IRQ27: Reserved / Peripheral Slot */
  .word IRQ28_Handler       /* IRQ28: Reserved / Peripheral Slot */
  .word IRQ29_Handler       /* IRQ29: Reserved / Peripheral Slot */
  .word IRQ30_Handler       /* IRQ30: Reserved / Peripheral Slot */
  .word IRQ31_Handler       /* IRQ31: Reserved / Peripheral Slot */

  .text
  .thumb_func
Reset_Handler:
  bl bootrom_main
Loop:
  b Loop

  /* Macro to route unhandled interrupts to an infinite loop trap */
  .thumb_func
Default_Handler:
  b Default_Handler

  /* Define weak aliases for all handlers to point to Default_Handler */
  .macro def_irq_handler handler_name
  .weak \handler_name
  .set \handler_name, Default_Handler
  .endm

  /* Core Exceptions */
  def_irq_handler NMI_Handler
  def_irq_handler HardFault_Handler
  def_irq_handler SVC_Handler
  def_irq_handler PendSV_Handler
  def_irq_handler SysTick_Handler

  /* TLE985x Specific Peripheral Mapping */
  def_irq_handler IRQ0_Handler
  def_irq_handler IRQ1_Handler
  def_irq_handler IRQ2_Handler
  def_irq_handler IRQ3_Handler
  def_irq_handler IRQ4_Handler
  def_irq_handler IRQ5_Handler
  def_irq_handler IRQ6_Handler
  def_irq_handler IRQ7_Handler
  def_irq_handler IRQ8_Handler
  def_irq_handler IRQ9_Handler
  def_irq_handler IRQ10_Handler
  def_irq_handler IRQ11_Handler
  def_irq_handler IRQ12_Handler
  def_irq_handler IRQ13_Handler
  def_irq_handler IRQ14_Handler
  def_irq_handler IRQ15_Handler
  def_irq_handler IRQ16_Handler
  def_irq_handler IRQ17_Handler
  def_irq_handler IRQ18_Handler
  def_irq_handler IRQ19_Handler
  def_irq_handler IRQ20_Handler
  def_irq_handler IRQ21_Handler
  def_irq_handler IRQ22_Handler
  def_irq_handler IRQ23_Handler
  def_irq_handler IRQ24_Handler
  def_irq_handler IRQ25_Handler
  def_irq_handler IRQ26_Handler
  def_irq_handler IRQ27_Handler
  def_irq_handler IRQ28_Handler
  def_irq_handler IRQ29_Handler
  def_irq_handler IRQ30_Handler
  def_irq_handler IRQ31_Handler