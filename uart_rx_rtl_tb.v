`timescale 1ns / 1ps

module uart_rx_rtl_tb();
    localparam CLK_FREQ  = 50_000_000;
    localparam BAUD_RATE = 9600;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ;
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE;

    wire [7:0] rx_data;
    wire rx_ready, flag;
    reg clk, rxd, rst_n;

    uart_rx_rtl #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut(
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .flag(flag),
        .clk(clk),
        .rxd(rxd),
        .rst_n(rst_n)
    );

    initial begin
        clk = 1'b0; rst_n = 1'b0; rxd = 1'b1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    task send_byte(input [7:0] data_out);
        begin
            #BIT_PERIOD rxd = 1'b0; // START BIT
            for (integer i = 0; i < 8; i = i + 1) #BIT_PERIOD rxd = data_out[i]; // DATA BITS
            #BIT_PERIOD rxd = 1'b1; // STOP BIT
            #BIT_PERIOD rxd = 1'b1; // IDLE
        end
    endtask

    initial begin
        #5 rst_n = 1'b1;

        send_byte(8'hD8);
        send_byte(8'h9C);
        send_byte(8'hB4);

        #(3*BIT_PERIOD) $finish;
    end

endmodule