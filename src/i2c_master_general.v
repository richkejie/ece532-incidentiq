`timescale 1ns/1ps

module i2c_master_general(
    input wire clk,
    input wire reset_n,

    input wire start,
    input wire rw, //read =1, write=0
    input wire [6:0] slave_addr,
    input wire [15:0] w_data, //if single byte, use lower 8 bits and ignore upper 8 bits
    input wire multi_byte, //set to 1 if multiple bytes (ie 2 bytes), else 0 for single byte
    input wire [7:0] reg_addr, // register address to write to or read from
    // input wire [1:0] data_len,
    output reg [15:0] r_data,
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

always @(posedge clk or negedge reset_n) begin
    if (reset_n == 1'b0) begin
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
assign sda = sda_output_en ? sda_out : 1'bz; // when output enabled, drive sda_out; otherwise high impedance for reading

localparam IDLE = 0, START = 1, ADDR = 2, ACK_ADDR = 3, REG = 4, ACK_REG = 5, DATA = 6, ACK_DATA = 7, STOP = 8;

reg [2:0] state;
reg [3:0] bit_cnt;
reg [7:0] data_addr_reg;
// reg [1:0] bytes_left;

reg byte_idx;
// reg [1:0] latched_data_len;
reg [15:0] w_buffer;
reg latch_rw;
reg [7:0] latch_slave_addr;
reg repeat_start; // flag to indicate if we are in a repeated start
reg [7:0] latch_reg_addr;

always @(posedge i2c_clk or negedge reset_n) begin
    if (reset_n == 1'b0) begin
        state <= IDLE;
        busy <= 0;
        ack_error <= 0;
        sda_output_en <= 1;
        sda_out <= 1;
        r_data <= 16'h00;
        done <= 0;
        repeat_start <= 0;
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

                    byte_idx <= multi_byte; // if multi_byte is 1, start with byte_idx 1 for data phase, else start with byte_idx 0 for single byte
                    w_buffer <= w_data; // always load full 16 bits, but for single byte transactions we will only use the lower 8 bits and ignore the upper 8 bits 
                    latch_slave_addr <= slave_addr;
                    latch_reg_addr <= reg_addr;

                    repeat_start <= rw; // set flag to indicate we need a repeated start for read after writing register address
                    // latch_rw <= (rw) ? 0 : 1; // if read, latch_rw starts at 0 for first phase to write register address, then will be set to 1 for repeated start; if write, just set directly to 0
                    latch_rw <= 0; // always start with write phase to send register address, then if rw is 1 we will set latch_rw to 1 for repeated start after ACK_ADDR
                    // if (rw == 1) begin // if we are reading, the first phase is writing the register address, so we need to set latch_rw to 0 for the first part of the transaction. For writes, we can just set it directly since it's always 0
                    //     latch_rw <= 0;
                    // end else begin
                    //     latch_rw <= rw;
                    // end
                end
            end
            //might need to latch inputs at start of transaction to avoid issues with changing inputs during transaction (TODO)
            START: begin //start condition is SDA goes low while SCL is high
                sda_out <= 0;
                data_addr_reg <= { latch_slave_addr, latch_rw }; // load slave address and R/W bit into shift register
                bit_cnt <= 7;
                state <= ADDR;
                // byte_idx <= multi_byte; // if multi_byte is 1, start with byte_idx 1 for data phase, else start with byte_idx 0 for single byte
                // latch_rw <= rw;
                // latched_data_len <= (data_len == 0) ? 1 : data_len;
                // latched_data_len <= data_len; // latch data length at start of transaction
                
                // w_buffer <= (multi_byte) ? {w_data[7:0], 8'h00} : w_data; // if there is only 1 byte to write, put it in the upper byte of the buffer
                // w_buffer <= w_data; // always load full 16 bits, but for single byte transactions we will only use the lower 8 bits and ignore the upper 8 bits
                // byte_idx <= 0;
                
                // bytes_left <= (data_len == 0) ? 1 : data_len; // default to 1 byte if data_len is 0
                // bytes_left <= data_len; // use latched data length to track bytes left in transaction
            end
            ADDR: begin
                //sends addr one bit at a time, MSB first
                //once all bits sent, move to ACK state
                sda_out <= data_addr_reg[bit_cnt];
                if (bit_cnt == 0) begin
                    state <= ACK_ADDR;
                    sda_output_en <= 0;
                end else begin
                    bit_cnt <= bit_cnt - 1;
                end
            end

            ACK_ADDR: begin
                ack_error <= sda; // if slave doesn't pull low, it's an ack error
                if (ack_error) begin
                    state <= STOP; // if no ACK, stop transaction
                end else begin
                    // data_addr_reg <= w_data; // load register address into shift register for next phase
                    // data_addr_reg <= { latch_slave_addr, latch_rw, latch_reg_addr }; // load slave address, R/W bit, and register address into shift register for next phase
                    bit_cnt <= 7;
                    sda_output_en <= 1;
                    // state <= DATA;
                    state <= REG;
                    data_addr_reg <= latch_reg_addr; // load register address into shift register for next phase
                end
            end
            // i think before this all is ok, but need to check next state logic
            REG: begin
                sda_out <= data_addr_reg[bit_cnt]; // send register address MSB first
                if (bit_cnt == 0) begin
                    if (repeat_start) begin
                        repeat_start <= 0; // clear repeat_start flag after using it
                        state <= START; // if this is a read transaction, we need to do a repeated start after sending the register address
                        latch_rw <= 1; // set latch_rw to 1 for repeated start to indicate read phase
                    end else begin
                        state <= ACK_REG; // if this is a write transaction, we can just go to ACK_REG after sending the register address
                    end
                    // state <= ACK_REG;
                    // if (repeat_start) begin
                    //     state <= START; // if this is a read transaction, we need to do a repeated start after sending the register address
                    //     latch_rw <= 1; // set latch_rw to 1 for repeated start to indicate read phase
                    // end else begin
                    //     state <= ACK_REG; // if this is a write transaction, we can just go to ACK_REG after sending the register address
                    // end
                    sda_output_en <= 0; // release SDA for ACK from slave after sending register address
                end else begin
                    bit_cnt <= bit_cnt - 1;
                end
            end
            ACK_REG: begin
                ack_error <= sda;
                if (ack_error) begin
                    state <= STOP;
                end else begin
                    bit_cnt <= 7;
                    sda_output_en<=1;
                    state<=DATA;
                end
            end

            DATA: begin
                if (latch_rw == 1'b0) begin // Write operation
                    sda_out <= w_buffer[byte_idx*8 + bit_cnt]; // MSB first

                    if (bit_cnt == 0) begin
                        state <= ACK_DATA;
                        sda_output_en <= 0; // release SDA for ACK from slave after write
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end else begin
                    r_data[byte_idx*8 + bit_cnt] <= sda;

                    if (bit_cnt == 0) begin
                        state <= ACK_DATA;
                        sda_output_en <= 1; // output ACK for slave after read
                        sda_out <= (byte_idx == 1) ? 0 : 1; // ACK for first byte, NACK for second byte if multi_byte
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end

            ACK_DATA: begin
                ack_error <= sda; // check for ACK/NACK from slave
                
                if (ack_error && latch_rw == 0) begin
                    state <= STOP; // if no ACK, stop transaction
                end else begin
                    if (latch_rw == 0) begin //for writes
                        if (byte_idx) begin
                            byte_idx <= 0;
                            bit_cnt <= 7;
                            sda_output_en <= 1; // output data for next byte if there are more bytes to write
                            state <= DATA;
                        end else begin
                            state <= STOP;
                        end
                        // data_addr_reg <= w_data; // load register address into shift register for next phase
                        // bit_cnt <= 7;
                        // sda_output_en <= 1;
                        // state <= DATA;
                    end else if (latch_rw == 1) begin //for reads
                        if (byte_idx) begin
                            byte_idx <= 0;
                            bit_cnt <= 7;
                            state <= DATA;
                            sda_output_en <= 0; // release SDA for slave to output data
                        end else begin
                            state <= STOP;
                        end
                    end
                end
                // if (ack_error && rw == 0) begin
                //     state <= STOP; // if no ACK on write, stop transaction
                // end else begin
                //     bytes_left <= bytes_left - 1;
                //     if (bytes_left > 1) begin
                //         byte_idx <= byte_idx + 1;
                //         bit_cnt <= 7;
                //         state <= DATA;
                //         sda_output_en <= (rw == 0); // output data for writes, release for reads
                //         sda_out <= 0; // ACK for reads, data for writes
                //     end else begin
                //         state <= STOP;
                //     end
                // end
            end

            STOP: begin
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