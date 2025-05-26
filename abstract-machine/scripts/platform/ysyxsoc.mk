AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/ioe/ioe.c \
           riscv/ysyxsoc/ioe/timer.c \
           riscv/ysyxsoc/ioe/uart.c \
           riscv/ysyxsoc/ioe/input.c \
           riscv/ysyxsoc/ioe/gpu.c \
           riscv/ysyxsoc/input.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/am/src/riscv/ysyxsoc/linker.ld \
						 --defsym=_pmem_start=0x30000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start --print-map
CFLAGS += -DMAINARGS=\"$(mainargs)\"

NPCFLAGS += -l $(shell dirname $(IMAGE).elf)/ysyxsoc-log.txt -b
NPCFLAGS += -e $(IMAGE).elf

.PHONY: $(AM_HOME)/am/src/riscv/ysyxsoc/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents --set-section-flags .bss.extra=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) sim ARGS="$(NPCFLAGS)" IMG=$(IMAGE).bin