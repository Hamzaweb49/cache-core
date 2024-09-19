# Makefile to run simulation on vsim

SRC_FILE = src/cache_datapath.sv src/cache_controller.sv src/ace_controller.sv src/top_level.sv 
TB_FILE = test/tb_top_level.sv

VSIM = vsim
GTKWAVE = gtkwave
VSIM_FLAGS = -c -do "run -all; quit"

VSIM_OUT = modelsim_sim.out
VCD_FILE = Top_level.vcd

# Default target
all: help

# ModelSim compile and run
vsim: $(SRC_FILE) $(TB_FILE)
	@echo "Compiling with ModelSim..."
	vlog $(SRC_FILE) $(TB_FILE)
	@echo "Running simulation with ModelSim..."
	$(VSIM) $(VSIM_FLAGS) tb_restoring_division

# View waveform using GTKWave
view: 
	@echo "Opening waveform with GTKWave..."
	$(GTKWAVE) $(VCD_FILE)

# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -f $(VSIM_OUT) $(VCD_FILE)
	rm -rf work

# Help target
help:
	@echo "Makefile for compiling and running simulations with Icarus Verilog and ModelSim"
	@echo
	@echo "Usage:"
	@echo "  make vsim           Compile and run simulation with ModelSim"
	@echo "  make view           View waveform using GTKWave"
	@echo "  make clean          Clean up generated files"
	@echo "  make help           Display this help message"

# Phony targets
.PHONY: all vsim view clean help
