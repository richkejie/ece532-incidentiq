`timescale 1ns / 1ps

module data_packager(
    input   logic           clk,
    input   logic           rst,             // sync active high reset
    
    // control from polling module
    input   logic           in_valid,
    
    // inputs from sensors
    input   logic [15:0]    i_gps,
    input   logic [15:0]    i_accel,
    input   logic [15:0]    i_gyro,
    input   logic [7:0]     i_temp,
    input   logic [7:0]     i_delta,
    
    // output packet
    output  logic [63:0]    o_packet,
    output  logic           o_packet_valid,
    
    // interface to BRAM buffer
    output  logic [31:0]    o_data_packet_bram_addr,
    output  logic [31:0]    o_data_packet_bram_din,
    output  logic [3:0]     o_data_packet_bram_we,
    output  logic           o_data_packet_bram_en
    
    // interface to crash_detection
    );
    
    logic [63:0]            packet;
    
    logic [63:0]            w_packet_d;
    logic                   w_packet_valid;
    
    assign o_packet         = w_packet_d;
    assign o_packet_valid   = w_packet_valid;
    
    always_comb begin
        packet = {
            i_gps,          // [63:48]
            i_accel,        // [47:32]
            i_gyro,         // [31:16]
            i_temp,         // [15:8]
            i_delta         // [7:0]
        };
    end
    
    // data_packet_mem is 8K, can store 2048 32-bit words
    // need 11 bits to count all the words
    logic [10:0] word_counter;
 
    always_ff @(posedge clk) begin
        if (rst) begin
            w_packet_d                          <= '0;
            w_packet_valid                      <= 1'b0;
            word_counter                        <= '0;
        end else begin
            if (in_valid) begin
                w_packet_d                      <= packet;
                w_packet_valid                  <= 1'b1;
                word_counter                    <= word_counter + 11'd1; // will naturally wrap around
            end else begin
                w_packet_valid                  <= 1'b0;
            end
        end
    end
    
    // for now, simply write lower 32 bits
    // later will pipeline the packet to write
    // or increase bus width of bram
    bram_writer u_data_packet_mem_writer(
        .clk(clk),
        .rst(rst),
        .i_valid(w_packet_valid),
        .i_data(w_packet_d[31:0]),
        .i_bram_addr({21'd0, word_counter}),
        .o_bram_addr(o_data_packet_bram_addr),
        .o_bram_din(o_data_packet_bram_din),
        .o_bram_we(o_data_packet_bram_we),
        .o_bram_en(o_data_packet_bram_en)
    );
    
endmodule
