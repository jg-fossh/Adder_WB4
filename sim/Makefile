NPROCS = 1
OS := $(shell uname -s)
ifeq ($(OS),Linux)
  NPROCS := $(shell grep -c ^processor /proc/cpuinfo)
else ifeq ($(OS),Darwin)
  NPROCS := $(shell system_profiler | awk '/Number of CPUs/ {print $$4}{next;}')
endif # $(OS)
THREADS := $(NPROCS)

SIM = verilator
TOPLEVEL_LANG = verilog
EXTRA_ARGS += --trace-fst --trace-structs --threads $(THREADS)
VERILOG_SOURCES = $(shell pwd)/../source/Adder.v ./TB_TOP.v

PLUSARGS=+UVM_VERBOSITY=UVM_LOW +UVM_NO_RELNOTES
ifneq ($(UVM_TEST),)
  PLUSARGS += +UVM_TESTNAME=$(UVM_TEST)
else
  PLUSARGS += +UVM_TESTNAME=default_test
endif

TOPLEVEL := TB_TOP
MODULE   ?= top

include $(shell cocotb-config --makefiles)/Makefile.sim
