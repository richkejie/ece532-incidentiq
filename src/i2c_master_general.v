`timescale 1ns/1ps

module i2c_master_general(
    input wire clk, //system clock
    input wire reset_n, //asynchronous active low reset

    input wire start, //signal to start transaction (no effect if already busy with a transaction)
    input wire [6:0] slave_addr, //7-bit slave address
    input wire rw, //read =1, write=0
    input wire [7:0] reg_addr, // register address to write to or read from
    input wire [15:0] w_data, //if single byte, use lower 8 bits
    input wire multi_byte, //set to 1 if multiple bytes (ie 2 bytes), else 0 for single byte
    output reg [15:0] r_data, //if single byte, valid data will be in lower 8 bits and upper 8 bits will be 0
    output reg busy, // goes high when transaction is in progress, goes low when transaction is complete and STOP condition has been generated
    output reg ack_error, // goes high if we detect an ACK error (ie. slave fails to ACK address or data), goes low at start of new transaction
    output reg done, // goes high for one clock cycle when transaction is complete (ie. STOP condition generated) to indicate to rest of system that transaction is complete

    output wire scl, // I2C clock line (driven by master)
    inout wire sda // I2C data line (bidirectional, driven by master or slave depending on phase of transaction
);

//clock division - tbd relative to system clock frequency
parameter CLK_DIV = 250;

reg [$clog2(CLK_DIV)-1:0] clk_div_cnt;
reg i2c_clk;

//Clock generation (i2c_clk will be scaled down relative to system clock based on CLK_DIV parameter
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

//when sda_output_en is 1, we drive sda_out. else, we release sda (high impedance) for slave to drive it during ACK and read data phases
reg sda_out, sda_output_en;
assign sda = sda_output_en ? sda_out : 1'bz; 

localparam IDLE = 0, START = 1, ADDR = 2, ACK_ADDR = 3, REG = 4, ACK_REG = 5, DATA = 6, ACK_DATA = 7, STOP = 8;
reg [3:0] state;

reg [3:0] bit_cnt; //counter for bits being sent/received, counts down from 7 to 0 for each byte
reg [7:0] data_addr_reg; //reg for (slave addr + R/W bit) or (register address) to be shifted out during ADDR and REG states

reg byte_index; //index for multi-byte transactions, 0 for first byte (or only byte if single byte transaction), 1 for second byte in multi-byte transaction
reg [15:0] w_buffer; //write buffer (latched w_data)
reg rw_flag; //rw bit 
reg [7:0] latch_slave_addr; // latched slave address
reg repeat_start; // flag to indicate if we require a repeated start (ie. is this a read transaction); set to rw input at start of transaction, cleared after using it for repeated start
reg [7:0] latch_reg_addr; // latched register address
reg start_phase;

always @(posedge scl or negedge reset_n) begin
    if (reset_n == 1'b0) begin
        state <= IDLE;
        busy <= 0;
        ack_error <= 0;
        sda_output_en <= 0;
        sda_out <= 0;
        r_data <= 16'h0; 
        done <= 0;
        repeat_start <= 0;
        start_phase <= 0;
    end else begin
        case (state)
            IDLE: begin
                done <= 0;
                sda_output_en <= 0; // release SDA line in IDLE state
                sda_out <= 1; // keep SDA high in IDLE state
                start_phase <= 0; // reset start_phase flag at beginning of IDLE state

                // wait for start signal, then move to START state to generate start condition
                if (start) begin
                    busy <= 1;
                    state <= START;
                    //set up initial conditions for start of transaction
                    sda_output_en <= 1;
                    sda_out <= 1;

                    byte_index <= multi_byte; // if multi_byte is 1, start with byte_index 1 for data phase, else start with byte_index 0 for single byte
                    w_buffer <= w_data; // always load full 16 bits, but for single byte transactions we will only use the lower 8 bits and ignore the upper 8 bits 
                    latch_slave_addr <= slave_addr;
                    latch_reg_addr <= reg_addr;

                    repeat_start <= rw; // set flag to indicate we need a repeated start for read after writing register address
                    rw_flag <= 0; // always start with write phase to send register address, then if rw is 1 we will set rw_flag to 1 for repeated start after ACK_ADDR
                    bit_cnt <= 7; 
                end
            end
            
            START: begin 
                //start condition is SDA goes low while SCL is high
                sda_output_en <= 1;
                sda_out <= 0;
                data_addr_reg <= { latch_slave_addr, rw_flag }; // load slave address and R/W bit into shift register for next phase
                state <= ADDR;
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
                ack_error <= sda; // if slave doesn't pull low, it's an ack error (proceed to STOP state)
                if (sda) begin
                    state <= STOP; 
                end else begin
                    bit_cnt <= 7;
                    sda_output_en <= 1;
                    state <= REG;
                    data_addr_reg <= latch_reg_addr; // load register address into shift register for next phase
                end
            end
            
            REG: begin
                sda_out <= data_addr_reg[bit_cnt]; // send register address MSB first
                if (bit_cnt == 0) begin
                    state <= ACK_REG;
                    sda_output_en <= 0; // release SDA for ACK from slave after sending register address
                end else begin
                    bit_cnt <= bit_cnt - 1;
                end
            end

            ACK_REG: begin
                ack_error <= sda; // if slave doesn't pull low, it's an ack error (proceed to STOP state)
                if (sda) begin
                    state <= STOP;
                end else begin
                    bit_cnt <= 7;
                    if (repeat_start) begin
                        //if this is a read transaction, we need to do a repeated start after sending the register address
                        // sda_output_en<=1;
                        sda_output_en<=0; // release SDA to prepare for repeated start condition (SDA goes low while SCL is high), we will drive SDA low in START state of repeated start
                        // sda_out<=1; 
                        repeat_start <= 0; // clear repeat_start flag after using it
                        state <= START; // if this is a read transaction, we need to do a repeated start after sending the register address
                        rw_flag <= 1; // set rw_flag to 1 for repeated start to indicate read phase
                    end else begin
                        state<=DATA;
                        sda_output_en <= !rw_flag; // if rw_flag is 0 (write), we will output data in DATA state; if rw_flag is 1 (read), we will release SDA for slave to output data in DATA state
                    end
                end
            end

            DATA: begin
                if (rw_flag == 1'b0) begin // Write operation
                    sda_out <= w_buffer[byte_index*8 + bit_cnt]; // MSB first

                    if (bit_cnt == 0) begin
                        state <= ACK_DATA;
                        sda_output_en <= 0; // release SDA for ACK from slave after write
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end else begin
                    r_data[byte_index*8 + bit_cnt] <= sda;

                    if (bit_cnt == 0) begin
                        state <= ACK_DATA;
                        sda_output_en <= 1; // output ACK for slave after read
                        sda_out <= (byte_index == 1) ? 0 : 1; // ACK for first byte, NACK for second byte if multi_byte
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end

            ACK_DATA: begin
                ack_error <= sda; // check for ACK/NACK from slave, but only treat it as an error if we were writing data (rw_flag == 0)
                
                if (sda && rw_flag == 0) begin
                    state <= STOP; 
                end else begin
                    if (byte_index) begin
                        byte_index <= 0;
                        bit_cnt <= 7;
                        state <= DATA;
                        sda_output_en <= !rw_flag; // for writes, output next byte;
                    end else begin
                        state <= STOP;
                    end
                    // if (rw_flag == 0) begin //for writes
                    //     if (byte_index) begin
                    //         byte_index <= 0;
                    //         bit_cnt <= 7;
                    //         sda_output_en <= 1; // output data for next byte if there are more bytes to write
                    //         state <= DATA;
                    //     end else begin
                    //         state <= STOP;
                    //     end
                    // end else if (rw_flag == 1) begin //for reads
                    //     if (byte_index) begin
                    //         byte_index <= 0;
                    //         bit_cnt <= 7;
                    //         state <= DATA;
                    //         sda_output_en <= 0; // release SDA for slave to output data
                    //     end else begin
                    //         state <= STOP;
                    //     end
                    // end
                end
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