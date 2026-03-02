// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
// Date        : Mon Mar  2 11:36:48 2026
// Host        : ug170 running 64-bit Debian GNU/Linux 12 (bookworm)
// Command     : write_verilog -force -mode synth_stub
//               /nfs/ug/homes-4/w/wuricha8/ece532/ece532-incidentiq/incident_iq/incident_iq.srcs/sources_1/ip/ila_0/ila_0_stub.v
// Design      : ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2018.3" *)
module ila_0(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13, probe14)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[1:0],probe3[15:0],probe4[15:0],probe5[15:0],probe6[15:0],probe7[15:0],probe8[15:0],probe9[15:0],probe10[15:0],probe11[15:0],probe12[15:0],probe13[31:0],probe14[31:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [1:0]probe2;
  input [15:0]probe3;
  input [15:0]probe4;
  input [15:0]probe5;
  input [15:0]probe6;
  input [15:0]probe7;
  input [15:0]probe8;
  input [15:0]probe9;
  input [15:0]probe10;
  input [15:0]probe11;
  input [15:0]probe12;
  input [31:0]probe13;
  input [31:0]probe14;
endmodule
