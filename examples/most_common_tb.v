// Richard's most_common_tb.v file as an example for how to write testbenches

`timescale 1ns / 1ps

module most_common_tb(

    );
    
    parameter CLK_PERIOD = 10;
    parameter RESET_CYCLES = 5;
    parameter END_CYCLES = 10;
    
    reg clk;
    reg reset;
    reg [3:0] in_data;
    reg in_valid;
    wire [3:0] out_common;
    
    most_common dut(
        .clk(clk),
        .reset(reset),
        .in_data(in_data),
        .in_valid(in_valid),
        .out_common(out_common)
    );
    
    // 10 unit period clock, start high
    initial begin
        clk = 1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // apply reset cleanly for 5 cycles
    task apply_reset;
        integer i;
        begin
            @(posedge clk);
            $display("Time %0t: apply reset", $time);
            reset = 1;
            for (i = 0; i < RESET_CYCLES; i = i + 1) @(posedge clk);
            reset = 0;
            @(posedge clk); // one clean cycle after reset
        end
    endtask
    
    task send_data(input [3:0] data);
        begin
            @(posedge clk);
            in_data = data;
            $display("Time %0t: set in_data = %0d", $time, data);
        end
    endtask
    
    task data_valid;
        begin
            @(posedge clk);
            in_valid = 1;
            $display("Time %0t: data set to valid", $time);
        end
    endtask
    
    task data_invalid;
        begin
            @(posedge clk);
            in_valid = 0;
            $display("Time %0t: data set to invalid", $time);
        end
    endtask
    
    // --------------main simulation code--------------
    integer start_simulation = 0;
    integer simulation_done = 0;
    
    
    initial begin
        apply_reset();
        start_simulation = 1;
    end
    
    // #### driver ####
    initial begin
        wait (start_simulation == 1);
        data_valid();
        send_data(4'd0);
        send_data(4'd1);
        send_data(4'd2);
        send_data(4'd3);
        send_data(4'd1);
        send_data(4'd2);
        send_data(4'd2);
        send_data(4'd3);
        repeat (4) @(posedge clk);
        send_data(4'd4);
        repeat (8) @(posedge clk);
        data_invalid();
        apply_reset();
        simulation_done = 1;
    end
    
    // #### monitor ####
    initial begin
        wait (start_simulation == 1);
        $display("Time %0t: simulation started", $time);
        forever begin
            @(posedge clk);
            #1;
            $display("Time %0t: out_common = %0d", $time, out_common);
        end
    end
    
    // #### scoreboard ####
    
    integer correct_counter[15:0];
    integer i, max;
    reg [3:0] expected_common;
    reg check_next_cycle;
    initial begin
        for (i = 0; i < 16; i = i + 1) correct_counter[i] = 0;
        expected_common = 4'd0;
    end
    
    initial begin
        wait (start_simulation == 1);
        forever begin 
            @(posedge clk);
            
            if (check_next_cycle) begin
                max = correct_counter[0];
                expected_common = 0;
                for (i = 1; i < 16; i = i + 1) begin
                    if (correct_counter[i] > max) begin
                        max = correct_counter[i];
                        expected_common = i[3:0];
                    end
                end
            end
            
            if (reset) begin
                for (i = 0; i < 16; i = i + 1) correct_counter[i] = 0;
                expected_common = 4'd0;
                check_next_cycle = 0;
            end else if (in_valid) begin
                correct_counter[in_data] = correct_counter[in_data] + 1;
                check_next_cycle = 1;
            end else begin
                check_next_cycle = 0;
            end
            
            #1;
            if (out_common !== expected_common) begin
                $display("ERROR at time %0t: expected %0d, got %0d", $time, expected_common, out_common);
            end
        end
    end
    
    // #### end sim ####
    initial begin
        wait (simulation_done == 1);
        repeat (END_CYCLES) @(posedge clk); // wait 10 cycles before ending
        $display("Simulation finished at time %0t", $time);
        $finish;
    end
    
endmodule
