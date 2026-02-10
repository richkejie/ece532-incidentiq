`timescale 1ns/1ps

module temp_sensor_driver (
    input  wire clk,
    input  wire reset,
    input  wire cmd_valid,          // trigger a high-level command
    input  wire rw,                 // 1 = read, 0 = write
    input  wire [2:0] high_level_cmd,
    input  wire [15:0] cmd_value,   // only for writes

    output reg  cmd_done,
    output reg  [12:0] read_data,
    output reg  error
);

    // Internal signals to i2c master
    reg start;
    reg [6:0] slave_addr;
    reg [7:0] w_data;
    wire [15:0] r_data;
    wire busy;
    wire done;
    wire scl;
    wire sda;
    reg [7:0] cmd_reg;
    reg multi_byte; // flag to indicate if we need to read/write multiple bytes

    reg latched_rw;
    reg latched_multi_byte;
    reg [7:0] latched_cmd_reg;

    // I2C master instance
    i2c_master_general u_i2c (
        .clk(clk),
        .reset(reset),
        .start(start),
        .rw(latched_rw),
        .slave_addr(slave_addr),
        .w_data(w_data),
        .r_data(r_data),
        .data_len(latched_multi_byte ? 2 : 1),
        .busy(busy),
        .done(done),
        .ack_error(error),
        .scl(scl),
        .sda(sda)
    );

    // Determine register address and multi-byte flag
    always @(*) begin
        slave_addr = 7'h48; // ADT7420 address
        case(high_level_cmd)
            3'b000: begin cmd_reg = 8'h00; multi_byte = 1; end // READ TEMP
            3'b001: begin cmd_reg = 8'h02; multi_byte = 0; end // READ STATUS
            3'b010: begin cmd_reg = 8'h0B; multi_byte = 0; end // READ ID
            3'b011: begin cmd_reg = 8'h03; multi_byte = 0; end // CONFIG READ/WRITE
            3'b100: begin cmd_reg = 8'h04; multi_byte = 1; end // THIGH READ/WRITE
            3'b101: begin cmd_reg = 8'h06; multi_byte = 1; end // TLOW READ/WRITE
            3'b110: begin cmd_reg = 8'h08; multi_byte = 1; end // TCRIT READ/WRITE
            3'b111: begin cmd_reg = 8'h0A; multi_byte = 0; end // HYST READ/WRITE
        endcase
    end

    // FSM
    localparam IDLE = 0, WAIT_PTR = 1, TRANSACTION = 2;
    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            start <= 0;
            cmd_done <= 0;
        end else begin
            case(state)
                IDLE: begin
                    cmd_done <= 0;
                    if(cmd_valid && !busy) begin
                        latched_cmd_reg <= cmd_reg;
                        latched_multi_byte <= multi_byte;
                        latched_rw <= rw;

                        if(rw == 0) w_data <= cmd_value[15:8]; // first byte for writes
                        start <= 1;
                        state <= WAIT_PTR;
                    end else start <= 0;
                end

                WAIT_PTR: begin
                    start <= 0;
                    if(done) begin
                        start <= 1;
                        w_data <= (latched_rw == 0) ? cmd_value[15:8] : latched_cmd_reg;
                        state <= TRANSACTION;
                    end
                end

                TRANSACTION: begin
                    start <= 0;
                    if(done) begin
                        if(latched_rw) begin
                            // combine multi-byte read if needed
                            read_data <= latched_multi_byte ? r_data[15:3] : {5'b0, r_data[7:0]};
                        end
                        cmd_done <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
