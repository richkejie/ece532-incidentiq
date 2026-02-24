`timescale 1ns / 1ps

// axi vip imports
import axi_vip_pkg::*;
import verif_data_packet_write_axi_vip_0_0_pkg::*;

module axi_vip_mst_tests();

    // define axi agent
    verif_data_packet_write_axi_vip_0_0_mst_t       agent;

    // axi related variables
    xil_axi_data_beat                               rd_data[];

    // address offsets --- check address editor
    localparam DATA_PACKET_BASE_ADDR        = 32'h0000_0000;
    localparam TB_TEST_ADDR                 = DATA_PACKET_BASE_ADDR + 4;

    initial begin
        // create and start agent
        agent = new("master vip agent", u_verif_system_top.verif_data_packet_write_i.axi_vip_0.inst.IF);
        agent.start_master();

        wait(data_packet_write_tb.start_simulation == 1);

        $display("%0t: [TB] Writing 32'd0 to address 32'h0000_0004", $time);
        write_bram(TB_TEST_ADDR, 32'd0);
        agent.wait_drivers_idle();
        $display("%0t: [TB] Write Complete", $time);

        // Test Case 1: Send a basic packet
        $display("%0t: TC1: Sending Sample 1..., should write to address 32'h0000_0004", $time);
        data_packet_write_tb.send_sample(16'hAAAA, 16'hBBBB, 16'hCCCC, 8'hDD, 8'hEE);

        repeat(10) @(posedge data_packet_write_tb.clk);
        $display("%0t: [TB] Reading back from address 32'h0000_0004", $time);
        read_bram(TB_TEST_ADDR, rd_data);
        $display("%0t: [TB] rdata: %0x", $time, rd_data[0]);

        // $display("%0t: [TB] Writing 32'd169 to address 32'h0000_0000", $time);
        // write_bram(TB_TEST_ADDR, 32'd169);
        // agent.wait_drivers_idle();
        // $display("%0t: [TB] Write Complete", $time);

        // $display("%0t: [TB] Reading back from address 32'h0000_0000", $time);
        // read_bram(TB_TEST_ADDR, rd_data);

        // // verify
        // if (rd_data[0] == 32'd169)
        //     $display("[TB] PASS - Read data matches: %0d", rd_data[0]);
        // else
        //     $display("[TB] FAIL - Expected 169, got %0d", rd_data[0]);

        repeat(10) @(posedge data_packet_write_tb.clk);
        $finish;

    end

    // write task
    task automatic write_bram(input bit [31:0] addr, input bit [31:0] data);
        axi_transaction wr;
        
        $display("%0t: [TB] Write Start", $time);
        wr = agent.wr_driver.create_transaction("write");
        wr.set_write_cmd(addr, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(XIL_AXI_SIZE_4BYTE));
        wr.set_data_block(data);
        agent.wr_driver.send(wr);
    endtask

    // read task
    task automatic read_bram(input bit [31:0] addr, output xil_axi_data_beat data[]);
        axi_transaction rd;

        $display("%0t: [TB] Read Start", $time);
        rd = agent.rd_driver.create_transaction("read");
        rd.set_read_cmd(addr, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(XIL_AXI_SIZE_4BYTE));
        
        rd.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
        agent.rd_driver.send(rd);
        agent.rd_driver.wait_rsp(rd);

        data = new[rd.get_len()+1];
        for ( xil_axi_uint beat=0; beat < rd.get_len()+1; beat++ ) begin
            data[beat] = rd.get_data_beat(beat);
        end

        $display("%0t: [TB] Read Complete, data = %0x", $time, data[0]);
    endtask



endmodule

module data_packet_write_tb();

    parameter CLK_PERIOD = 10;
    parameter RESET_CYCLES = 20;

    logic clk;
    logic arst_n;

    // inputs to data_packager
    logic           in_valid;
    logic [15:0]    i_gps;
    logic [15:0]    i_accel;
    logic [15:0]    i_gyro;
    logic [7:0]     i_temp;
    logic [7:0]     i_delta;

    // outputs from data_packager
    logic [63:0]    o_packet;
    logic           o_packet_valid;
    logic [31:0]    o_data_packet_bram_addr;
    logic [31:0]    o_data_packet_bram_din;
    logic [3:0]     o_data_packet_bram_we;
    logic           o_data_packet_bram_en;
    
    data_packager u_data_packager(
        .clk(clk),
        .arst_n(arst_n),
        .in_valid(in_valid),
        .i_gps(i_gps),
        .i_accel(i_accel),
        .i_gyro(i_gyro),
        .i_temp(i_temp),
        .i_delta(i_delta),
        .o_packet(o_packet),
        .o_packet_valid(o_packet_valid),
        .o_data_packet_bram_addr(o_data_packet_bram_addr),
        .o_data_packet_bram_din(o_data_packet_bram_din),
        .o_data_packet_bram_we(o_data_packet_bram_we),
        .o_data_packet_bram_en(o_data_packet_bram_en)
    );
    
    verif_data_packet_write_wrapper u_verif_system_top(
        .aresetn(arst_n),
        .data_packet_bram_port_addr(o_data_packet_bram_addr),
        .data_packet_bram_port_clk(clk),
        .data_packet_bram_port_din(o_data_packet_bram_din),
        .data_packet_bram_port_dout(),  // not used
        .data_packet_bram_port_en(o_data_packet_bram_en),
        .data_packet_bram_port_rst(arst_n),
        .data_packet_bram_port_we(o_data_packet_bram_we),
        .sys_clock(clk)
    );

    // clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // intialize signals
    task init;
        in_valid = 0;
        i_gps = 0; i_accel = 0; i_gyro = 0; i_temp = 0; i_delta = 0;
    endtask

    // apply reset cleanly for 5 cycles
    task apply_reset;
        $display("%0t: apply reset", $time);
        arst_n = 0;
        repeat (RESET_CYCLES) @(posedge clk);
        arst_n = 1;
        repeat (RESET_CYCLES) @(posedge clk);
    endtask

    // send a sensor sample
    task send_sample(
        input [15:0] gps,
        input [15:0] accel,
        input [15:0] gyro,
        input [7:0] temp,
        input [7:0] delta
    );
        begin
            @(posedge clk);
            i_gps       <= gps;
            i_accel     <= accel;
            i_gyro      <= gyro;
            i_temp      <= temp;
            i_delta     <= delta;
            @(posedge clk);
            in_valid    <= 1'b1;
            @(posedge clk);
            in_valid    <= 1'b0;
        end
    endtask

    // --------------main simulation code--------------
    integer start_simulation = 0;
    integer simulation_done = 0;
    
    initial begin
        init();
        apply_reset();
        start_simulation = 1;
    end
    
    axi_vip_mst_tests mst();
    
endmodule
