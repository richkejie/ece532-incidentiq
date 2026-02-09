`timescale 1ns / 1ps

module crash_detection #(
        parameter int HISTORY_LEN = 16 // must be a power of 2
    )(
        input   logic           clk,
        input   logic           rst,
        
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
    logic [15:0] gps;
    logic [15:0] accel;
    logic [15:0] gyro;
    logic [15:0] delta;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            gps             <= '0;
            accel           <= '0;
            gyro            <= '0;
            delta           <= '0;
        end else if (i_sensors_valid) begin
            gps             <= i_gps;
            accel           <= i_accel;
            gyro            <= i_gyro;
            delta           <= i_delta;
        end // otherwise keeps the same data
    end

    logic [15:0][HISTORY_LEN:0] shift_gps, shift_accel, shift_gyro;
    logic [15:0][HISTORY_LEN-1:0] shift_delta;
    
    // this adds 1 cycle delay, inputs clocked into signals previously,
    // then starts to be shifted into the shift registers
    always_ff @(posedge clk) begin
        if (rst) begin
            shift_gps       <= '0;
            shift_accel     <= '0;
            shift_gyro      <= '0;
            shift_delta     <= '0;
        end else if (i_sensors_valid) begin
            shift_gps       <= {shift_gps[HISTORY_LEN-1:0],gps};
            shift_accel     <= {shift_accel[HISTORY_LEN-1:0],accel};
            shift_gyro      <= {shift_gyro[HISTORY_LEN-1:0],gyro};
            shift_delta     <= {shift_delta[HISTORY_LEN-1-1:0],delta};
        end // otherwise keeps the same data
    end
    
    // need 4 extra bits to hold sum of 16 16-bit numbers
    // running sums will also be a 1 cycle delay from the shift registers
    logic [HISTORY_LEN-1+3:0] accel_running_sum, gyro_running_sum, delta_running_sum;
    always_ff @(posedge clk) begin
        if (rst) begin
            accel_running_sum       <= '0;
            gyro_running_sum        <= '0;
            delta_running_sum       <= '0;
        end else if (i_sensors_valid) begin 
            accel_running_sum       <= accel_running_sum + shift_accel[1] - shift_accel[16];
            gyro_running_sum        <= gyro_running_sum + shift_gyro[1] - shift_gyro[16];
            delta_running_sum       <= delta_running_sum + shift_delta[0] - shift_delta[15];
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
                inst_speeds[i] = (shift_gps[i+1] - shift_gps[i]) / shift_delta[i];
            end else begin
                inst_speeds[i] = '0;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            speed_running_sum       <= '0;
        end else if (i_sensors_valid) begin
            speed_running_sum       <= speed_running_sum + inst_speeds[0] - inst_speeds[15];
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
    
    always_ff @(posedge clk) begin
        if (rst) begin
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
