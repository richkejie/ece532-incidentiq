`timescale 1ns / 1ps

module crash_detection_tb();

    parameter HISTORY_LEN = 10;

    parameter CLK_PERIOD = 10; // 100 MHz clock
    parameter RESET_CYCLES = 5;


    logic clk;
    logic rst;

    // inputs to crash_detection
    logic           i_state_rst;
    logic           i_sensors_valid;
    logic [15:0]    i_gps;
    logic [15:0]    i_accel;
    logic [15:0]    i_gyro;
    logic [15:0]    i_delta;

    logic [31:0]    ireg_speed_threshold                = 32'd20; // 20km/h
    logic [31:0]    ireg_non_fatal_accel_threshold      = 32'd50; // ~5G
    logic [31:0]    ireg_fatal_accel_threshold          = 32'd70; // ~7G
    logic [31:0]    ireg_angle_threshold                = 32'd45; // 45 degrees
    logic [31:0]    ireg_angle_in_motion_threshold;                 // unused
    logic [31:0]    ireg_angular_speed_threshold;                   // unused

    // outputs from crash_detection
    logic [1:0]     o_state;
    logic           o_non_fatal_intr;
    logic           o_fatal_intr;

    // expected
    logic [63:0]    expected_packet;

    crash_detection #(
        .HISTORY_LEN(HISTORY_LEN)
    ) dut (
        .*  // connect all matching signal names
    );

    // clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // intialize signals
    task init;
        i_state_rst = 0;
        i_sensors_valid = 0;
        i_gps = 0; i_accel = 0; i_gyro = 0; i_delta = 0;
    endtask

    // apply reset cleanly for 5 cycles
    task apply_reset;
        $display("%0t: apply reset", $time);
        rst = 1;
        repeat (RESET_CYCLES) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);
    endtask

    task reset_state;
        $display("%0t: reset state", $time);
        i_state_rst = 1;
        @(posedge clk);
        i_state_rst = 0;
        @(posedge clk);
    endtask

    // send a sensor sample
    task send_sample(
        input [15:0] gps,
        input [15:0] accel,
        input [15:0] gyro,
        input [15:0] delta
    );
        begin
            @(posedge clk);
            i_sensors_valid     <= 1'b1;
            i_gps               <= gps;
            i_accel             <= accel;
            i_gyro              <= gyro; 
            i_delta             <= delta;
            @(posedge clk);
            i_sensors_valid     <= 1'b0;
        end
    endtask

    // --------------main simulation code--------------
    integer start_simulation = 0;
    integer simulation_done = 0;
    
    
    initial begin
        init();
        apply_reset();
        start_simulation = 1;
    end

    // #### driver ####
    initial begin
        wait (start_simulation == 1);

        // Test Case 1: Normal Driving (Safe State)
        // gps increases, but accel/gyro remain low
        $display("%0t: TC1: Normal Driving", $time);
        for (int i = 0; i < 20; i++) begin
            send_sample((i*10), 16'd10, 16'd2, 16'd1);
        end
        #100;

        // Test Case 2: Non-Fatal Impact
        // high accel, but low speed (gps hasn't changed much)
        $display("%0t: TC2: Low-speed impact (Non-Fatal)", $time);
        send_sample(16'd205, 16'd600, 16'd5, 16'd1); // sudden spike in acceleration
        repeat (5) @(posedge clk);

        // reset state for next test
        reset_state();

        // Test Case 3: Fatal Crash
        // high speed + high accel + rotation
        $display("%0t: TC3: High-speed crash (Fatal)", $time);
        for (int i = 0; i < 16; i++) begin
            send_sample(16'd1000 + (i*100), 16'd20, 16'd0, 16'd1); // fill history with high speed first
        end
        send_sample(16'd2600, 16'd100, 16'd80, 16'd1); // impact
        repeat (10) @(posedge clk);

        simulation_done = 1;
    end

    // #### monitor ####
    initial begin
        wait (start_simulation == 1);
        $display("%0t: --- Starting Simulation ---", $time);
        $monitor("%0t | State:%b | Non-Fatal:%b | Fatal:%b", 
              $time, o_state, o_non_fatal_intr, o_fatal_intr);
    end

    // // Simple logging assertion
    // always @(posedge o_fatal_intr) 
    //     $display("%0t [ASSERTION] Fatal Crash Detected!", $time);

    // always @(posedge o_non_fatal_intr) 
    //     $display("%0t [ASSERTION] Non-Fatal Crash Detected!", $time);

    // #### end sim ####
    initial begin
        wait (simulation_done == 1);
        repeat (5) @(posedge clk); // wait 5 cycles before ending
        $display("Simulation finished at time %0t", $time);
        $finish;
    end


endmodule
