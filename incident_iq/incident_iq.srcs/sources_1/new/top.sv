`timescale 1ns / 1ps

module top(
    input   logic           CLK,        // board clock crystal (100 MHZ?)
    input   logic           RESET       // reset button (sync active high)
    
    // outputs?
    );
    
    // --- internal wires ---
    
    // --- system top wrapper ---
    system_top_wrapper u_system_top(
        
    );
    
    // -- crash detection ---
    crash_detection u_crash_detection(
    
    );
    
    // --- data packager ---
    data_packager u_data_packager(
        .clk                (CLK),
        .rst                (RESET),
        .poll_trigger       (),
        .i_gps              (),
        .i_accel            (),
        .i_gyro             (),
        .i_temp             (),
        .o_packaged_word    (),
        .o_valid            (),
        .o_addr             ()
    );
    
    // --- sensor polling ---
    sensor_polling u_sensor_polling(
    
    );
    
    // --- sensors top ---
    sensors_top u_sensors_top(
    
    );
    
endmodule
