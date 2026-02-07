`timescale 1ns / 1ps

module data_packager(
    input   logic           clk,
    input   logic           rst,             // sync active high reset
    
    // control from polling module
    input   logic           poll_trigger,
    
    // inputs from sensors
    input   logic [15:0]    i_gps,
    input   logic [15:0]    i_accel,
    input   logic [15:0]    i_gyro,
    input   logic [7:0]     i_temp,
    
    // interface to BRAM buffer
    output  logic [63:0]    o_packaged_word,    // packaged data
    output  logic           o_valid,            // data valid
    output  logic [9:0]     o_addr              // address of BRAM
    );
    
    logic [63:0]            current_frame;
    logic [7:0]             rolling_ts;
    
    always_comb begin
        current_frame = {
            i_gps,          // [63:48]
            i_accel,        // [47:32]
            i_gyro,         // [31:16]
            i_temp,         // [15:8]
            rolling_ts      // [7:0]
        };
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            rolling_ts          <= '0;
            o_addr              <= '0;
            o_valid             <= 1'b0;
            o_packaged_word     <= '0;
        end else begin
            if (poll_trigger) begin
                o_packaged_word <= current_frame;
                o_valid         <= 1'b1;
                o_addr          <= o_addr + 1'b1;
                rolling_ts      <= rolling_ts + 1'b1; // should saturate this...
            end else begin
                o_valid         <= 1'b0;
            end
        end
    end
    
endmodule
