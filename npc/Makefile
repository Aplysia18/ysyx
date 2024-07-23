CSRC = $(wildcard npc/csrc/*.cpp)
VSRC = $(wildcard npc/vsrc/*.v)

all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	verilator --cc --exe --build -j 0 -Wall --trace-fst ${CSRC} ${VSRC}

include ../Makefile
