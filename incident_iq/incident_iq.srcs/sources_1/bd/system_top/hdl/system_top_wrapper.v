//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Wed Mar  4 21:32:50 2026
//Host        : Richard_PC running 64-bit major release  (build 9200)
//Command     : generate_target system_top_wrapper.bd
//Design      : system_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_top_wrapper
   (M_AXI_registers_araddr,
    M_AXI_registers_arprot,
    M_AXI_registers_arready,
    M_AXI_registers_arvalid,
    M_AXI_registers_awaddr,
    M_AXI_registers_awprot,
    M_AXI_registers_awready,
    M_AXI_registers_awvalid,
    M_AXI_registers_bready,
    M_AXI_registers_bresp,
    M_AXI_registers_bvalid,
    M_AXI_registers_rdata,
    M_AXI_registers_rready,
    M_AXI_registers_rresp,
    M_AXI_registers_rvalid,
    M_AXI_registers_wdata,
    M_AXI_registers_wready,
    M_AXI_registers_wstrb,
    M_AXI_registers_wvalid,
    clk_out1,
    cpu_reset_n,
    crash_interrupt_in,
    data_packet_bram_port_addr,
    data_packet_bram_port_clk,
    data_packet_bram_port_din,
    data_packet_bram_port_dout,
    data_packet_bram_port_en,
    data_packet_bram_port_rst,
    data_packet_bram_port_we,
    sys_clock);
  output [31:0]M_AXI_registers_araddr;
  output [2:0]M_AXI_registers_arprot;
  input [0:0]M_AXI_registers_arready;
  output [0:0]M_AXI_registers_arvalid;
  output [31:0]M_AXI_registers_awaddr;
  output [2:0]M_AXI_registers_awprot;
  input [0:0]M_AXI_registers_awready;
  output [0:0]M_AXI_registers_awvalid;
  output [0:0]M_AXI_registers_bready;
  input [1:0]M_AXI_registers_bresp;
  input [0:0]M_AXI_registers_bvalid;
  input [31:0]M_AXI_registers_rdata;
  output [0:0]M_AXI_registers_rready;
  input [1:0]M_AXI_registers_rresp;
  input [0:0]M_AXI_registers_rvalid;
  output [31:0]M_AXI_registers_wdata;
  input [0:0]M_AXI_registers_wready;
  output [3:0]M_AXI_registers_wstrb;
  output [0:0]M_AXI_registers_wvalid;
  output clk_out1;
  input cpu_reset_n;
  input [0:0]crash_interrupt_in;
  input [31:0]data_packet_bram_port_addr;
  input data_packet_bram_port_clk;
  input [31:0]data_packet_bram_port_din;
  output [31:0]data_packet_bram_port_dout;
  input data_packet_bram_port_en;
  input data_packet_bram_port_rst;
  input [3:0]data_packet_bram_port_we;
  input sys_clock;

  wire [31:0]M_AXI_registers_araddr;
  wire [2:0]M_AXI_registers_arprot;
  wire [0:0]M_AXI_registers_arready;
  wire [0:0]M_AXI_registers_arvalid;
  wire [31:0]M_AXI_registers_awaddr;
  wire [2:0]M_AXI_registers_awprot;
  wire [0:0]M_AXI_registers_awready;
  wire [0:0]M_AXI_registers_awvalid;
  wire [0:0]M_AXI_registers_bready;
  wire [1:0]M_AXI_registers_bresp;
  wire [0:0]M_AXI_registers_bvalid;
  wire [31:0]M_AXI_registers_rdata;
  wire [0:0]M_AXI_registers_rready;
  wire [1:0]M_AXI_registers_rresp;
  wire [0:0]M_AXI_registers_rvalid;
  wire [31:0]M_AXI_registers_wdata;
  wire [0:0]M_AXI_registers_wready;
  wire [3:0]M_AXI_registers_wstrb;
  wire [0:0]M_AXI_registers_wvalid;
  wire clk_out1;
  wire cpu_reset_n;
  wire [0:0]crash_interrupt_in;
  wire [31:0]data_packet_bram_port_addr;
  wire data_packet_bram_port_clk;
  wire [31:0]data_packet_bram_port_din;
  wire [31:0]data_packet_bram_port_dout;
  wire data_packet_bram_port_en;
  wire data_packet_bram_port_rst;
  wire [3:0]data_packet_bram_port_we;
  wire sys_clock;

  system_top system_top_i
       (.M_AXI_registers_araddr(M_AXI_registers_araddr),
        .M_AXI_registers_arprot(M_AXI_registers_arprot),
        .M_AXI_registers_arready(M_AXI_registers_arready),
        .M_AXI_registers_arvalid(M_AXI_registers_arvalid),
        .M_AXI_registers_awaddr(M_AXI_registers_awaddr),
        .M_AXI_registers_awprot(M_AXI_registers_awprot),
        .M_AXI_registers_awready(M_AXI_registers_awready),
        .M_AXI_registers_awvalid(M_AXI_registers_awvalid),
        .M_AXI_registers_bready(M_AXI_registers_bready),
        .M_AXI_registers_bresp(M_AXI_registers_bresp),
        .M_AXI_registers_bvalid(M_AXI_registers_bvalid),
        .M_AXI_registers_rdata(M_AXI_registers_rdata),
        .M_AXI_registers_rready(M_AXI_registers_rready),
        .M_AXI_registers_rresp(M_AXI_registers_rresp),
        .M_AXI_registers_rvalid(M_AXI_registers_rvalid),
        .M_AXI_registers_wdata(M_AXI_registers_wdata),
        .M_AXI_registers_wready(M_AXI_registers_wready),
        .M_AXI_registers_wstrb(M_AXI_registers_wstrb),
        .M_AXI_registers_wvalid(M_AXI_registers_wvalid),
        .clk_out1(clk_out1),
        .cpu_reset_n(cpu_reset_n),
        .crash_interrupt_in(crash_interrupt_in),
        .data_packet_bram_port_addr(data_packet_bram_port_addr),
        .data_packet_bram_port_clk(data_packet_bram_port_clk),
        .data_packet_bram_port_din(data_packet_bram_port_din),
        .data_packet_bram_port_dout(data_packet_bram_port_dout),
        .data_packet_bram_port_en(data_packet_bram_port_en),
        .data_packet_bram_port_rst(data_packet_bram_port_rst),
        .data_packet_bram_port_we(data_packet_bram_port_we),
        .sys_clock(sys_clock));
endmodule
