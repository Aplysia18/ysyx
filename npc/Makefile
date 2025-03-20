TOPNAME = ysyxSoCFull
INC_PATH ?= 

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace-fst \
				-I./vsrc --timescale "1ns/1ps" --no-timing

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(shell find $(abspath ./vsrc) $(abspath ../ysyxSoC/perip) -name "*.v" -or -name "*.sv")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INC_PATH += $(NPC_HOME)/csrc/include $(NPC_HOME)/../ysyxSoC/perip/uart16550/rtl $(NPC_HOME)/../ysyxSoC/perip/spi/rtl
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" $(shell llvm-config --cxxflags) -fPIE
LDFLAGS += -lreadline -ldl $(shell llvm-config --libs)

$(BIN): $(VSRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

IMG ?=
ARGS ?= --log=$(BUILD_DIR)/npc-log.txt

# nemu shared library for difftest
DIFF_REF_SO = $(NEMU_HOME)/build/riscv32-nemu-interpreter-so
EXTRA_ARGS += --diff=$(DIFF_REF_SO)

all:
	@echo "Write this Makefile by your self."

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(MAKE) -C $(NEMU_HOME) clean
	$(MAKE) -C $(NEMU_HOME)
	@echo "Verilator simulation"
	@echo "$< $(ARGS) $(EXTRA_ARGS) $(IMG)"
	@$< $(ARGS) $(EXTRA_ARGS) $(IMG)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
