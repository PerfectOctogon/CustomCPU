# CustomCPU
Build my own CPU with my own instruction set, then grow it into a toolchain where instructions are defined in a file and hot software can be turned into hardware.

1. CPU descriptor: a JSON-like file that defines registers, memory, and instructions. Base instructions are built in and custom ones are compositions of primitive operations.
2. My own language that compiles down to that CPU's instructions.
3. promote: turns a function in my language into a new custom instruction in the descriptor.
4. Hardware generation: turns the descriptor, including promoted instructions, into Verilog that runs on an FPGA.

Hardware generation is realistic for a limited set of instructions with no recursion.

Design document (updated regularly): https://docs.google.com/document/d/1YHeN4AueAq_CrUQ3DLEFPw6QuZ-A1WtcalHHmcInZME/edit?usp=sharing

## Building

### Tools required:

`icarus-verilog`

### Compile + run tests:

`iverilog -o *_tb.vvp rtl/*.v tb/*.v`
`vvp *.vvp`
