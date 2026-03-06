//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2026 04:06:40 PM
// Design Name: 
// Module Name: temp_sensor_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module temp_sensor_driver (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        cmd_start,          // trigger a high-level command
    input  wire        rw,                 // 1 = read, 0 = write
    input  wire [2:0]  high_level_cmd,
    input  wire [15:0] cmd_value,          // only for writes

    output reg         cmd_done,
    output reg  [15:0] read_data,
    output wire         error,
    output wire        scl, 
    inout  wire        sda,
    output wire        busy,
    output wire [3:0]  master_state, // debug signal to observe master state
    output reg         start,
    output reg         start_latched, //debug signal to hold start until we see busy, to ensure master sees the pulse
    output reg         cmd_start_latched //debug signal to latch the cmd_start until we can safely start the transaction (i.e. not in the middle of another transaction)
);

    // Internal signals to i2c master
    reg [6:0]  slave_addr;
    reg [15:0] w_data;
    reg [7:0]  cmd_reg;
    reg        multi_byte;

    wire [15:0] master_r_data;
    wire        master_done;
   
    reg         latched_rw;
    reg         latched_multi_byte;
    reg [7:0]   latched_cmd_reg;

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
        .busy(busy),
        .ack_error(error),
        .done(master_done),
        .scl(scl),
        .sda(sda),
        .latch_start(),
        .state(master_state),
        .bit_cnt() //debug for observing how many bits have been transferred (useful for multi-byte transactions)
    );

    // Determine register address and multi-byte flag
    // writes are byte-by-byte; multi_byte is relevant for 16-bit regs
    always @(*) begin
        slave_addr = 7'h4B;   // if sensor NACKs, try 7'h48
        cmd_reg    = 8'h00;
        multi_byte = 1'b0;

        case (high_level_cmd)
            3'b000: begin cmd_reg = 8'h00; multi_byte = 1'b1; end // TEMP
            3'b001: begin cmd_reg = 8'h02; end                    // STATUS
            3'b010: begin cmd_reg = 8'h0B; end                    // ID
            3'b011: begin cmd_reg = 8'h03; end                    // CONFIG
            3'b100: begin cmd_reg = 8'h04; multi_byte = 1'b1; end // THIGH
            3'b101: begin cmd_reg = 8'h06; multi_byte = 1'b1; end // TLOW
            3'b110: begin cmd_reg = 8'h08; multi_byte = 1'b1; end // TCRIT
            3'b111: begin cmd_reg = 8'h0A; end                    // HYST
            default: begin cmd_reg = 8'h00; multi_byte = 1'b0; end
        endcase
    end

    // Simplified FSM: IDLE and COMPLETE
    localparam [1:0] IDLE = 2'd0, COMPLETE = 2'd1;
    reg [1:0] state;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state              <= IDLE;
            cmd_done           <= 1'b0;
            read_data          <= 16'h0000;
            // error              <= 1'b0;
            start              <= 1'b0;
            start_latched      <= 1'b0;
            cmd_start_latched  <= 1'b0;
            latched_rw         <= 1'b0;
            latched_multi_byte <= 1'b0;
            latched_cmd_reg    <= 8'h00;
            w_data             <= 16'h0000;
        end else begin
            cmd_done <= 1'b0;         // pulse behavior
            // error    <= master_error; // mirror master error

            if (cmd_start)
                cmd_start_latched <= 1'b1;

            case (state)
                IDLE: begin
                    start         <= 1'b0;
                    start_latched <= 1'b0;

                    if (cmd_start_latched && !busy) begin
                        latched_rw         <= rw;
                        latched_multi_byte <= multi_byte;
                        latched_cmd_reg    <= cmd_reg;
                        w_data             <= cmd_value;

                        start_latched      <= 1'b1;
                        cmd_start_latched  <= 1'b0;
                        state              <= COMPLETE;
                    end
                end

                COMPLETE: begin
                    start <= start_latched;

                    if (start_latched && busy)
                        start_latched <= 1'b0;

                    if (master_done && !busy) begin
                        if (latched_rw && !error)
                            read_data <= master_r_data;

                        cmd_done <= 1'b1;
                        state    <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
