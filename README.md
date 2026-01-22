# 8-Bit Pipelined RISC-Like Processor (Von Neumann Architecture)

![Project Status](https://img.shields.io/badge/Status-Completed-success) ![Language](https://img.shields.io/badge/Verilog-HDL-blue) ![Platform](https://img.shields.io/badge/FPGA-Artix--7-orange)

## 📌 Project Overview

This project presents the design and implementation of a custom **8-bit, 5-stage pipelined processor** based on the **Von Neumann architecture**. Developed using Verilog HDL, the processor features a unified memory space of 256 bytes and supports a RISC-like instruction set.

The design balances complexity with performance, integrating advanced architectural features typically found in high-end microcontrollers, such as hardware-based **Hazard Detection**, **Data Forwarding**, and automated **Interrupt Handling**. The system was successfully synthesized on a Xilinx Artix-7 FPGA (Basys3) and verified with 100% pass rates across critical edge-case simulations.



![5-Stage Pipeline Diagram](./Submissions/Block Diagram.png)


---

## 🚀 Key Features

* **5-Stage Pipeline:** Implements Instruction Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), and Write Back (WB) stages to maximize instruction throughput.
* **Von Neumann Architecture:** Utilizes a **Unified Memory** structure (256 Bytes) with a custom Dual-Port interface to allow simultaneous Instruction Fetch and Data Access.
* **Robust Hazard Management:**
    * **Forwarding Unit:** Resolves Read-After-Write (RAW) hazards by forwarding data from EX, MEM, and WB stages directly to the ID stage.
    * **Hazard Detection Unit:** Automatically inserts pipeline stalls (bubbles) when Load-Use hazards are detected.
* **Hardware Interrupts:** Supports external interrupts with atomic context switching. The system automatically preserves the Program Counter (PC) and Condition Code Register (CCR) using shadow registers and stack storage.
* **Hardware Stack Operations:** Dedicated logic for PUSH, POP, CALL, and RET instructions, managing the Stack Pointer (SP) in hardware.



---

## 🏗️ System Architecture

The processor utilizes a fully integrated datapath where control logic, memory management, and execution units operate concurrently.

### 1. Fetch Stage (IF)
* Retrieves instructions from Unified Memory.
* Handles PC updates for Normal flow, Branches, Subroutine Calls, and Interrupt Vectors (0x01).

### 2. Decode Stage (ID)
* **Control Unit (FSM):** Generates control signals and manages multi-cycle operations like Interrupts and Returns.
* **Hazard Handling:** Performs early forwarding and stall generation to ensure data integrity.

### 3. Execute Stage (EX)
* **ALU:** Performs Arithmetic (ADD, SUB), Logic (AND, OR, NOT), and Shift operations.
* **Branch Unit:** Resolves conditional jumps (JZ, JN, JC) and flushes the pipeline if a branch is taken.

### 4. Memory Stage (MEM)
* Manages Data Loads/Stores and Stack operations.
* Includes **Stack Pointer Logic** to auto-increment/decrement the SP during PUSH/POP.

### 5. Write Back Stage (WB)
* Commits results to the General Purpose Registers (R0-R3).
* Drives the **Valid** output signal to synchronize external peripherals.

---

## 🧪 Verification & Testing

The design was validated using a suite of testbenches covering general functionality and critical edge cases. All 96 test cases passed successfully.

### Critical Test Scenarios
1.  **Fibonacci Sequence Generator:**
    * Verified iterative algorithms and control flow.
    * Successfully generated the sequence 0, 1, 1, 2, 3, 5, 8.
2.  **Complex Data Hazards:**
    * Tested LDD (Load Direct) followed immediately by usage (Load-Use Hazard).
    * Verified correct Stall insertion and subsequent Data Forwarding.
3.  **Interrupts & Nested Subroutines:**
    * Triggered interrupts during active execution.
    * Verified PC save/restore, Flag preservation, and correct return from nested CALL/RET sequences.

---

## 🛠️ FPGA Implementation Stats

The design was synthesized for the **Xilinx Artix-7 (xc7a35tcpg236-1)** using the Basys3 board.

| Metric | Usage | Percentage |
| :--- | :--- | :--- |
| **Slice LUTs** | 1009 / 20800 | 5% |
| **Slice Registers** | 1221 / 41600 | 3% |
| **Block RAM** | 1.5 Tile | <1% |
| **Power Consumption** | 0.084 W | Low Power |
| **Timing** | WNS: +3.066ns | Met Constraints |

*Data derived from Vivado Implementation Reports.*

---

## 👥 Team & Contributions

This project was a collaborative effort by a team of engineers from the Faculty of Engineering, Cairo University:

* **Mohammed Nasr**
* **Amr Hamdy**
* **Mohamad Abdallah**
* **Nourhan Mohammad**
* **Huda Ehab**
* **Hagar Abdelkareem**

*Supervised by Prof. Hossam Fahmy and Eng. Hassan El-Menier.*

---

## ⚖️ License

This project is intended for educational purposes as part of the ELC3030 Advanced Microprocessor course at Cairo University.
