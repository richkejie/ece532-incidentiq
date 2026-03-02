`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/19/2026 03:12:50 PM
// Design Name: 
// Module Name: PollingModule
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PollingModule(
    input  wire        clk,
    input  wire        reset_top,
    
    output wire         spi0_output_valid, 
    output wire        CS_n_0, 
    output wire        MOSI_0, 
    input wire         MISO_0, 
    output wire        SCK_0, 
    
    output wire         spi1_output_valid, 
    output wire        CS_n_1, 
    output wire        MOSI_1, 
    input wire         MISO_1, 
    output wire        SCK_1, 
    
    //input wire         DATA_RECV, // inputs from the data packer to indicate the information was received from SPI 0 device 
    
    output reg [15:0] spi0_out_dataZ, 
    output reg [15:0] spi0_out_dataY, 
    output reg [15:0] spi0_out_dataX,
    
    output reg [15:0] spi1_out_dataZ, 
    output reg [15:0] spi1_out_dataY, 
    output reg [15:0] spi1_out_dataX, 
    
    input wire BTNC, 
    
    output wire        uart_valid, 
    output reg         [1023:0] out_sentence_captured,   
    input  wire        gps_rx   // PMOD JA pin 3
    
    
    );
    

    
localparam integer CLK_SPEED = 100_000_000;
localparam integer BAUD_RATE = 9600;
localparam integer MAX_BYTES = 128;
    
// 10 hertz counter 
localparam integer DIV = 10000000; // value we are counting to in order to get 10Hz refresh rate  
reg [23:0] cnt = 0;
reg flag_10hz = 0; // flag used to indicate when it is time for the modules to refresh

wire [7:0] spi0_out_data; 
wire [7:0] spi1_out_data; 

reg spi0_reset; 
reg spi1_reset; 
reg uart_reset; 
// Accelerometer FSM 

localparam [4:0]
        F0_IDLE  = 5'd0,
        
        F0_START_XLOW = 5'd1,
        F0_WAIT_XLOW  = 5'd2,
        F0_DONE_XLOW  = 5'd3,
        
        F0_START_XHIGH = 5'd4,
        F0_WAIT_XHIGH  = 5'd5,
        F0_DONE_XHIGH  = 5'd6,
        
        F0_START_YLOW = 5'd7,
        F0_WAIT_YLOW  = 5'd8,
        F0_DONE_YLOW = 5'd9,
        
        F0_START_YHIGH  = 5'd10,
        F0_WAIT_YHIGH = 5'd11,
        F0_DONE_YHIGH  = 5'd12,
        
        F0_START_ZLOW = 5'd13,
        F0_WAIT_ZLOW  = 5'd14,
        F0_DONE_ZLOW  = 5'd15,
        
        F0_START_ZHIGH = 5'd16,
        F0_WAIT_ZHIGH  = 5'd17,
        F0_DONE_ZHIGH  = 5'd18,
        
        
        F0_DONE  = 5'd19;
        
reg [4:0] fsm0_state, fsm0_next;

// Gyroscope FSM 

localparam [4:0]
        F1_IDLE  = 5'd0,
        
        F1_START_XLOW = 5'd1,
        F1_WAIT_XLOW  = 5'd2,
        F1_DONE_XLOW  = 5'd3,
        
        F1_START_XHIGH = 5'd4,
        F1_WAIT_XHIGH  = 5'd5,
        F1_DONE_XHIGH  = 5'd6,
        
        F1_START_YLOW = 5'd7,
        F1_WAIT_YLOW  = 5'd8,
        F1_DONE_YLOW = 5'd9,
        
        F1_START_YHIGH  = 5'd10,
        F1_WAIT_YHIGH = 5'd11,
        F1_DONE_YHIGH  = 5'd12,
        
        F1_START_ZLOW = 5'd13,
        F1_WAIT_ZLOW  = 5'd14,
        F1_DONE_ZLOW  = 5'd15,
        
        F1_START_ZHIGH = 5'd16,
        F1_WAIT_ZHIGH  = 5'd17,
        F1_DONE_ZHIGH  = 5'd18,
        
        
        F1_DONE  = 5'd19;
        
reg [4:0] fsm1_state, fsm1_next;

// UART FSM

localparam [4:0]
        F2_IDLE  = 5'd0,
        
        F2_SAMPLE = 5'd1, 
        
        F2_WAIT = 5'd2, 

        F2_DONE  = 5'd3;
        
reg [4:0] fsm2_state, fsm2_next;

reg uart_sampled; // this is an internal flag that we use to know when we sampled the uart 

// internal SPI control declarations 

reg  [15:0] spi0_in_data, spi1_in_data; 
reg         spi0_CTS, spi1_CTS;
wire        spi0_RTS, spi1_RTS;
reg         spi0_MODE, spi1_MODE;

 reg spi0_RTS_edge, spi1_RTS_edge, uart_output_valid_edge;
 wire spi0_done = (~spi0_RTS_edge) & spi0_RTS;
 wire spi1_done = (~spi1_RTS_edge) & spi1_RTS;
 wire uart_done = (~uart_output_valid_edge) & uart_sampled;

always @(posedge clk) begin 
    if (reset_top) begin 
        spi0_CTS <= 0; 
        spi1_CTS <= 0; 
        spi0_in_data <= 0; 
        spi1_in_data <= 0; 
        cnt <= 0;
        flag_10hz <= 0; 
        // need to reset the FSMs as well 
        
        spi0_RTS_edge <= 0;
        spi1_RTS_edge <= 0;
        uart_output_valid_edge <= 0; 
        
        fsm0_state <= F0_IDLE;
        fsm1_state <= F1_IDLE;
        fsm2_state <= F2_IDLE;
        
        uart_sampled <= 0; 
        
        spi0_out_dataZ <= 0;
        spi0_out_dataY <= 0;
        spi0_out_dataX <= 0;
        
        spi1_out_dataZ <= 0;
        spi1_out_dataY <= 0;
        spi1_out_dataX <= 0;
        
        spi0_reset <= 1;
        spi1_reset <= 1;
        uart_reset <= 1; 
        
        spi0_MODE <= 1;   // use MODE=1 here
        spi1_MODE <= 0;   // use MODE=0 here
        
    end else begin 
        
        uart_reset <= 0; // take the module out of reset 
        fsm0_state <= fsm0_next;
        fsm1_state <= fsm1_next;
        fsm2_state <= fsm2_next;
    
        spi0_RTS_edge <= spi0_RTS;
        spi1_RTS_edge <= spi1_RTS;
        uart_output_valid_edge <= uart_sampled; 
        
        flag_10hz <= 0;
        if (cnt == DIV-1) begin
          cnt       <= 0;
          flag_10hz <= 1;               // 1-cycle pulse every 0.1 s
        end else begin
          cnt <= cnt + 1;
        end
        
        
        // FSM 0 outputs 
        spi0_CTS <= 0; // de-assert this every round 
        case (fsm0_state) 
            F0_START_XLOW: begin 
                spi0_out_dataZ <= 0;
                spi0_out_dataY <= 0;
                spi0_out_dataX <= 0;
                spi0_MODE <= 1; // since this is the onboard value we need 2 transactions 
                spi0_in_data <= 16'h0B0E; // read from X_LOW register value 
                spi0_CTS <= 1; 
                spi0_reset <= 0; // this is when we pull the reset for the module low
            end 
            
            F0_WAIT_XLOW: begin 
                //spi0_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
                 
            end 
            
            F0_START_XHIGH: begin 
                spi0_MODE <= 1; // since this is the onboard value we need 2 transactions 
                spi0_in_data <= 16'h0B0F; // read from X_HIGH register value 
                spi0_CTS <= 1;
            end 
            
            //F0_WAIT_XHIGH: spi0_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F0_START_YLOW: begin 
                spi0_MODE <= 1; // since this is the onboard value we need 2 transactions 
                spi0_in_data <= 16'h0B10; // read from Y_LOW register value 
                spi0_CTS <= 1;
            end 
            
            //F0_WAIT_YLOW: spi0_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F0_START_YHIGH: begin 
                spi0_MODE <= 1; // since this is the onboard value we need 2 transactions 
                spi0_in_data <= 16'h0B11; // read from Y_HIGH register value 
                spi0_CTS <= 1;
            end 
            
            //F0_WAIT_YHIGH: spi0_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F0_START_ZLOW: begin 
                spi0_MODE <= 1; // since this is the onboard value we need 2 transactions 
                spi0_in_data <= 16'h0B12; // read from Z_LOW register value 
                spi0_CTS <= 1;
            end 
            
            //F0_WAIT_ZLOW: spi0_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F0_START_ZHIGH: begin 
                spi0_MODE <= 1; // since this is the onboard value we need 2 transactions 
                spi0_in_data <= 16'h0B13; // read from Z_HIGH register value 
                spi0_CTS <= 1;
            end 
            
            //F0_WAIT_ZHIGH: spi0_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F0_DONE: begin end 
            
         endcase 
         
         // capturing data once we have validated that the transaction ran 
         
         if (fsm0_state == F0_DONE_XLOW && spi0_done) begin 
            spi0_out_dataX[7:0] <= spi0_out_data;    // latch X_LOW
         end 
         
         if (fsm0_state == F0_DONE_XHIGH && spi0_done) begin 
            spi0_out_dataX[15:8] <= spi0_out_data;    // latch X_HIGH
         end 
         
         if (fsm0_state == F0_DONE_YLOW && spi0_done) begin 
            spi0_out_dataY[7:0] <= spi0_out_data;    // latch X_HIGH
         end 
         
         if (fsm0_state == F0_DONE_YHIGH && spi0_done) begin 
            spi0_out_dataY[15:8] <= spi0_out_data;    // latch X_HIGH
         end 
         
         if (fsm0_state == F0_DONE_ZLOW && spi0_done) begin 
            spi0_out_dataZ[7:0] <= spi0_out_data;    // latch X_HIGH
         end 
         
         if (fsm0_state == F0_DONE_ZHIGH && spi0_done) begin 
            spi0_out_dataZ[15:8] <= spi0_out_data;    // latch X_HIGH
         end 

        
        // FSM 1 outputs 
        
        spi1_CTS <= 0; // de-assert this every round 
        case (fsm1_state) 
            F1_START_XLOW: begin 
                spi1_out_dataZ <= 0;
                spi1_out_dataY <= 0;
                spi1_out_dataX <= 0;
                spi1_MODE <= 0; 
                spi1_in_data <= 16'h00A8; // read from X_LOW angular data register value 
                spi1_CTS <= 1; 
                spi1_reset <= 0; // this is when we pull the reset for the module low 
            end 
            
            F1_WAIT_XLOW: begin 
                //spi1_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
                
            end 
            
            F1_START_XHIGH: begin 
                spi1_MODE <= 0;  
                spi1_in_data <= 16'h00A9; // read from X_HIGH register value 
                spi1_CTS <= 1;
            end 
            
            //F0_WAIT_XHIGH: spi1_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F1_START_YLOW: begin 
                spi1_MODE <= 0;  
                spi1_in_data <= 16'h00AA; // read from Y_LOW register value 
                spi1_CTS <= 1;
            end 
            
            //F0_WAIT_YLOW: spi1_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F1_START_YHIGH: begin 
                spi1_MODE <= 0; // since this is the onboard value we need 2 transactions 
                spi1_in_data <= 16'h00AB; // read from Y_HIGH register value 
                spi1_CTS <= 1;
            end 
            
            //F0_WAIT_YHIGH: spi1_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F1_START_ZLOW: begin 
                spi1_MODE <= 0; 
                spi1_in_data <= 16'h00AC; // read from Z_LOW register value 
                spi1_CTS <= 1;
            end 
            
            //F0_WAIT_ZLOW: spi1_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F1_START_ZHIGH: begin 
                spi1_MODE <= 0; 
                spi1_in_data <= 16'h00AD; // read from Z_HIGH register value 
                spi1_CTS <= 1;
            end 
            
            //F0_WAIT_ZHIGH: spi1_CTS <= 1; // in case the RTS did not go low fast enough, keep CTS HIGH
            
            F1_DONE: begin end
            
         endcase 
         
         // capturing data once we have validated that the transaction ran 
         
         if (fsm1_state == F1_DONE_XLOW && spi1_done) begin 
            spi1_out_dataX[7:0] <= spi1_out_data;    // latch X_LOW
         end 
         
         if (fsm1_state == F1_DONE_XHIGH && spi1_done) begin 
            spi1_out_dataX[15:8] <= spi1_out_data;    // latch X_HIGH
         end 
         
         if (fsm1_state == F1_DONE_YLOW && spi1_done) begin 
            spi1_out_dataY[7:0] <= spi1_out_data;    // latch X_HIGH
         end 
         
         if (fsm1_state == F1_DONE_YHIGH && spi1_done) begin 
            spi1_out_dataY[15:8] <= spi1_out_data;    // latch X_HIGH
         end 
         
         if (fsm1_state == F1_DONE_ZLOW && spi1_done) begin 
            spi1_out_dataZ[7:0] <= spi1_out_data;    // latch X_HIGH
         end 
         
         if (fsm1_state == F1_DONE_ZHIGH && spi1_done) begin 
            spi1_out_dataZ[15:8] <= spi1_out_data;    // latch X_HIGH
         end 
         
         // FSM 2 outputs 
         
        uart_sampled <= 0; // reset it when not being actively driven 
        case (fsm2_state) 
            F2_SAMPLE: begin 
               out_sentence_captured <= out_sentence; // actually record the output from the uart sentence constructor 
               uart_sampled <= 1; // set this flag to high 
            end 
            
            F1_DONE: begin end
            
         endcase 
    
    end 
end 

// Combinational Logic for FSM0 next state logic 

always @(*) begin 
    fsm0_next = fsm0_state; // hold the current state by default 
    
    case (fsm0_state) 
        F0_IDLE: begin 
            if (flag_10hz) begin 
                fsm0_next = F0_START_XLOW; // send the message that re need to 
            end 
        end 
        
        F0_START_XLOW: begin 
            if (spi0_RTS) begin 
                fsm0_next = F0_WAIT_XLOW;
            end
        end 
        
        F0_WAIT_XLOW: begin 
            if (!spi0_RTS) begin // can see that the module accepted the data_in given 
                fsm0_next = F0_DONE_XLOW;
            end
        end 
        
        F0_DONE_XLOW: begin 
            if (spi0_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm0_next = F0_START_XHIGH;
            end 
        end 
        
        F0_START_XHIGH: fsm0_next = F0_WAIT_XHIGH;
        
        F0_WAIT_XHIGH: begin 
            if (!spi0_RTS) begin // can see that the module accepted the data_in given 
                fsm0_next = F0_DONE_XHIGH;
            end
        end 
        
        F0_DONE_XHIGH: begin 
            if (spi0_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm0_next = F0_START_YLOW;
            end 
        end 
        
        F0_START_YLOW: fsm0_next = F0_WAIT_YLOW;
          
        F0_WAIT_YLOW: begin 
            if (!spi0_RTS) begin // can see that the module accepted the data_in given 
                fsm0_next = F0_DONE_YLOW;
            end
        end 
        
        F0_DONE_YLOW: begin 
            if (spi0_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm0_next = F0_START_YHIGH;
            end 
        end 
        
        F0_START_YHIGH: fsm0_next = F0_WAIT_YHIGH;
        
        F0_WAIT_YHIGH: begin 
            if (!spi0_RTS) begin // can see that the module accepted the data_in given 
                fsm0_next = F0_DONE_YHIGH;
            end
        end 
        
        F0_DONE_YHIGH: begin 
            if (spi0_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm0_next = F0_START_ZLOW;
            end 
        end 
        
        F0_START_ZLOW: fsm0_next = F0_WAIT_ZLOW;
        
        F0_WAIT_ZLOW: begin 
            if (!spi0_RTS) begin // can see that the module accepted the data_in given 
                fsm0_next = F0_DONE_ZLOW;
            end
        end 
        
        F0_DONE_ZLOW: begin 
            if (spi0_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm0_next = F0_START_ZHIGH;
            end 
        end 
        
        F0_START_ZHIGH: fsm0_next = F0_WAIT_ZHIGH;
        
        F0_WAIT_ZHIGH: begin 
            if (!spi0_RTS) begin // can see that the module accepted the data_in given 
                fsm0_next = F0_DONE_ZHIGH;
            end
        end
        
        F0_DONE_ZHIGH: begin 
            if (spi0_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm0_next = F0_DONE;
            end 
        end 
        
        F0_DONE: begin 
            if (BTNC) begin 
                fsm0_next = F0_IDLE; // wait for the next 10hz flag and RTS from the modules 
            end 
        end 
     endcase
         
end 

// Combinational Logic for FSM1 next state logic 

always @(*) begin 
    fsm1_next = fsm1_state; // hold the current state by default 
    
    case (fsm1_state) 
        F1_IDLE: begin 
            if (flag_10hz) begin 
                fsm1_next = F1_START_XLOW; // send the message that re need to 
            end 
        end 
        
        F1_START_XLOW: begin 
            if (spi1_RTS) begin 
                fsm1_next = F1_WAIT_XLOW;
            end
        end 
        
        F1_WAIT_XLOW: begin 
            if (!spi1_RTS) begin // can see that the module accepted the data_in given 
                fsm1_next = F1_DONE_XLOW;
            end
        end 
        
        F1_DONE_XLOW: begin 
            if (spi1_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm1_next = F1_START_XHIGH;
            end 
        end 
        
        F1_START_XHIGH: fsm1_next = F1_WAIT_XHIGH;
        
        F1_WAIT_XHIGH: begin 
            if (!spi1_RTS) begin // can see that the module accepted the data_in given 
                fsm1_next = F1_DONE_XHIGH;
            end
        end 
        
        F1_DONE_XHIGH: begin 
            if (spi1_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm1_next = F1_START_YLOW;
            end 
        end 
        
        F1_START_YLOW: fsm1_next = F1_WAIT_YLOW;
          
        F1_WAIT_YLOW: begin 
            if (!spi1_RTS) begin // can see that the module accepted the data_in given 
                fsm1_next = F1_DONE_YLOW;
            end
        end 
        
        F1_DONE_YLOW: begin 
            if (spi1_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm1_next = F1_START_YHIGH;
            end 
        end 
        
        F1_START_YHIGH: fsm1_next = F1_WAIT_YHIGH;
        
        F1_WAIT_YHIGH: begin 
            if (!spi1_RTS) begin // can see that the module accepted the data_in given 
                fsm1_next = F1_DONE_YHIGH;
            end
        end 
        
        F1_DONE_YHIGH: begin 
            if (spi1_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm1_next = F1_START_ZLOW;
            end 
        end 
        
        F1_START_ZLOW: fsm1_next = F1_WAIT_ZLOW;
        
        F1_WAIT_ZLOW: begin 
            if (!spi1_RTS) begin // can see that the module accepted the data_in given 
                fsm1_next = F1_DONE_ZLOW;
            end
        end 
        
        F1_DONE_ZLOW: begin 
            if (spi1_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm1_next = F1_START_ZHIGH;
            end 
        end 
        
        F1_START_ZHIGH: fsm1_next = F1_WAIT_ZHIGH;
        
        F1_WAIT_ZHIGH: begin 
            if (!spi1_RTS) begin // can see that the module accepted the data_in given 
                fsm1_next = F1_DONE_ZHIGH;
            end
        end
        
        F1_DONE_ZHIGH: begin 
            if (spi1_RTS) begin // can see that the transaction completed and can move to setting up the next transaction. 
                fsm1_next = F1_DONE;
            end 
        end 
        
        F1_DONE: begin 
            if (BTNC) begin 
                fsm1_next = F1_IDLE; // wait for the next 10hz flag and RTS from the modules 
            end 
        end 
     endcase
         
end 

// combinational logic for FSM 2

always @(*) begin 
    fsm2_next = fsm2_state; // hold the current state by default 
    
    case (fsm2_state) 
        F2_IDLE: begin 
            if (flag_10hz) begin 
                fsm2_next = F2_SAMPLE; // send the message that re need to 
            end 
        end 
        
        F2_SAMPLE: begin 
            if (uart_done) begin 
                fsm2_next = F2_DONE; // wait until the data recieved flag is raised 
            end 
        end 
        
        F2_DONE: begin 
            if (BTNC) begin 
                fsm2_next = F2_IDLE; // wait for the next 10hz flag and RTS from the modules 
            end 
        end 
     endcase
         
end 

// combinational logic for the valid output handshake 

assign spi0_output_valid = (fsm0_state == F0_DONE);
assign spi1_output_valid = (fsm1_state == F1_DONE);
assign uart_valid = (fsm2_state == F2_DONE); 
    
// Instance 0 -- onboard accelerometer 
    SPI u_spi0 (
        .clk     (clk),
        .reset   (spi0_reset),
        .in_data (spi0_in_data),
        .out_data(spi0_out_data),
        .CTS     (spi0_CTS),
        .RTS     (spi0_RTS),
        .SCK     (SCK_0),
        .CS_n    (CS_n_0),
        .MOSI    (MOSI_0),
        .MISO    (MISO_0),
        .MODE    (spi0_MODE)
    );
    
// Instance 1 - external gyroscope 
SPI u_spi1 (
        .clk     (clk),
        .reset   (spi1_reset),
        .in_data (spi1_in_data),
        .out_data(spi1_out_data),
        .CTS     (spi1_CTS),
        .RTS     (spi1_RTS),
        .SCK     (SCK_1),
        .CS_n    (CS_n_1),
        .MOSI    (MOSI_1),
        .MISO    (MISO_1),
        .MODE    (spi1_MODE)
    ); 
    
// GPS UART instantiations 


wire [7:0]    rx_byte;
wire          rx_valid;
wire          byte_error;
wire          in_sentence;
wire [1023:0] out_sentence;
wire [7:0]    out_len;

uart_rx #(
        .CLK_SPEED(CLK_SPEED),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk       (clk),
        .rst       (uart_reset),
        .rx        (gps_rx),
        .rx_byte   (rx_byte),
        .rx_valid  (rx_valid),
        .byte_error(byte_error)
    );

    construct_gps_nmea_sentence #(
        .MAX_BYTES(MAX_BYTES)
    ) u_nmea (
        .clk         (clk),
        .rst         (uart_reset),
        .rx_byte     (rx_byte),
        .rx_valid    (rx_valid),
        .out_sentence(out_sentence), // not used yet
        .out_len     (out_len), // not used yet
        .in_sentence (in_sentence)
    );
    
    
//ila_0 u_ila (
//  .clk(clk),

//  // ---- poll / valid flags ----
//  .probe0(out_sentence_captured), 
//  .probe1(flag_10hz)          
  
  
  
               
//);
    
    
   
    
    
endmodule
