# Simulation, Testing, and Graphing Guide

This guide explains how to run the simulations, validate the routing logic against the C golden model, and generate performance graphs for your report.

---

## 1. Out-of-the-Box Report Generation (No Dependencies)

We have provided a Python script [Analysis/plot_noc_performance.py](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Analysis/plot_noc_performance.py) that reads simulation data and outputs a polished HTML report with vector SVG charts. It does **not** require MATLAB, `matplotlib`, or `pandas`.

### How to Run:
1. Open PowerShell or Command Prompt.
2. Navigate to the project root and run:
   ```bash
   python Analysis/plot_noc_performance.py
   ```
3. Open [Analysis/noc_performance_summary.html](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Analysis/noc_performance_summary.html) in any web browser. You will see:
   * **Latency vs Traffic Load** graph (cycles vs offered load).
   * **Throughput Trend** graph (packets per cycle).
   * **Simulation Summary Table** showing traffic rate, latency, and status.

---

## 2. RTL Simulation in Vivado

To compile the Verilog RTL and run the testbench in **Xilinx Vivado**:

### Step 1: Create a Vivado Project
1. Open Vivado.
2. Select **Create Project** -> Name it `NoC_2x2_Mesh`.
3. Choose **RTL Project** -> Click Next.

### Step 2: Add Design Sources
1. Add the following files from the `Design/` directory:
   * [1(FIFO).v](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Design/1(FIFO).v)
   * [2(Routing_logic).v](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Design/2(Routing_logic).v)
   * [3(Router).v](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Design/3(Router).v)
   * [4(Traffic_generator).v](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Design/4(Traffic_generator).v)
   * [5(NoC_top).v](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Design/5(NoC_top).v)
2. Ensure target language is set to **Verilog**.

### Step 3: Add Simulation Source
1. Add [Testbench/5(Top_Noc_tb).v](file:///c:/Users/anurag/.gemini/antigravity/scratch/NoC-mini-project/Testbench/5(Top_Noc_tb).v) as a **Simulation Source**.
2. Set `noc_top_tb` as the top module.

### Step 4: Run Simulation
1. Click **Run Simulation** -> **Run Behavioral Simulation**.
2. Vivado will open the waveform viewer. You can inspect the clock (`clk`), handshakes (`tg_valid`/`tg_ready`), and internal FIFO statuses.
3. Upon completion, the testbench will automatically output:
   * Console displays indicating `INJECT` and `DELIVER` cycles for all 4 test packets.
   * A file named `Analysis/noc_results.csv` capturing average latency and throughput.

---

## 3. C-based Golden Reference Model

The C model is used to validate the XY routing algorithm. It sweeps through all 16 routing coordinate combinations to verify logic correctness.

### Compile (using GCC):
```bash
gcc -std=c11 -O2 GoldenReference/main.c GoldenReference/noc_golden.c -o GoldenReference/noc_golden
```

### Run Tests:
* **Run Self-Test** (asserts that the algorithm behaves correctly for all grid nodes):
  ```bash
  ./GoldenReference/noc_golden --self-test
  ```
* **Run Routing Sweep** (dumps routing directions for all source/destination combinations):
  ```bash
  ./GoldenReference/noc_golden --sweep
  ```
* **Verify Custom Packet Route** (prints routing choice at node (0,1) for packet `0x99`):
  ```bash
  ./GoldenReference/noc_golden --packet 0x99 --x 0 --y 1
  ```

---

## 4. Graphing in MATLAB

If you have MATLAB installed, you can use the original MATLAB scripts:

1. Open MATLAB.
2. Navigate to the `Analysis/` folder.
3. Run the following command in the Command Window:
   ```matlab
   plot_noc_performance('noc_results_demo.csv')
   ```
4. This will create and save a high-resolution PNG: `Analysis/noc_performance_summary.png`.
