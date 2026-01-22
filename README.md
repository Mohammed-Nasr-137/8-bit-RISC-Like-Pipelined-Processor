# 8-Bit Pipelined RISC-Like Processor (Von Neumann Architecture)

![Project Status](https://img.shields.io/badge/Status-Completed-success) ![Language](https://img.shields.io/badge/Verilog-HDL-blue) ![Platform](https://img.shields.io/badge/FPGA-Artix--7-orange)

## 📌 Project Overview

This project presents the design and implementation of a custom **8-bit, 5-stage pipelined processor** based on the **Von Neumann architecture**. [cite_start]Developed using Verilog HDL, the processor features a unified memory space of 256 bytes and supports a RISC-like instruction set[cite: 676, 677].

[cite_start]The design balances complexity with performance, integrating advanced architectural features typically found in high-end microcontrollers, such as hardware-based **Hazard Detection**, **Data Forwarding**, and automated **Interrupt Handling**[cite: 678]. [cite_start]The system was successfully synthesized on a Xilinx Artix-7 FPGA (Basys3) and verified with 100% pass rates across critical edge-case simulations[cite: 924, 1291].

---

## 🚀 Key Features

* [cite_start]**5-Stage Pipeline:** Implements Instruction Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), and Write Back (WB) stages to maximize instruction throughput[cite: 684].
* [cite_start]**Von Neumann Architecture:** Utilizes a **Unified Memory** structure (256 Bytes) with a custom Dual-Port interface to allow simultaneous Instruction Fetch and Data Access[cite: 755].
* **Robust Hazard Management:**
    * [cite_start]**Forwarding Unit:** Resolves Read-After-Write (RAW) hazards by forwarding data from EX, MEM, and WB stages directly to the ID stage[cite: 821].
    * [cite_start]**Hazard Detection Unit:** Automatically inserts pipeline stalls (bubbles) when Load-Use hazards are detected[cite: 816].
* **Hardware Interrupts:** Supports external interrupts with atomic context switching. [cite_start]The system automatically preserves the Program Counter (PC) and Condition Code Register (CCR) using shadow registers and stack storage[cite: 863, 1084].
* [cite_start]**Hardware Stack Operations:** Dedicated logic for PUSH, POP, CALL, and RET instructions, managing the Stack Pointer (SP) in hardware[cite: 881].

---

## 🏗️ System Architecture

[cite_start]The processor utilizes a fully integrated datapath where control logic, memory management, and execution units operate concurrently[cite: 752].

### 1. Fetch Stage (IF)
* [cite_start]Retrieves instructions from Unified Memory[cite: 759].
* [cite_start]Handles PC updates for Normal flow, Branches, Subroutine Calls, and Interrupt Vectors (0x01)[cite: 760, 781].

### 2. Decode Stage (ID)
* [cite_start]**Control Unit (FSM):** Generates control signals and manages multi-cycle operations like Interrupts and Returns[cite: 796, 799].
* [cite_start]**Hazard Handling:** Performs early forwarding and stall generation to ensure data integrity[cite: 816, 821].

### 3. Execute Stage (EX)
* [cite_start]**ALU:** Performs Arithmetic (ADD, SUB), Logic (AND, OR, NOT), and Shift operations[cite: 842].
* [cite_start]**Branch Unit:** Resolves conditional jumps (JZ, JN, JC) and flushes the pipeline if a branch is taken[cite: 855].

### 4. Memory Stage (MEM)
* [cite_start]Manages Data Loads/Stores and Stack operations[cite: 869].
* [cite_start]Includes **Stack Pointer Logic** to auto-increment/decrement the SP during PUSH/POP[cite: 881].

### 5. Write Back Stage (WB)
* [cite_start]Commits results to the General Purpose Registers (R0-R3)[cite: 896].
* [cite_start]Drives the **Valid** output signal to synchronize external peripherals[cite: 917].

---

## 🧪 Verification & Testing

The design was validated using a suite of testbenches covering general functionality and critical edge cases. [cite_start]All 96 test cases passed successfully[cite: 1287].

### Critical Test Scenarios
1.  **Fibonacci Sequence Generator:**
    * [cite_start]Verified iterative algorithms and control flow[cite: 1235].
    * [cite_start]Successfully generated the sequence 0, 1, 1, 2, 3, 5, 8[cite: 1254].
2.  **Complex Data Hazards:**
    * [cite_start]Tested LDD (Load Direct) followed immediately by usage (Load-Use Hazard)[cite: 1117].
    * [cite_start]Verified correct Stall insertion and subsequent Data Forwarding[cite: 1131].
3.  **Interrupts & Nested Subroutines:**
    * [cite_start]Triggered interrupts during active execution[cite: 1155].
    * [cite_start]Verified PC save/restore, Flag preservation, and correct return from nested CALL/RET sequences[cite: 1159].

---

## 🛠️ FPGA Implementation Stats

[cite_start]The design was synthesized for the **Xilinx Artix-7 (xc7a35tcpg236-1)** using the Basys3 board[cite: 1291].

| Metric | Usage | Percentage |
| :--- | :--- | :--- |
| **Slice LUTs** | 1009 / 20800 | 5% |
| **Slice Registers** | 1221 / 41600 | 3% |
| **Block RAM** | 1.5 Tile | <1% |
| **Power Consumption** | 0.084 W | Low Power |
| **Timing** | WNS: +3.066ns | Met Constraints |

[cite_start]*Data derived from Vivado Implementation Reports[cite: 1371, 1375, 1398].*

---

## 👥 Team & Contributions

[cite_start]This project was a collaborative effort by a team of engineers from the Faculty of Engineering, Cairo University[cite: 656, 657, 658]:

* **Mohammed Nasr**
* **Amr Hamdy**
* **Mohamad Abdallah**
* **Nourhan Mohammad**
* **Huda Ehab**
* **Hagar Abdelkareem**

*Supervised by Prof. Hossam Fahmy and Eng. [cite_start]Hassan El-Menier[cite: 671].*

---

## ⚖️ License

[cite_start]This project is intended for educational purposes as part of the ELC3030 Advanced Microprocessor course at Cairo University[cite: 668].
