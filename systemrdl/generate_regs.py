import os
import subprocess

RDL_FILE = "src/registers.rdl"
RTL_OUTPUT_DIR = "gen_rtl"
C_OUTPUT_DIR = "gen_c"

def generate():
    os.makedirs(RTL_OUTPUT_DIR, exist_ok=True)
    os.makedirs(C_OUTPUT_DIR, exist_ok=True)

    print(f"--- Compiling {RDL_FILE} ---")

    # 1. Generate Verilog RTL
    print("Generating SystemVerilog using PeakRDL...")
    subprocess.run([
        "peakrdl", "regblock", RDL_FILE,
        "-o", RTL_OUTPUT_DIR,
        "--cpuif", "axi4-lite"
    ])

    # 2. Generate C Header
    print("Generating C Header...")
    subprocess.run([
        "peakrdl", "c-header", RDL_FILE,
        "-o", f"{C_OUTPUT_DIR}/regs.h"
    ])

    print("\nDone!")

if __name__ == "__main__":
    generate()