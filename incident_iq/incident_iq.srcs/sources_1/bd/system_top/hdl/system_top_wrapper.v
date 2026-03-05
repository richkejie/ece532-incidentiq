//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Sun Feb 22 18:26:34 2026
//Host        : Richard_PC running 64-bit major release  (build 9200)
//Command     : generate_target system_top_wrapper.bd
//Design      : system_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_top_wrapper
   (areset_n,
    crash_interrupt_in,
    data_packet_bram_port_addr,
    data_packet_bram_port_clk,
    data_packet_bram_port_din,
    data_packet_bram_port_dout,
    data_packet_bram_port_en,
    data_packet_bram_port_rst,
    data_packet_bram_port_we,
    diff_clock_rtl_clk_n,
    diff_clock_rtl_clk_p);
  input areset_n;
  input [0:0]crash_interrupt_in;
  input [31:0]data_packet_bram_port_addr;
  input data_packet_bram_port_clk;
  input [31:0]data_packet_bram_port_din;
  output [31:0]data_packet_bram_port_dout;
  input data_packet_bram_port_en;
  input data_packet_bram_port_rst;
  input [3:0]data_packet_bram_port_we;
  input diff_clock_rtl_clk_n;
  input diff_clock_rtl_clk_p;

  wire areset_n;
  wire [0:0]crash_interrupt_in;
  wire [31:0]data_packet_bram_port_addr;
  wire data_packet_bram_port_clk;
  wire [31:0]data_packet_bram_port_din;
  wire [31:0]data_packet_bram_port_dout;
  wire data_packet_bram_port_en;
  wire data_packet_bram_port_rst;
  wire [3:0]data_packet_bram_port_we;
  wire diff_clock_rtl_clk_n;
  wire diff_clock_rtl_clk_p;

  system_top system_top_i
       (.areset_n(areset_n),
        .crash_interrupt_in(crash_interrupt_in),
        .data_packet_bram_port_addr(data_packet_bram_port_addr),
        .data_packet_bram_port_clk(data_packet_bram_port_clk),
        .data_packet_bram_port_din(data_packet_bram_port_din),
        .data_packet_bram_port_dout(data_packet_bram_port_dout),
        .data_packet_bram_port_en(data_packet_bram_port_en),
        .data_packet_bram_port_rst(data_packet_bram_port_rst),
        .data_packet_bram_port_we(data_packet_bram_port_we),
        .diff_clock_rtl_clk_n(diff_clock_rtl_clk_n),
        .diff_clock_rtl_clk_p(diff_clock_rtl_clk_p));
endmodule
