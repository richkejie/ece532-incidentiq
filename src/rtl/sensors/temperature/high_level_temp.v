`timescale 1ns / 1ps

module adt_temp_monitor_top (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [15:0] t_high_value,   // desired high temp register value
    input  wire [15:0] t_low_value,    // desired low temp register value
    output wire        warning,        // high if temp > high or temp < low
    // I2C interface
    output wire        i2c_scl,
    inout  wire        i2c_sda
);

    // Internal wires
    wire cmd_done;
    wire [15:0] temp_read;
    reg  cmd_start;
    reg  rw;               // 0 = write, 1 = read
    reg  [2:0] high_level_cmd;
    reg  [15:0] cmd_value;

    // Instantiate your I2C driver
    temp_sensor_driver i2c_driver (
        .clk(clk),
        .reset_n(reset_n),
        .cmd_start(cmd_start),
        .rw(rw),
        .high_level_cmd(high_level_cmd),
        .cmd_value(cmd_value),
        .cmd_done(cmd_done),
        .temp_out(temp_read),   // assuming your driver outputs temperature
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda)
    );

    // State machine to configure registers and monitor temperature
    typedef enum logic [1:0] {IDLE, WRITE_REGS, MONITOR} state_t;
    state_t state, next_state;

    // FSM sequential
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state <= IDLE;
            cmd_start <= 0;
        end else begin
            state <= next_state;
        end
    end

    // FSM combinational
    always @(*) begin
        // Defaults
        next_state = state;
        cmd_start  = 0;
        rw         = 0;
        high_level_cmd = 0;
        cmd_value = 0;

        case(state)
            IDLE: next_state = WRITE_REGS;

            WRITE_REGS: begin
                // Write T_HIGH first
                cmd_start = 1;
                rw = 0;
                high_level_cmd = 3'd4; // assuming 4=T_HIGH register
                cmd_value = t_high_value;
                next_state = MONITOR;
            end

            MONITOR: begin
                // Read temp continuously
                cmd_start = 1;
                rw = 1;
                high_level_cmd = 3'd0; // assuming 0 = temperature register
            end
        endcase
    end

    // Temperature warning
    assign warning = (temp_read > t_high_value) || (temp_read < t_low_value);

endmodule