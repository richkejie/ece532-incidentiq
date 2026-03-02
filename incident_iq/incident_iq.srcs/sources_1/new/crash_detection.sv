`timescale 1ns / 1ps

module crash_detection #(
        parameter int HISTORY_LEN = 16 // must be a power of 2
    )(
        input   logic           clk,
        input   logic           arst_n,
        
        input   logic           i_state_rst,
        
        input   logic           i_sensors_valid,
        
        input   logic [15:0]    i_accel_z,
        input   logic [15:0]    i_accel_y,
        input   logic [15:0]    i_accel_x,
        
        input   logic [15:0]    i_gyro_z,
        input   logic [15:0]    i_gyro_y,
        input   logic [15:0]    i_gyro_x,
        
        // config registers
        input   logic [31:0]    ireg_accel_threshold,
        input   logic [31:0]    ireg_angular_speed_threshold,
        
        output  logic [1:0]     o_state,
        output  logic           o_non_fatal_intr,
        output  logic           o_fatal_intr
    );

    // --------------- Sensor Data ---------------
    
    // compute max norm for acceleration
    logic [11:0] accel_max_norm;
    logic [15:0] next_accel;
    
    max_norm_3_axes #(
        .DATA_LEN(16),
        .DATA_MSB(12)
    ) u_accel_max_norm (
        .i_data_x(i_accel_x),
        .i_data_y(i_accel_y),
        .i_data_z(i_accel_z),
        .o_data_max_norm(accel_max_norm)
    );
    assign next_accel = {4'b0, accel_max_norm};
    
    // compute max norm for gyro angular rate
    logic [15:0] gyro_max_norm;
    logic [15:0] next_gyro;
    
    max_norm_3_axes #(
        .DATA_LEN(16),
        .DATA_MSB(16)
    ) u_gyro_max_norm (
        .i_data_x(i_gyro_x),
        .i_data_y(i_gyro_y),
        .i_data_z(i_gyro_z),
        .o_data_max_norm(gyro_max_norm)
    );
    assign next_gyro = gyro_max_norm;
    

    // shift registers to keep history
    logic [HISTORY_LEN:0][15:0] shift_gps;
    logic [HISTORY_LEN-1:0][15:0] shift_delta, shift_accel, shift_gyro;
    
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            shift_accel     <= '0;
            shift_gyro      <= '0;
        end else if (i_state_rst) begin
            shift_accel     <= '0;
            shift_gyro      <= '0;
        end else if (i_sensors_valid) begin
            shift_accel     <= {shift_accel[HISTORY_LEN-1-1:0],next_accel};
            shift_gyro      <= {shift_gyro[HISTORY_LEN-1-1:0],next_gyro};
        end // otherwise keeps the same data
    end
    
    // running sums of history
    // pure combinational add --- may not meet timing...
    logic [HISTORY_LEN-1+3:0] accel_running_sum, gyro_running_sum;
    
    always_comb begin
        accel_running_sum = '0;
        gyro_running_sum = '0;
        for (int i =0; i <= HISTORY_LEN-1; i++) begin
            accel_running_sum = accel_running_sum + shift_accel[i];
            gyro_running_sum = gyro_running_sum + shift_gyro[i];
        end
    end
    
    // compute average values from running sum and history length
    logic [HISTORY_LEN-1:0] avg_accel, avg_gyro;
    
    // TIMING VIOLATION: make averages sequential logic
//    assign avg_accel = accel_running_sum >> $clog2(HISTORY_LEN);
//    assign avg_gyro = gyro_running_sum >> $clog2(HISTORY_LEN);
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            avg_accel           <= '0;
            avg_gyro            <= '0;
        end else begin
            avg_accel           <= accel_running_sum >> $clog2(HISTORY_LEN);
            avg_gyro            <= gyro_running_sum >> $clog2(HISTORY_LEN);
        end
    end

    // --------------- FSM ---------------
    typedef enum logic [1:0] {
        SAFE                = 2'b00,
        NON_FATAL           = 2'b01,
        FATAL               = 2'b10
    } crash_state_t;
    
    crash_state_t state, state_next;
    
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            state       <= SAFE;
        end else if (i_state_rst) begin
            state       <= SAFE;
        end else begin
            state       <= state_next;
        end
    end
    
    always_comb begin
        state_next = state;
        
        case(state)
            SAFE: begin
                state_next = SAFE;
                if (avg_accel > ireg_accel_threshold) begin
                    state_next = FATAL;
                end else if (avg_gyro > ireg_angular_speed_threshold) begin
                    state_next = NON_FATAL;
                end
            end
            
            NON_FATAL: begin
                state_next = NON_FATAL;
                if (i_state_rst) state_next = SAFE;
            end
            
            FATAL: begin
                state_next = FATAL;
                if (i_state_rst) state_next = SAFE;
            end
            
            default: state_next = SAFE;
        endcase
    end

    // --------------- Outputs ---------------
    assign o_state = state;
    assign o_non_fatal_intr = (state == NON_FATAL);
    assign o_fatal_intr = (state == FATAL);

endmodule
