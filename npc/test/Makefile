# Makefile for char_test.c
all: char_test.elf
	@riscv64-linux-gnu-gcc -march=rv32e_zicsr -mabi=ilp32e -ffreestanding -nostdlib -Wl,-Ttext=0x30000000 -O2 -o char_test.elf char_test.c
	@riscv64-linux-gnu-objcopy -j .text -O binary char_test.elf char_test.bin
	@riscv64-linux-gnu-objdump -d char_test.elf > char_test.txt