`timescale 1ns / 1ps

module data_packager(
    input   logic           clk,
    input   logic           arst_n,             // async active low reset
    
    // control from polling module
    input   logic           i_gps_valid,        // uart_valid
    input   logic           i_accel_valid,      // spi0_output_valid
    input   logic           i_gyro_valid,       // spi1_output_valid
        
    // inputs from sensors
//    input   logic [15:0]    i_gps,
    input   logic [1023:0]  i_gps_sentence,
    
    // acceleration
    input   logic [15:0]    i_accel_z,          // spi0_out_dataZ
    input   logic [15:0]    i_accel_y,          // spi0_out_dataY
    input   logic [15:0]    i_accel_x,          // spi0_out_dataX
    
    // gyro
    input   logic [15:0]    i_gyro_z,           // spi1_out_dataZ
    input   logic [15:0]    i_gyro_y,           // spi1_out_dataY
    input   logic [15:0]    i_gyro_x,           // spi1_out_dataX
    
    // handshake with sensor polling
    output  logic           o_data_recv,
    
    // output packet
    output  logic [127:0]   o_packet,
    output  logic           o_packet_valid,
    
    // interface to BRAM buffer
    output  logic [31:0]    o_data_packet_bram_addr,
    output  logic [31:0]    o_data_packet_bram_din,
    output  logic [3:0]     o_data_packet_bram_we,
    output  logic           o_data_packet_bram_en,
    
    // interface to crash detection
    output  logic [15:0]    o_cd_accel_z,
    output  logic [15:0]    o_cd_accel_y,
    output  logic [15:0]    o_cd_accel_x,
    output  logic [15:0]    o_cd_gyro_z,
    output  logic [15:0]    o_cd_gyro_y,
    output  logic [15:0]    o_cd_gyro_x
    );
    
    logic all_sensors_valid = i_accel_valid & i_gyro_valid;
    logic in_valid;
    
    // --- handshake ---
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            in_valid        <= 1'b0;
        end else if (all_sensors_valid) begin
            in_valid        <= 1'b1;
        end else begin
            in_valid        <= 1'b0;
        end
    end
    
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            o_data_recv     <= 1'b0;
        end else if (in_valid) begin
            o_data_recv     <= 1'b1;
        end else begin
            o_data_recv     <= 1'b0;
        end
    end
    
    // --- gps nmea field extract ---
    logic   [31:0]          w_gps_utc_time;
    logic   [31:0]          w_gps_latitude, w_gps_longitude;
    logic                   w_gps_north, w_gps_east;
    logic   [31:0]          w_gps_ground_speed;
    
    nmea_field_extract #(
        .SENTENCE_BITS(1024)
    ) u_gps_extract(
        .clk            (clk),
        .sentence       (i_gps_sentence),
        .utc_time       (w_gps_utc_time),
        .latitude       (w_gps_latitude),
        .north          (w_gps_north),
        .longitude      (w_gps_longitude),
        .east           (w_gps_east),
        .ground_speed   (w_gps_ground_speed)
    );
    
    
    // --- packet ---
    // not used for now...
    logic [127:0]            packet;
    
    assign o_packet         = packet;
    assign o_packet_valid   = in_valid;
    
    always_comb begin
        packet = {
            i_accel_z,        // [47:32]
            i_accel_y,
            i_accel_x,
            i_gyro_z,         // [31:16]
            i_gyro_y,
            i_gyro_x
        };
    end
    
    // --- sensor data to crash detection (passthrough for now) ---
    assign o_cd_accel_z = i_accel_z;
    assign o_cd_accel_y = i_accel_y;
    assign o_cd_accel_x = i_accel_x;
    assign o_cd_gyro_z = i_gyro_z;
    assign o_cd_gyro_y = i_gyro_y;
    assign o_cd_gyro_x = i_gyro_x;
    
    // --- BRAM write ---
    // data_packet_mem is 8K, can store 2048 32-bit words
    // need 11 bits to count all the words
    logic [10:0] word_counter;
 
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            word_counter                        <= 11'd4;
        end else if (in_valid) begin
            word_counter                    <= word_counter + 11'd4; // will naturally wrap around
        end
    end
    
    // for now, simply write lower 32 bits
    // later will pipeline the packet to write
    // or increase bus width of bram
    bram_writer u_data_packet_mem_writer(
        .clk(clk),
        .arst_n(arst_n),
        .i_valid(in_valid),
        .i_data(packet[31:0]),
        .i_bram_addr({21'd0, word_counter}),
        .o_bram_addr(o_data_packet_bram_addr),
        .o_bram_din(o_data_packet_bram_din),
        .o_bram_we(o_data_packet_bram_we),
        .o_bram_en(o_data_packet_bram_en)
    );
endmodule
