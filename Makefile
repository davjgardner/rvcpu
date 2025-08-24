
BIN = core_tb.vvp
TOP = core_tb

all: $(BIN) sim

$(BIN): src/* sim/*
	iverilog -o $@ src/* sim/* -s $(TOP)

sim: $(BIN)
	vvp  $(BIN)

clean:
	rm -f *.vvp *.vcd