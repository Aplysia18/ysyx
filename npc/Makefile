CSRC = $(wildcard ./csrc/*.cpp)
VSRC = $(wildcard ./vsrc/*.v)

all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	verilator --cc --exe --build -j 0 -Wall --trace-fst ${CSRC} ${VSRC}

clean:
	rm -rf obj_dir

include ../Makefile
