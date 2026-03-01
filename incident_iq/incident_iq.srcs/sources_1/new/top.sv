`timescale 1ns / 1ps

module top(
    input   logic           CLK,        // board clock crystal (100 MHZ?)
    input   logic           ARESET_N    // reset button (sync active high)
    
    // outputs?
    );
    
    // --- internal wires ---
    logic [63:0] w_data_packet;
    logic w_data_packet_valid;
    
//    logic [31:0] w_data_packet_bram_addr;
//    logic [31:0] w_data_packet_bram_din;
//    logic [3:0] w_data_packet_bram_we;
//    logic w_data_packet_bram_en;
    
    // for mid-project-demo, don't worry about microblaze stuff
    
    // --- system top wrapper ---
//    system_top_wrapper u_system_top(
//        .diff_clock_rtl_clk_n(), // differential clock n --- determine where to connect on board
//        .diff_clock_rtl_clk_p(), // differential clock p
//        .aresetn(ARESET_N),
        
//        // data_packet_mem BRAM_PORTB
//        .data_packet_bram_port_addr(w_data_packet_bram_addr),
//        .data_packet_bram_port_clk(CLK),
//        .data_packet_bram_port_din(w_data_packet_bram_din),
//        .data_packet_bram_port_dout(),      // unconnected, data packager does not need to read from the buffer
//        .data_packet_bram_port_en(w_data_packet_bram_en),
//        .data_packet_bram_port_rst(ARESET_N),  // resets dout, so not necessary since not reading
//        .data_packet_bram_port_we(w_data_packet_bram_we)         // 4-byte we   
//    );
    
    // -- crash detection ---
    crash_detection u_crash_detection(
        .clk(CLK),
        .arst_n(ARESET_N),
        .i_packet(w_data_packet),
        .i_packet_valid(w_data_packet_valid),
        .i_accel_threshold(),
        .i_orient_threshold(),
        .i_temp_threshold(),
        .o_crash_detected()
    );
    
    // --- data packager ---
    data_packager u_data_packager(
        .clk                (CLK),
        .rst                (ARESET_N),
        
        .i_accel_valid      (spi0_output_valid),
        .i_accel_z          (spi0_out_dataZ),
        .i_accel_y          (spi0_out_dataY),
        .i_accel_x          (spi0_out_dataX),
        
        .i_gps              (),             // from u_sensor_polling
        
        .i_gyro_valid       (spi1_output_valid),
        .i_gyro_z           (spi1_out_dataZ),
        .i_gyro_y           (spi1_out_dataY),
        .i_gyro_x           (spi1_out_dataX),
        
        .i_temp             (),             // from u_sensor_polling
        .i_delta            (),             // from u_sensor_polling
        
        .o_packet           (w_data_packet),
        .o_packet_valid     (w_data_packet_valid),
        
        // BRAM interface
        .o_data_packet_bram_addr(),
        .o_data_packet_bram_din(),
        .o_data_packet_bram_we(),
        .o_data_packet_bram_en(),
        
        // Crash Detection interface
        .o_cd_accel_max     (cd_accel_max),
        .o_cd_gyro_max      (cd_gyro_max)
    );
    
    // --- sensor polling ---
    sensor_polling u_sensor_polling(
    
    );
    
    // --- sensors top ---
    sensors_top u_sensors_top(
    
    );
    
endmodule
