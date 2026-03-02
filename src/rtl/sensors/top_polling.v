`timescale 1ns / 1ps

module top_polling (
    input  wire clk,        // 100 MHz
    input  wire BTNC,       // button for your FSM1/FSM2 reset behavior

    // SPI0 physical pins
    input  wire MISO_0,
    output wire MOSI_0,
    output wire SCK_0,
    output wire CS_n_0,

    // SPI1 physical pins
    input  wire MISO_1,
    output wire MOSI_1,
    output wire SCK_1,
    output wire CS_n_1,

    // GPS UART RX pin
    input  wire gps_rx
);

    // -------------------------------------------------------------------------
    // Power-on reset stretch: hold reset_top high for N clock cycles, then low.
    // -------------------------------------------------------------------------
    localparam integer RESET_HOLD_CYCLES = 1000;  // 1000 cycles @100MHz = 10 us
    reg [$clog2(RESET_HOLD_CYCLES+1)-1:0] rst_cnt = 0;
    reg reset_top = 1'b1;

    always @(posedge clk) begin
        if (reset_top) begin
            if (rst_cnt == RESET_HOLD_CYCLES-1) begin
                reset_top <= 1'b0;
            end else begin
                rst_cnt <= rst_cnt + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // PollingModule instance
    // -------------------------------------------------------------------------
    wire spi0_output_valid;
    wire spi1_output_valid;
    wire uart_valid;

    wire [15:0] spi0_out_dataX, spi0_out_dataY, spi0_out_dataZ;
    wire [15:0] spi1_out_dataX, spi1_out_dataY, spi1_out_dataZ;
    wire [1023:0] out_sentence_captured;

    PollingModule u_polling (
        .clk(clk),
        .reset_top(reset_top),

        .spi0_output_valid(spi0_output_valid),
        .CS_n_0(CS_n_0),
        .MOSI_0(MOSI_0),
        .MISO_0(MISO_0),
        .SCK_0(SCK_0),

        .spi1_output_valid(spi1_output_valid),
        .CS_n_1(CS_n_1),
        .MOSI_1(MOSI_1),
        .MISO_1(MISO_1),
        .SCK_1(SCK_1),

        .spi0_out_dataZ(spi0_out_dataZ),
        .spi0_out_dataY(spi0_out_dataY),
        .spi0_out_dataX(spi0_out_dataX),

        .spi1_out_dataZ(spi1_out_dataZ),
        .spi1_out_dataY(spi1_out_dataY),
        .spi1_out_dataX(spi1_out_dataX),

        .BTNC(BTNC),

        .uart_valid(uart_valid),
        .out_sentence_captured(out_sentence_captured),
        .gps_rx(gps_rx)
    );

endmodule