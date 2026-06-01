CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy

CFLAGS=-mcpu=cortex-m0 -mthumb -nostdlib -ffreestanding -Wall -Wextra -g
LDFLAGS=-T linker.ld -nostdlib

all: bootrom.elf bootrom.bin

bootrom.elf: startup.s bootrom.c linker.ld
	$(CC) $(CFLAGS) startup.s bootrom.c $(LDFLAGS) -o bootrom.elf

bootrom.bin: bootrom.elf
	$(OBJCOPY) -O binary bootrom.elf bootrom.bin

clean:
	rm -f bootrom.elf bootrom.bin