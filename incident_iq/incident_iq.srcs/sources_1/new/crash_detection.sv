`timescale 1ns / 1ps

module crash_detection #(
        parameter int HISTORY_LEN = 16 // must be a power of 2
    )(
        input   logic           clk,
        input   logic           arst_n,
        
        input   logic           i_state_rst,
        
        input   logic           i_sensors_valid,
        input   logic [15:0]    i_gps,
        input   logic [15:0]    i_accel,
        input   logic [15:0]    i_gyro,
        input   logic [15:0]    i_delta,
        
        // config registers
        input   logic [31:0]    ireg_speed_threshold,
        input   logic [31:0]    ireg_non_fatal_accel_threshold,
        input   logic [31:0]    ireg_fatal_accel_threshold,
        input   logic [31:0]    ireg_angle_threshold,
        input   logic [31:0]    ireg_angle_in_motion_threshold,
        input   logic [31:0]    ireg_angular_speed_threshold,
        
        output  logic [1:0]     o_state,
        output  logic           o_non_fatal_intr,
        output  logic           o_fatal_intr
    );

    // --------------- Sensor Data ---------------

    logic [HISTORY_LEN:0][15:0] shift_gps;
    logic [HISTORY_LEN-1:0][15:0] shift_delta, shift_accel, shift_gyro;
    
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            shift_gps       <= '0;
            shift_accel     <= '0;
            shift_gyro      <= '0;
            shift_delta     <= '0;
        end else if (i_state_rst) begin
            shift_gps       <= '0;
            shift_accel     <= '0;
            shift_gyro      <= '0;
            shift_delta     <= '0;
        end else if (i_sensors_valid) begin
            shift_gps       <= {shift_gps[HISTORY_LEN-1:0],i_gps};
            shift_accel     <= {shift_accel[HISTORY_LEN-1-1:0],i_accel};
            shift_gyro      <= {shift_gyro[HISTORY_LEN-1-1:0],i_gyro};
            shift_delta     <= {shift_delta[HISTORY_LEN-1-1:0],i_delta};
        end // otherwise keeps the same data
    end
    
    // pure combinational add --- may not meet timing...
    logic [HISTORY_LEN-1+3:0] accel_running_sum, gyro_running_sum, delta_running_sum;
    
    always_comb begin
        accel_running_sum = '0;
        gyro_running_sum = '0;
        delta_running_sum = '0;
        for (int i =0; i <= HISTORY_LEN-1; i++) begin
            accel_running_sum = accel_running_sum + shift_accel[i];
            gyro_running_sum = gyro_running_sum + shift_gyro[i];
            delta_running_sum = delta_running_sum + shift_delta[i];
        end
    end
    
    logic [HISTORY_LEN-1:0] avg_accel, avg_gyro;
    assign avg_accel = accel_running_sum >> $clog2(HISTORY_LEN);
    assign avg_gyro = gyro_running_sum >> $clog2(HISTORY_LEN);

    // --------------- Speed ---------------
    logic [15:0][HISTORY_LEN-1:0] inst_speeds;
    logic [HISTORY_LEN-1+3:0] speed_running_sum;
    logic [HISTORY_LEN-1:0] avg_speed;
    
    always_comb begin
        for (int i = 0; i < HISTORY_LEN; i++) begin
            if (shift_delta[i] > 0) begin
                inst_speeds[i] = (shift_gps[i] - shift_gps[i+1]) / shift_delta[i];
            end else begin
                inst_speeds[i] = '0;
            end
        end
    end
    
    // pure combinational add --- may not meet timing...
    always_comb begin
        speed_running_sum = '0;
        for (int i =0; i <= HISTORY_LEN-1; i++) begin
            speed_running_sum = speed_running_sum + inst_speeds[i];
        end
    end
    
    assign avg_speed = speed_running_sum >> $clog2(HISTORY_LEN);

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
                if ((avg_speed >= ireg_speed_threshold) && (
                    (avg_accel > ireg_fatal_accel_threshold) ||
                    (avg_gyro > ireg_angle_threshold)
                )) begin
                    state_next = FATAL;
                end else if ((avg_speed < ireg_speed_threshold) && (
                    (avg_accel > ireg_non_fatal_accel_threshold) ||
                    (avg_gyro > ireg_angle_threshold)
                )) begin
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
