`timescale 1ns / 1ps

module sensors_top #(
    parameter int GPS_NMEA_MAX_BYTES = 128 // maximum number of bytes per NMEA sentence
    ) (
    input   logic           clk,
    input   logic           rst,
    
    // gps
    input   logic           i_gps_uart_rx, // gps uart rx pin
    output  logic [GPS_NMEA_MAX_BYTES*8-1:0] o_gps_nmea_out_sentence,
    output  logic [$clog2(GPS_NMEA_MAX_BYTES+1)-1:0] o_gps_nmea_out_len,
    output  logic o_gps_nmea_in_sentence
    );
    
    
    // --- GPS ---
    logic [7:0] w_gps_uart_rx_byte;
    logic w_gps_uart_rx_valid;
    logic w_gps_uart_byte_error;
    
//    logic [GPS_NMEA_MAX_BYTES*8-1:0] o_gps_nmea_out_sentence;
//    logic [$clog2(GPS_NMEA_MAX_BYTES+1)-1:0] o_gps_nmea_out_len;
//    logic o_gps_nmea_in_sentence;
    
    uart_rx gps_uart_rx(
        // inputs
        .clk(clk),
        .rst(rst),
        .rx(i_gps_uart_rx),
        // outputs
        .rx_byte(w_gps_uart_rx_byte),
        .rx_valid(w_gps_uart_rx_valid),
        .byte_error(w_gps_uart_byte_error)
    );
    
    construct_gps_nmea_sentence #(
        .MAX_BYTES(GPS_NMEA_MAX_BYTES)
    ) u_gps_nmea (
        // inputs
        .clk(clk),
        .rst(rst),
        .rx_byte(w_gps_uart_rx_byte),
        .rx_valid(w_gps_uart_rx_valid),
        // outputs
        .out_sentence(o_gps_nmea_out_sentence),
        .out_len(o_gps_nmea_out_len),
        .in_sentence(o_gps_nmea_in_sentence)
    );
    
    
endmodule
