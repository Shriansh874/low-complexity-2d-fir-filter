# Low-Complexity Sparse 2-D FIR Filter  
*(23 × 23 taps, 40 dB attenuation / 1 % ripple)*

This repository documents the **end-to-end design and implementation** of a 2-D circular FIR low-pass filter based on the paper:

> **Yi Li, Jiaxiang Zhao, Wei Xu**  
> *“A novel design algorithm for low-complexity sparse 2-D FIR filters,”*  
> *Int. J. Circuit Theory & Applications, 2025.*

The work spans:

* **MATLAB** – dense → sparse filter generation, CSD quantisation, frequency-domain visualisation.  
* **Verilog (Vivado)** – two hardware architectures (dense vs. sparse + CSD + CSE), full synthesis, and utilisation reports.

---

## 1. Project Overview

### Objectives
1. **Reproduce the paper’s algorithm**  
   * Sparse design → CSD quantisation → Common Sub-Expression Elimination (CSE) → sensitivity-based pruning.
2. **Visualise frequency response** in MATLAB (3-D surface + radial cross-section).
3. **Quantise coefficients** (14/16/18-bit CSD) and export to a `.mem` file for HDL.
4. **Implement two FIR cores** in Verilog:  
   * `fir_dense.v`  Classic multiply–accumulate (211 taps).  
   * `fir_sparse_csd_cse.v` Sparse, CSD-encoded, CSE-optimised.
5. **Measure FPGA resource savings** (adders, LUTs, DSPs) in Vivado 2023.1.

---

## 2. Filter Specifications

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Pass-band cutoff | \( \omega_p = 0.4\pi \) | Frequencies inside are passed |
| Stop-band start | \( \omega_s = 0.6\pi \) | Frequencies outside are suppressed |
| Pass-band ripple | \( \delta_p = 0.01 \) | ±1 % magnitude tolerance |
| Stop-band attenuation | \( \alpha_s = 40\,\text{dB} \) | ⇒ \( \delta_s = 0.01 \) |
| Filter size | \( 23 \times 23 \) | Circularly symmetric |
| Word-lengths | 14 / 16 / 18 bits | CSD coefficient width |

Design constraints

\[
\begin{cases}
|H(e^{j\omega_1},e^{j\omega_2})-1|\le \delta_p & \omega_1^2+\omega_2^2 \le \omega_p^2 \\[6pt]
|H(e^{j\omega_1},e^{j\omega_2})|\le \delta_s & \omega_1^2+\omega_2^2 \ge \omega_s^2
\end{cases}
\]

---

## 3. Repository Structure

