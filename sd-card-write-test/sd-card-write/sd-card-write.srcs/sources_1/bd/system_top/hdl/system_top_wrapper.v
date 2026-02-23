//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Mon Feb 23 11:15:25 2026
//Host        : Richard_PC running 64-bit major release  (build 9200)
//Command     : generate_target system_top_wrapper.bd
//Design      : system_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_top_wrapper
   (acl_spi_io0_io,
    acl_spi_io1_io,
    acl_spi_sck_io,
    acl_spi_ss_io,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  inout acl_spi_io0_io;
  inout acl_spi_io1_io;
  inout acl_spi_sck_io;
  inout acl_spi_ss_io;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire acl_spi_io0_i;
  wire acl_spi_io0_io;
  wire acl_spi_io0_o;
  wire acl_spi_io0_t;
  wire acl_spi_io1_i;
  wire acl_spi_io1_io;
  wire acl_spi_io1_o;
  wire acl_spi_io1_t;
  wire acl_spi_sck_i;
  wire acl_spi_sck_io;
  wire acl_spi_sck_o;
  wire acl_spi_sck_t;
  wire acl_spi_ss_i;
  wire acl_spi_ss_io;
  wire acl_spi_ss_o;
  wire acl_spi_ss_t;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  IOBUF acl_spi_io0_iobuf
       (.I(acl_spi_io0_o),
        .IO(acl_spi_io0_io),
        .O(acl_spi_io0_i),
        .T(acl_spi_io0_t));
  IOBUF acl_spi_io1_iobuf
       (.I(acl_spi_io1_o),
        .IO(acl_spi_io1_io),
        .O(acl_spi_io1_i),
        .T(acl_spi_io1_t));
  IOBUF acl_spi_sck_iobuf
       (.I(acl_spi_sck_o),
        .IO(acl_spi_sck_io),
        .O(acl_spi_sck_i),
        .T(acl_spi_sck_t));
  IOBUF acl_spi_ss_iobuf
       (.I(acl_spi_ss_o),
        .IO(acl_spi_ss_io),
        .O(acl_spi_ss_i),
        .T(acl_spi_ss_t));
  system_top system_top_i
       (.acl_spi_io0_i(acl_spi_io0_i),
        .acl_spi_io0_o(acl_spi_io0_o),
        .acl_spi_io0_t(acl_spi_io0_t),
        .acl_spi_io1_i(acl_spi_io1_i),
        .acl_spi_io1_o(acl_spi_io1_o),
        .acl_spi_io1_t(acl_spi_io1_t),
        .acl_spi_sck_i(acl_spi_sck_i),
        .acl_spi_sck_o(acl_spi_sck_o),
        .acl_spi_sck_t(acl_spi_sck_t),
        .acl_spi_ss_i(acl_spi_ss_i),
        .acl_spi_ss_o(acl_spi_ss_o),
        .acl_spi_ss_t(acl_spi_ss_t),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
