`timescale 1ns / 1ps

module crash_detection(
        input   logic           clk,
        input   logic           rst,

        input   logic [63:0]    i_packet,
        input   logic           i_packet_valid,

        input   logic [15:0]    i_accel_threshold,
        input   logic [15:0]    i_orient_threshold,
        input   logic [15:0]    i_temp_threshold,

        output  logic           o_crash_detected
    );

    // temporary...
    assign o_crash_detected = 1'b0;

    // store X past packets
    // can be in a buffer/shift register

    // calculate a moving average of the X history of packets

    // if accel > accel_threshold, trigger crash detected
    // if orient > orient_threshold, trigger crash detected
    // if temp > temp_threshold, trigger crash detected


endmodule
