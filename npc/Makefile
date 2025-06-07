TOPNAME = ysyxSoCFull
NXDC_FILES = $(NPC_HOME)/constr/$(TOPNAME).nxdc
INC_PATH ?= 

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --autoflush --trace-fst \
				-I./vsrc -I$(NPC_HOME)/../ysyxSoC/perip/uart16550/rtl -I$(NPC_HOME)/../ysyxSoC/perip/spi/rtl --timescale "1ns/1ps" --no-timing

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) $(abspath ../ysyxSoC/perip) ../ysyxSoC/build/ysyxSoCFull.v -name "*.v" -or -name "*.sv")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INC_PATH += $(NPC_HOME)/csrc/include
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" $(shell llvm-config --cxxflags) -fPIE
LDFLAGS += -lreadline -ldl $(shell llvm-config --libs)

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
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

perf: $(BIN)
	$(MAKE) -C $(NPC_HOME) clean
	$(MAKE) -C $(NPC_HOME)/../am-kernels/benchmarks/microbench/ run ARCH=riscv32e-ysyxsoc mainargs=train

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
