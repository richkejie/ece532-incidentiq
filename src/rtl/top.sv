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
    
    logic system_top_clk_out1;

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
    
    logic M_AXI_registers_s_axil_awready;
    logic M_AXI_registers_s_axil_awvalid;
    logic [3:0] M_AXI_registers_s_axil_awaddr;
    logic [2:0] M_AXI_registers_s_axil_awprot;
    logic M_AXI_registers_s_axil_wready;
    logic M_AXI_registers_s_axil_wvalid;
    logic [31:0] M_AXI_registers_s_axil_wdata;
    logic [3:0] M_AXI_registers_s_axil_wstrb;
    logic M_AXI_registers_s_axil_bready;
    logic M_AXI_registers_s_axil_bvalid;
    logic [1:0] M_AXI_registers_s_axil_bresp;
    logic M_AXI_registers_s_axil_arready;
    logic M_AXI_registers_s_axil_arvalid;
    logic [3:0] M_AXI_registers_s_axil_araddr;
    logic [2:0] M_AXI_registers_s_axil_arprot;
    logic M_AXI_registers_s_axil_rready;
    logic M_AXI_registers_s_axil_rvalid;
    logic [31:0] M_AXI_registers_s_axil_rdata;
    logic [1:0] M_AXI_registers_s_axil_rresp;

    registers_pkg::registers__in_t whwif_in;
    registers_pkg::registers__out_t whwif_out;

    // --- register file ---
    registers u_reg_file(
        .clk(system_top_clk_out1),
        .arst_n(ARESET_N),
        .s_axil_awready(M_AXI_registers_s_axil_awready),
        .s_axil_awvalid(M_AXI_registers_s_axil_awvalid),
        .s_axil_awaddr(M_AXI_registers_s_axil_awaddr),
        .s_axil_awprot(M_AXI_registers_s_axil_awprot),
        .s_axil_wready(M_AXI_registers_s_axil_wready),
        .s_axil_wvalid(M_AXI_registers_s_axil_wvalid),
        .s_axil_wdata(M_AXI_registers_s_axil_wdata),
        .s_axil_wstrb(M_AXI_registers_s_axil_wstrb),
        .s_axil_bready(M_AXI_registers_s_axil_bready),
        .s_axil_bvalid(M_AXI_registers_s_axil_bvalid),
        .s_axil_bresp(M_AXI_registers_s_axil_bresp),
        .s_axil_arready(M_AXI_registers_s_axil_arready),
        .s_axil_arvalid(M_AXI_registers_s_axil_arvalid),
        .s_axil_araddr(M_AXI_registers_s_axil_araddr),
        .s_axil_arprot(M_AXI_registers_s_axil_arprot),
        .s_axil_rready(M_AXI_registers_s_axil_rready),
        .s_axil_rvalid(M_AXI_registers_s_axil_rvalid),
        .s_axil_rdata(M_AXI_registers_s_axil_rdata),
        .s_axil_rresp(M_AXI_registers_s_axil_rresp),
        .hwif_in(whwif_in),
        .hwif_out(whwif_out)
    );

    // --- system top ---
    system_top_wrapper u_system_top(
        .sys_clock(CLK),
        .cpu_reset_n(ARESET_N),
        .clk_out1(system_top_clk_out1),
        .M_AXI_registers_araddr(M_AXI_registers_s_axil_araddr),
        .M_AXI_registers_arprot(M_AXI_registers_s_axil_arprot),
        .M_AXI_registers_arready(M_AXI_registers_s_axil_arready),
        .M_AXI_registers_arvalid(M_AXI_registers_s_axil_arvalid),
        .M_AXI_registers_awaddr(M_AXI_registers_s_axil_awaddr),
        .M_AXI_registers_awprot(M_AXI_registers_s_axil_awprot),
        .M_AXI_registers_awready(M_AXI_registers_s_axil_awready),
        .M_AXI_registers_awvalid(M_AXI_registers_s_axil_awvalid),
        .M_AXI_registers_bready(M_AXI_registers_s_axil_bready),
        .M_AXI_registers_bresp(M_AXI_registers_s_axil_bresp),
        .M_AXI_registers_bvalid(M_AXI_registers_s_axil_bvalid),
        .M_AXI_registers_rdata(M_AXI_registers_s_axil_rdata),
        .M_AXI_registers_rready(M_AXI_registers_s_axil_rready),
        .M_AXI_registers_rresp(M_AXI_registers_s_axil_rresp),
        .M_AXI_registers_rvalid(M_AXI_registers_s_axil_rvalid),
        .M_AXI_registers_wdata(M_AXI_registers_s_axil_wdata),
        .M_AXI_registers_wready(M_AXI_registers_s_axil_wready),
        .M_AXI_registers_wstrb(M_AXI_registers_s_axil_wstrb),
        .M_AXI_registers_wvalid(M_AXI_registers_s_axil_wvalid),
        .crash_interrupt_in(),
        .data_packet_bram_port_addr(),
        .data_packet_bram_port_clk(),
        .data_packet_bram_port_din(),
        .data_packet_bram_port_dout(),
        .data_packet_bram_port_en(),
        .data_packet_bram_port_rst(),
        .data_packet_bram_port_we()
    );

    // --- sensor polling ---
    PollingModule u_sensor_polling(
        .clk                (system_top_clk_out1),
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
        .clk                (system_top_clk_out1),
        .arst_n             (ARESET_N),
        
        .i_accel_valid      (spi0_output_valid),
        .i_accel_z          (spi0_out_dataZ),
        .i_accel_y          (spi0_out_dataY),
        .i_accel_x          (spi0_out_dataX),
        
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

        .o_data_packet_bram_write_ptr(whwif_in.WRITE_PTR.WPTR.next),
        .o_data_packet_bram_status_empty(whwif_in.STATUS.EMPTY.next),
        .o_data_packet_bram_status_full(whwif_in.STATUS.FULL.next),
        .i_data_packet_bram_read_ptr(whwif_out.READ_PTR.RPTR.value),
        
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
        .clk                (system_top_clk_out1),
        .arst_n             (ARESET_N),
        .i_state_rst        (1'b0),                 // don't use this reset, since don't have microblaze stuff setup
        .i_sensors_valid    (w_packet_valid),
        
        .i_gps              (),
        
        .i_accel_z          (w_accel_z),
        .i_accel_y          (w_accel_y),
        .i_accel_x          (w_accel_x),
        
        .i_gyro_z           (w_gyro_z),
        .i_gyro_y           (w_gyro_y),
        .i_gyro_x           (w_gyro_x),
        
        .i_delta            (),
        
        .ireg_speed_threshold                   (),
        .ireg_non_fatal_accel_threshold         (),
        .ireg_fatal_accel_threshold             (),
        .ireg_angle_threshold                   (),
        .ireg_angle_in_motion_threshold         (),
        .ireg_angular_speed_threshold           (),
        
        .o_state            (w_cd_state),
        .o_non_fatal_intr   (w_non_fatal_crash_led),
        .o_fatal_intr       (w_fatal_crash_led)
    );

    
endmodule
