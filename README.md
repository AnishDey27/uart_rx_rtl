Verilog UART Receiver Core
A robust, parameterizable, and fully verified UART (Universal Asynchronous Receiver-Transmitter) Receiver core, designed from the ground up in Verilog. This project serves as the foundational block for a complete UART communication system.
This IP was designed and verified as a personal project by Anish Dey, a B.E. student in Electronics & Tele-communication Engineering at Jadavpur University (Class of 2027) with a passion for VLSI and digital design.
Table of Contents
Key Features
Module Parameters
Port Descriptions
Functional Description
Verification Environment
Tools Used
How to Use
Future Work
Key Features
✅ Parameterizable Core: Easily configure CLK_FREQ and BAUD_RATE to adapt the module to any system.
✅ Robust Oversampling: Employs a 16x oversampling strategy with consistent mid-bit sampling (MID_SAMPLE = 7) for high noise immunity and timing margin.
✅ Standard Handshaking: Provides a clean, single-cycle rx_ready pulse for easy integration with downstream modules and a robust frame_error flag.
✅ Metastability Hardened: Includes a 2-flop synchronizer on the asynchronous rxd input to prevent metastability issues.
✅ Clean & Maintainable Code: Uses localparams for clarity and a dedicated sample_now signal to simplify conditional logic, making the code highly readable and easy to maintain.
✅ Safe FSM Design: The core state machine includes a default case to prevent accidental latches and ensure a known recovery path.
Module Parameters
The module can be configured with the following parameters during instantiation:
Parameter
Default Value
Description
CLK_FREQ
50_000_000
The frequency of the system clock (clk) in Hz.
BAUD_RATE
115200
The desired communication speed in bits per second.

Port Descriptions
Port Name
Direction
Width
Description
clk
Input
1
System clock.
rst_n
Input
1
Active-low asynchronous reset.
rxd
Input
1
The serial data input line from the transmitter.
rx_data
Output
8
The 8-bit parallel data byte received from a valid frame.
rx_ready
Output
1
A single-cycle pulse indicating rx_data is valid and ready to be read.
flag
Output
1
A frame error flag. Asserts high if a start bit or stop bit is invalid.

Functional Description
The UART receiver operates using a 4-state Finite State Machine (FSM):
IDLE: Waits for the rxd line to go low, indicating a start bit.
START_CHECK: After detecting a falling edge, it waits for half a bit period (MID_SAMPLE) and verifies that the line is still low. If not, it's considered a glitch and returns to IDLE.
DATA: Samples each of the 8 data bits (LSB first) at the center of their respective bit periods. The data is shifted into an internal SIPO (Serial-In, Parallel-Out) register.
STOP_CHECK: After receiving all data bits, it samples the line for a valid high stop bit. If the stop bit is valid, rx_ready is pulsed and the received data is latched to the output.
The core timing is controlled by a 16x oversampling clock, which is generated internally based on the CLK_FREQ and BAUD_RATE parameters.
Verification Environment
The module was rigorously verified using a flexible, self-contained testbench (uart_rx_rtl_tb.v).
Parameterized Timing: The testbench calculates the clock and bit periods from the same parameters passed to the DUT, ensuring the stimulus is always synchronized.
Task-Based Stimulus: A reusable send_byte task was created to improve readability and maintainability, allowing for clean and simple test sequences.
Golden Path Verification: The testbench successfully verifies the error-free reception of multiple consecutive data frames, as confirmed by the simulation waveform.
Future verification improvements could include adding self-checking assertions and creating tasks to inject framing errors to test the flag logic.
Tools Used
Design & Simulation: Xilinx Vivado
How to Use
Instantiate the uart_rx_rtl module in your Verilog project and override the default parameters as needed.
// Example instantiation in a top-level module
uart_rx_rtl #(
    .CLK_FREQ(100_000_000),  // Your system clock (e.g., 100 MHz)
    .BAUD_RATE(9600)         // Your desired baud rate
) uart_rx_instance (
    .clk(your_system_clock),
    .rst_n(your_reset_signal),
    .rxd(serial_input_pin),
    .rx_data(received_byte),
    .rx_ready(data_is_ready),
    .flag(frame_error_occurred)
);


Future Work
This UART Receiver is the first part of a larger project. The planned next steps are:
Develop a UART Transmitter (TX) module.
Integrate both RX and TX modules with dedicated FIFO buffers.
Create a top-level UART wrapper with a standard bus interface (e.g., AXI-Lite) for CPU control.
