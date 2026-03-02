`timescale 1ns/1ps

module temp_sensor_driver (
//    input wire cmd_start,
    input  wire clk,
    input  wire reset_n,
    input  wire cmd_start,          // trigger a high-level command
    input  wire rw,                 // 1 = read, 0 = write
    input  wire [2:0] high_level_cmd,
    input  wire [15:0] cmd_value,   // only for writes

    output reg  cmd_done,
    output reg  [15:0] read_data,
    output reg  error,
    output wire scl, 
    inout wire sda,
    output reg busy,
    wire [3:0] master_state,
    wire start
//    output reg state,
);

    // Internal signals to i2c master
    reg start;
    reg [6:0] slave_addr;
    reg [15:0] w_data;
    reg [7:0] cmd_reg;
    reg multi_byte; // flag to indicate if we need to read/write multiple bytes

    wire [15:0] master_r_data;
    wire master_busy;
    wire master_done;
    wire master_error;
   
    reg latched_rw;
    reg latched_multi_byte;
    reg [7:0] latched_cmd_reg;
    reg [2:0] latched_high_level_cmd;

    // I2C master instance
    i2c_master_general u_i2c (
        .start(start),
        .clk(clk),
        .reset_n(reset_n),
        .slave_addr(slave_addr),
        .rw(latched_rw),
        .reg_addr(latched_cmd_reg),
        .w_data(w_data),
        .multi_byte(latched_multi_byte),
        .r_data(master_r_data),
        .busy(master_busy),
        .ack_error(master_error),
        .done(master_done),
        .scl(scl),
        .sda(sda),
        .debug_state(master_state)
    );

    // Determine register address and multi-byte flag
    //writes are written byte by byte, so multi_byte is only relevant for reads of temp, thigh, tlow, tcrit
    always @(*) begin
        slave_addr = 7'h48; // ADT7420 address
        multi_byte = 0; // default to single byte unless it's a read of temp, thigh, tlow, or tcrit
        case(high_level_cmd)
            3'b000: begin // READ TEMP
                cmd_reg = 8'h00; 
                multi_byte = 1;
            end 
            3'b001: begin // READ STATUS
                cmd_reg = 8'h02; 
            end 
            3'b010: begin // READ ID
                cmd_reg = 8'h0B;
            end 
            3'b011: begin // CONFIG READ/WRITE
                cmd_reg = 8'h03;
            end 
            3'b100: begin // THIGH READ/WRITE
                cmd_reg = 8'h04;
                multi_byte = 1;
            end 
            3'b101: begin // TLOW READ/WRITE
                cmd_reg = 8'h06;
                multi_byte = 1;
            end 
            3'b110: begin // TCRIT READ/WRITE
                cmd_reg = 8'h08;
                // multi_byte = (rw == 1);
                multi_byte = 1; 
            end 
            3'b111: begin // HYST READ/WRITE
                cmd_reg = 8'h0A;
            end 
        endcase
    end

    // Simplified FSM: IDLE and COMPLETE
    localparam IDLE = 0, EXECUTE = 1, COMPLETE = 2;
    reg state;


    reg start_latched;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            start <= 0;
            cmd_done <= 0;
            start_latched <= 0;
        end else begin
            case(state)
                IDLE: begin
                    cmd_done <= 0;
                    start <= 0;
                    if(cmd_start && !busy) begin
                        // latched_cmd_reg    <= cmd_reg;
                        latched_multi_byte <= multi_byte;
                        latched_rw         <= rw;
                        // latched_high_level_cmd <= high_level_cmd;
                        if(rw == 0) begin
                            w_data <= cmd_value;
                        end
//                        start <= 1; // single-cycle pulse
                        start_latched <=1;
                        state <= COMPLETE;
                    end
                end

                COMPLETE: begin
//                    if ()
//                    start <= 0; // ensure start is a single-cycle pulse
                    start <= start_latched;
                    if (start_latched && busy) begin
                        start_latched <= 0;
                        start <= 0;
                    end
                    if (!master_error && master_done && !master_busy) begin
                        if (latched_rw) begin
                            read_data <= master_r_data;
                            // read_data <= latched_multi_byte ? master_r_data : {8'b0, master_r_data[7:0]};
                        end
                        cmd_done <= 1;
                        state <= IDLE;
                    end 
                end
            endcase
        end
    end

endmodule
