RVPREFIX = riscv32-unknown-elf-
RVCC = $(RVPREFIX)gcc
RVAS = $(RVPREFIX)as
RVOBJCOPY = $(RVPREFIX)objcopy

BIN = build/core_tb.vvp
TOP = core_tb

all: $(BIN) sim

SRCFILES = src/* sim/*
GENFILES = build/rom.v

build/rom.v: build/rom.bin
	python tools/mkrom.py $< $@

# For now building the fibonacci program
build/rom.bin: build/fib.bin
	cp $< $@


$(BIN): $(SRCFILES) $(GENFILES)
	iverilog -o $@ $^ -s $(TOP)

sim: $(BIN)
	vvp  $(BIN)

clean:
	rm -f *.vvp *.vcd build/*


build/%.S.o: prog/%.S
	$(RVAS) -o $@ $<

%.bin: %.S.o
	$(RVOBJCOPY) -O binary $< $@
