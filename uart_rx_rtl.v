module uart_rx_rtl #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    output [7:0] rx_data,
    output rx_ready,
    output flag,
    input clk,
    input rxd,
    input rst_n
);

    localparam IDLE = 2'd0,
               START_CHECK = 2'd1,
               DATA = 2'd2,
               STOP_CHECK = 2'd3,
               OVERSAMPLE_RATE = 16,
               MID_SAMPLE = 7,
               OVS_TICK_DIV = (CLK_FREQ / (BAUD_RATE * OVERSAMPLE_RATE)) - 1;

    wire baud_tick_ovs;
    reg [$clog2(OVS_TICK_DIV)-1:0] baud_counter_ovs;
    reg [3:0] sample_counter;
    reg [2:0] data_counter;
    reg [1:0] rxd_sync;
    reg [1:0] state, next_state;
    reg flag_store, rx_ready_store;
    reg [7:0] sipo, rx_data_store;
    wire sample_now;

    // OVERSAMPLE BAUD TICK    
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) baud_counter_ovs <= 0;
        else if(state == IDLE && next_state == START_CHECK) baud_counter_ovs <= 0;
        else if(baud_tick_ovs) baud_counter_ovs <= 0;
        else baud_counter_ovs <= baud_counter_ovs + 1'b1;
    end
    assign baud_tick_ovs = (baud_counter_ovs == OVS_TICK_DIV);

    // RXD CDC
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) rxd_sync <= 2'b11;
        else rxd_sync <= {rxd, rxd_sync[1]};
    end

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) state <= IDLE;
        else state <= next_state;
    end
    always @* begin
        next_state = state;
        case(state)
            IDLE: if(rxd_sync[0] == 1'b0) next_state = START_CHECK;
            START_CHECK: if(sample_now) next_state = (rxd_sync[0] == 1'b0) ? DATA : IDLE;
            DATA: if(sample_now && data_counter==7) next_state = STOP_CHECK;
            STOP_CHECK: if(sample_now) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // SAMPLE COUNTER
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) sample_counter <= 0;
        else if(state == IDLE && next_state == START_CHECK) sample_counter <= 0;
        else if(baud_tick_ovs && sample_counter == 15) sample_counter <= 0;
        else if(baud_tick_ovs) sample_counter <= sample_counter + 1'b1;
    end
    assign sample_now = (sample_counter == MID_SAMPLE) && baud_tick_ovs;

    // DATA COUNTER
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) data_counter <= 0;
        else if(state == START_CHECK && next_state == DATA) data_counter <= 0;
        else if(state == DATA && sample_now) data_counter <= data_counter + 1'b1;
    end

    // SIPO DATA
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) sipo <= 0;
        else if(state == DATA && sample_now) sipo <= {rxd_sync[0], sipo[7:1]};
    end

    // FRAME ERROR FLAG
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) flag_store <= 1'b0;
        else if (state == IDLE && next_state == START_CHECK) flag_store <= 1'b0;
        else if (state == START_CHECK && sample_now && rxd_sync[0] == 1'b1) flag_store <= 1'b1;
        else if (state == STOP_CHECK && sample_now && rxd_sync[0] == 1'b0) flag_store <= 1'b1;
    end
    assign flag = flag_store;

    // DATA READY
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            rx_ready_store <= 1'b0;
            rx_data_store <= 0;
        end
        else if(state==STOP_CHECK && sample_now && rxd_sync[0]) begin
            rx_ready_store <= 1'b1;
            rx_data_store <= sipo;
        end
        else rx_ready_store <= 1'b0;
    end
    assign rx_ready = rx_ready_store;
    assign rx_data = rx_data_store;

endmodule