TOPNAME = ysyx_24110015_top
INC_PATH ?= 

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace \
				-I./vsrc/include

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INC_PATH += $(NPC_HOME)/csrc/include
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

$(DIFF_REF_SO):
	$(MAKE) -C $(NEMU_HOME)

all:
	@echo "Write this Makefile by your self."

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Verilator simulation"
	@echo "$^ $(ARGS) $(EXTRA_ARGS) $(IMG)"
	@$^ $(ARGS) $(EXTRA_ARGS) $(IMG)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
