# Battleship-FPGA-Game-Verilog-Implementation
This project implements a Battleship-style game using Verilog HDL on an FPGA board (Tang Nano 9K). The design includes user input handling, hit/miss logic, a debouncer module, clock divider, and 7-segment display driver.
# Modules
battleship.v — Game logic
debouncer.v — Cleans button inputs
clk_divider.v — Slows down clock
ssd.v — 7-segment display driver
top.v — Top-level integration
# Project Structure
src/           → Verilog source files (battleship, clk_divider, debouncer, ssd, top)
constraints/   → tangnano9k.cst (pin assignments)
build/         → Synthesis outputs (json, fs, etc.)
docs/          → Optional reports/notes
