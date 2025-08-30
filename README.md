# Toy RISC-V CPU in Verilog

Simple, non-pipelined implementation of the core RISC-V specification as a means of learning Verilog.

## Setup

The following packages are required:
- `iverilog`
- `gtkwave` or `surfer` to view waveforms
- RISC-V toolchain, e.g. AUR package `riscv32-gnu-toolchain-elf-bin`

## Simulation

The core currently only runs in simulation.

Run `make` to compile and run the simulation.

## TODO

- [ ] Unit tests for all implemented instructions (maybe try out `cocotb`)
- [ ] Memory-mapped UART peripheral
- [ ] Synthesize and run on an FPGA
- [ ] Implement privilege and exception models
