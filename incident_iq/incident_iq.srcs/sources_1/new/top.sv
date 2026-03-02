`timescale 1ns / 1ps

module top(
    input   logic           CLK,        // board clock crystal (100 MHZ?)
    input   logic           ARESET_N,    // reset button (async active low)
    
    input  wire BTNC,       // button for your FSM1/FSM2 reset behavior (PollingModule
    
    // SPI0 physical pins (on-board accelerometer)
    input  wire MISO_0,
    output wire MOSI_0,
    output wire SCK_0,
    output wire CS_n_0,
    
    // SPI1 physical pins (gyroscope)
    input  wire MISO_1,
    output wire MOSI_1,
    output wire SCK_1,
    output wire CS_n_1,
    
    // GPS UART RX pin
    input  wire gps_rx,
    
    // LED outputs
    output  logic [1:0]     LED_CD_STATE,
    output  logic           LED_NON_FATAL_CRASH,
    output  logic           LED_FATAL_CRASH
    );
    
    // --- LEDS ---
    logic [1:0]     w_cd_state;
    logic           w_non_fatal_crash_led, w_fatal_crash_led;
    
    assign LED_CD_STATE         = w_cd_state;
    assign LED_NON_FATAL_CRASH  = w_non_fatal_crash_led;
    assign LED_FATAL_CRASH      = w_fatal_crash_led;
    
    // --- internal wires ---
    wire spi0_output_valid;
    wire spi1_output_valid;
    wire uart_valid;

    wire [15:0] spi0_out_dataX, spi0_out_dataY, spi0_out_dataZ;
    wire [15:0] spi1_out_dataX, spi1_out_dataY, spi1_out_dataZ;
    wire [1023:0] out_sentence_captured;
    
    logic           w_packet_valid;
    logic           w_data_recv;
    logic [15:0]    w_accel_z, w_accel_y, w_accel_x;
    logic [15:0]    w_gyro_z, w_gyro_y, w_gyro_x;
    

    // --- sensor polling ---
    PollingModule u_sensor_polling(
        .clk                (CLK),
        .reset_top          (~ARESET_N),          // should change to async active low (is currently sync active high)
        
        .spi0_output_valid  (spi0_output_valid),
        .CS_n_0             (CS_n_0),
        .MOSI_0             (MOSI_0),
        .MISO_0             (MISO_0),
        .SCK_0              (SCK_0),
        
        .spi1_output_valid  (spi1_output_valid),
        .CS_n_1             (CS_n_1),
        .MOSI_1             (MOSI_1),
        .MISO_1             (MISO_1),
        .SCK_1              (SCK_1),
        
//        .DATA_RECV          (w_data_recv),             // ? 
        
        .spi0_out_dataZ     (spi0_out_dataZ),
        .spi0_out_dataY     (spi0_out_dataY),
        .spi0_out_dataX     (spi0_out_dataX),
        
        .spi1_out_dataZ     (spi1_out_dataZ),
        .spi1_out_dataY     (spi1_out_dataY),
        .spi1_out_dataX     (spi1_out_dataX),
        
        .BTNC               (BTNC),
        
        .uart_valid         (uart_valid),
        .out_sentence_captured  (out_sentence_captured),
        .gps_rx             (gps_rx)
    );
    
    // --- data packager ---
    data_packager u_data_packager(
        .clk                (CLK),
        .rst                (ARESET_N),
        
        .i_accel_valid      (spi0_output_valid),
        .i_accel_z          (spi0_out_dataZ),
        .i_accel_y          (spi0_out_dataY),
        .i_accel_x          (spi0_out_dataX),
        
//        .i_gps              (),             // from u_sensor_polling
        .i_gps_valid        (uart_valid),
        .i_gps_sentence     (out_sentence_captured),
        
        .i_gyro_valid       (spi1_output_valid),
        .i_gyro_z           (spi1_out_dataZ),
        .i_gyro_y           (spi1_out_dataY),
        .i_gyro_x           (spi1_out_dataX),
        
        .o_data_recv        (w_data_recv),
        
        .o_packet           (), // not needed right now
        .o_packet_valid     (w_packet_valid),
        
        // BRAM interface --- don't connect to microblaze stuff for now
        .o_data_packet_bram_addr(),
        .o_data_packet_bram_din(),
        .o_data_packet_bram_we(),
        .o_data_packet_bram_en(),
        
        // crash detection interface
        .o_cd_accel_z       (w_accel_z),
        .o_cd_accel_y       (w_accel_y),
        .o_cd_accel_x       (w_accel_x),
        .o_cd_gyro_z        (w_gyro_z),
        .o_cd_gyro_y        (w_gyro_y),
        .o_cd_gyro_x        (w_gyro_x)
    );
    
        // -- crash detection ---
    crash_detection u_crash_detection(
        .clk                (CLK),
        .arst_n             (ARESET_N),
        .i_state_rst        (1'b0),                 // don't use this reset, since don't have microblaze stuff setup
        .i_sensors_valid    (w_packet_valid),
        
        .i_accel_z          (w_accel_z),
        .i_accel_y          (w_accel_y),
        .i_accel_x          (w_accel_x),
        
        .i_gyro_z           (w_gyro_z),
        .i_gyro_y           (w_gyro_y),
        .i_gyro_x           (w_gyro_x),
        
        .ireg_accel_threshold                   (32'd9800),     // units of micro Gs
        .ireg_angular_speed_threshold           (32'd30),       // units of degrees per second
        
        .o_state            (w_cd_state),
        .o_non_fatal_intr   (w_non_fatal_crash_led),
        .o_fatal_intr       (w_fatal_crash_led)
    );

    
endmodule
