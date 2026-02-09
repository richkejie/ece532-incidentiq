`timescale 1ns/1ps

module temp_sensor_driver (
    input  wire clk,
    input  wire reset,
    // output wire scl,
    // inout  wire sda,

    input wire cmd_valid,          // trigger a high-level command
    input wire rw,                 // 1 = read, 0 = write
    input  wire [2:0] high_level_cmd,
    input  wire [15:0] cmd_value,    // only for writes
    input wire reset,                // reset signal for FSM

    output reg  cmd_done,
    output reg  [12:0] read_data,
    output reg error,
);

// all commands:
/*
READ_TEMP (MSB + LSB) cmd 0
READ STATUS cmd 1
READ ID cmd 2
SET CONFIG (write) cmd 3
READ CONFIG cmd 3
SET THIGH (write) cmd 4
READ THIGH cmd 4
SET TLOW (write) cmd 5
READ TLOW cmd 5
SET TCRIT (write) cmd 6
READ TCRIT cmd 6
SET HYST (write) cmd 7
READ HYST cmd 7
*/

    // Internal signals to i2c master
    reg start;
    reg [6:0] slave_addr;
    reg [7:0] w_data;
    wire [7:0] r_data;
    wire busy;
    wire done;
    wire scl; //tbd if internal or external
    wire sda; //tbd if internal or external
    reg [7:0] cmd_reg;
    wire multi_byte; // flag to indicate if we need to read/write multiple bytes

    reg [7:0] latched_cmd_reg; 
    reg latched_rw;
    reg latched_multi_byte;

    reg [7:0] msb, lsb; // temp storage for multi-byte reads/writes

    // I2C master instance
    i2c_master_general u_i2c (
        .clk(clk), 
        .reset(reset),
        .start(start),
        .rw(rw),
        .slave_addr(slave_addr),
        .w_data(w_data),
        .r_data(r_data),
        .busy(busy),
        .done(done),
        .ack_error(error),    // optional
        .scl(scl),
        .sda(sda)
    );

    always @(*) begin
        slave_addr = 7'h48; // ADT7420 address
        case (high_level_cmd):
            3'b000: begin // READ TEMP
                cmd_reg = 8'h00; // temp register
                multi_byte = 1; // need to read both MSB and LSB
            end
            3'b001: begin // READ STATUS
                cmd_reg = 8'h02; // status register
                multi_byte = 0;
            end
            3'b010: begin // READ ID
                cmd_reg = 8'h0B; // ID register
                multi_byte = 0;
            end
            3'b011: begin // CONFIG READ/WRITE
                cmd_reg = 8'h03; // config register
                multi_byte = 0;
            end
            3'b100: begin // THIGH READ/WRITE
                cmd_reg = 8'h04; // THIGH register
                multi_byte = 1; // THIGH is 16 bits
            end
            3'b101: begin // TLOW READ/WRITE
                cmd_reg = 8'h06; // TLOW register
                multi_byte = 1; // TLOW is 16 bits
            end
            3'b110: begin // TCRIT READ/WRITE
                cmd_reg = 8'h08; // TCRIT register
                multi_byte = 1; // TCRIT is 16 bits
            end
            3'b111: begin // HYST READ/WRITE
                cmd_reg = 8'h0A; // HYST register
                multi_byte = 0;
            end
        endcase
    end

    localparam IDLE = 0, WAIT_PTR = 1, READ_MSB = 2, READ_LSB = 3, WRITE_MSB = 4, WRITE_LSB = 5;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            start <= 0;
            cmd_done <= 0;
        end else begin
            case(state)
                IDLE: begin // wait for command
                    cmd_done <= 0;
                    if(cmd_valid && !busy) begin
                        latched_cmd_reg <= cmd_reg; // latch reg addr for use in i2c transaction
                        latched_multi_byte <= multi_byte;
                        latched_rw <= rw;

                        if (rw == 0) begin // for writes, also latch the data
                            msb <= cmd_value[15:8];
                            lsb <= cmd_value[7:0];
                        end

                        start <= 1;
                        rw    <= 0;         // first write register address
                        w_data <= latched_cmd_reg;
                        state <= WAIT_PTR;
                    end else begin
                        start <= 0;
                    end
                end
                WAIT_PTR: begin // after sending reg addr, send data for writes or stop for reads
                    start <= 0;
                    if(done) begin
                        start <= 1;
                        rw    <= latched_rw;        // next read/write data
                        if (latched_rw == 0) begin
                            w_data <= msb; // MSB first
                            state <= WRITE_MSB;
                        end else begin
                            state <= READ_MSB;
                        end
                    end
                end
                WRITE_MSB: begin
                    start <= 0;
                    if(done) begin
                        if(latched_multi_byte) begin
                            w_data <= lsb; // then LSB
                            state <= WRITE_LSB;
                            start <= 1;
                            rw <= 0;
                        end else begin
                            cmd_done <= 1;
                            state <= IDLE;
                        end
                    end
                end
                WRITE_LSB: begin
                    start <= 0;
                    if(done) begin
                        cmd_done <= 1;
                        state <= IDLE;
                    end
                end
                READ_MSB: begin
                    start <= 0;
                    if(done) begin
                        if(latched_multi_byte) begin
                            read_data[12:5] <= r_data; // store MSB
                            state <= READ_LSB;
                            start <= 1;
                            rw <= 1; // read
                        end else begin
                            read_data <= {5'h00, r_data}; // pad MSB with zeros
                            cmd_done <= 1;
                            state <= IDLE;
                        end
                    end
                end
                READ_LSB: begin
                    start <= 0;
                    if(done) begin
                        read_data <= {read_data[12:5], r_data[7:3]}; // combine MSB and LSB - assumes 13 bit temp data
                        cmd_done <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
