# Low-Complexity Sparse FIR Filter Design & FPGA Implementation

> **From** Li et al. (2025) “A Novel Design Algorithm for Low Complexity Sparse 2-D FIR Filters”  
> **To** 1-D MATLAB prototype → Verilog → Vivado synthesis & resource analysis

---

## Table of Contents

1. [Project Overview](#project-overview)  
2. [Original Paper & Motivation](#original-paper--motivation)  
3. [Repository Structure](#repository-structure)  
4. [MATLAB Prototype](#matlab-prototype)  
   - 4.1 [Algorithm Steps](#algorithm-steps)  
   - 4.2 [Key Parameters](#key-parameters)  
   - 4.3 [Running the Demo](#running-the-demo)  
   - 4.4 [Outputs & Plots](#outputs--plots)  
5. [Verilog & Vivado Implementation](#verilog--vivado-implementation)  
   - 5.1 [fir24_pruned_q15.v Module](#fir24_pruned_q15v-module)  
   - 5.2 [Test Bench: fir24_pruned_q15_tb.v](#test-bench-fir24_pruned_q15_tbv)  
   - 5.3 [Vivado Project & Constraints](#vivado-project--constraints)  
   - 5.4 [Resource Utilization & Timing](#resource-utilization--timing)  
6. [Results Summary](#results-summary)  
7. [How to Reproduce](#how-to-reproduce)  
8. [Future Work](#future-work)  
9. [References](#references)  

---

## 1 | Project Overview

This repository demonstrates a complete workflow:

1. **Distill** the Li et al. sparse-CSE-CSD algorithm for 2-D FIR filters.  
2. **Implement** a 1-D low-pass FIR prototype in MATLAB, verify specs, measure algorithmic cost.  
3. **Export** the final 24-tap Q1.15 coefficients.  
4. **Build** a single-MAC, pipelined FIR in Verilog (`rtl/fir24_pruned_q15.v`) and verify with test bench (`rtl/fir24_pruned_q15_tb.v`).  
5. **Synthesize** in Vivado and analyze FPGA resource usage and timing.

---

## 2 | Original Paper & Motivation

The 2025 paper by Li et al. proposes:

- **Sparse filter design** via OMP/EIOMP → reduce # of non-zero taps.  
- **CSD quantisation** → multiplier-less arithmetic using ±1·2⁻ʲ digits.  
- **CSE + sensitivity-driven selection** → share “weight-two” subexpressions and minimize adder count.

**Motivation for this repo:**

- **Clarity**: validate core ideas on 1-D before full 2-D.  
- **Hardware realism**: measure real LUT/FF/DSP usage.  
- **Reproducibility**: share code & scripts for community use.

---

## 3 | Repository Structure
## Repository Structure

- **README.md**  
- **LICENSE**  

- **matlab/**  
  - `SparseFIR_CSD_demo.m`  
  - `coeff_24tap_q15.hex`  
  - **figs/**  
    - `response_full.png`  
    - `passband_zoom.png`  

- **rtl/**  
  - `fir24_pruned_q15.v`  
  - `fir24_pruned_q15_tb.v`  

- **vivado/**  
  - `create_project.tcl`  
  - **reports/**  
    - `synthesis_report.txt`  
    - `implementation_report.txt`  

- **doc/**  
  - `flowchart_CSD_CSE.png`  
  - `report.pdf`  
