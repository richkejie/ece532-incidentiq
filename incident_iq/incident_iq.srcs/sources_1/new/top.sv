`timescale 1ns / 1ps

module top(
    input   logic           CLK,        // board clock crystal (100 MHZ?)
    input   logic           ARESET_N    // reset button (async active low)
    
    // outputs?
    );
    
    // --- internal wires ---
    
    // --- system top wrapper ---
    system_top_wrapper u_system_bd(
        
    );
    
    // --- data packager ---
    data_packager u_packager(
        .clk                (CLK),
        .arst_n             (ARESET_N),
        .poll_trigger       (),
        .i_gps              (),
        .i_accel            (),
        .i_gyro             (),
        .i_temp             (),
        .o_packaged_word    (),
        .o_valid            (),
        .o_addr             ()
    );
    
endmodule
