`timescale 1ns/1ps

module i2c_master_general(
    input wire clk,
    input wire reset,

    input wire start,
    input wire rw,
    input wire [6:0] slave_addr,
    input wire [7:0] w_data,
    output reg [7:0] r_data,
    output reg busy,
    output reg ack_error,
    output reg done,

    output wire scl,
    inout wire sda
);

//clock division - tbd relative to system clock frequency
parameter CLK_DIV = 250;

reg [$clog2(CLK_DIV)-1:0] clk_div_cnt;
reg i2c_clk;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_div_cnt <= 0;
        i2c_clk <= 1;
    end else if (clk_div_cnt == CLK_DIV) begin
        clk_div_cnt <= 0;
        i2c_clk <= ~i2c_clk;
    end else begin
        clk_div_cnt <= clk_div_cnt + 1;
    end
end

assign scl = i2c_clk;

reg sda_out, sda_output_en;
assign sda = sda_output_en ? sda_out : 1'bz;

localparam IDLE = 0, START = 1, ADDR = 2, ACK1 = 3, REG = 4, ACK2 = 5, DATA = 6, ACK3 = 7, STOP = 8;

reg [2:0] state;
reg [3:0] bit_cnt;
reg [7:0] data_addr_reg;

always @(posedge i2c_clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        busy <= 0;
        ack_error <= 0;
        sda_output_en <= 1;
        sda_out <= 1;
        r_data <= 8'h00;
        done <= 0;
    end else begin
        case (state)
            IDLE: begin
                done <= 0;
                // wait for start signal, then move to START state to generate start condition
                if (start) begin
                    busy <= 1;
                    state <= START;
                    sda_output_en <= 1;
                    sda_out <= 1;
                end
            end
            START: begin //start condition is SDA goes low while SCL is high
                sda_out <= 0;
                data_addr_reg <= { slave_addr, rw }; // load slave address and R/W bit into shift register
                bit_cnt <= 7;
                state <= ADDR;
            end

            ADDR: begin
                //sends addr one bit at a time, MSB first
                //once all bits sent, move to ACK state
                sda_out <= data_addr_reg[bit_cnt];
                if (bit_cnt == 0) 
                    state <= ACK1;
                    sda_output_en <= 0;
                else 
                    bit_cnt <= bit_cnt - 1;
            end

            ACK1: begin
                ack_error <= sda; // if slave doesn't pull low, it's an ack error
                if (ack_error) begin
                    state <= STOP; // if no ACK, stop transaction
                end else begin
                    data_addr_reg <= w_data; // load register address into shift register for next phase
                    bit_cnt <= 7;
                    sda_output_en <= 1;
                    state <= DATA;
                end
            end

            DATA: begin
                if (rw == 1'b0) begin // Write operation
                    sda_out <= data_addr_reg[bit_cnt];
                end else begin // Read operation
                    r_data[bit_cnt] <= sda;
                end
                
                if (bit_cnt == 0) begin
                    state <= ACK2;
                    sda_output_en <= rw;
                end else begin
                    bit_cnt <= bit_cnt - 1;
                end
            end

            ACK2: begin
                ack_error <= sda; // check for ACK/NACK from slave
                state <= STOP;
            end

            STOP: begin
                sda_out <= 0;
                sda_output_en <= 1;
                sda_out <= 1; // STOP condition: SDA goes high while SCL is high
                busy <= 0;
                done <= 1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule