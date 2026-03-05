`timescale 1ns / 1ps

module data_packager #(
    parameter GPS_SENTENCE_BITS = 1024    
)(
    input   logic           clk,
    input   logic           arst_n,             // async active low reset
    
    // control from polling module
    input   logic           i_gps_valid,        // uart_valid
    input   logic           i_accel_valid,      // spi0_output_valid
    input   logic           i_gyro_valid,       // spi1_output_valid
        
    // inputs from sensors
    input   logic [GPS_SENTENCE_BITS-1:0]  i_gps_sentence,
    
    // acceleration
    input   logic [15:0]    i_accel_z,          // spi0_out_dataZ
    input   logic [15:0]    i_accel_y,          // spi0_out_dataY
    input   logic [15:0]    i_accel_x,          // spi0_out_dataX
    
    // gyro
    input   logic [15:0]    i_gyro_z,           // spi1_out_dataZ
    input   logic [15:0]    i_gyro_y,           // spi1_out_dataY
    input   logic [15:0]    i_gyro_x,           // spi1_out_dataX
    
    // handshake with sensor polling
    output  logic           o_data_recv,
    
    // output packet
    output  logic [10*32-1:0]       o_packet,
    output  logic                   o_packet_valid,
    
    // interface to BRAM buffer
    output  logic [31:0]    o_data_packet_bram_addr,
    output  logic [31:0]    o_data_packet_bram_din,
    output  logic [3:0]     o_data_packet_bram_we,
    output  logic           o_data_packet_bram_en,

    output  logic [10:0]    o_data_packet_bram_write_ptr,
    output  logic           o_data_packet_bram_status_empty,
    output  logic           o_data_packet_bram_status_full,
    input   logic [10:0]    i_data_packet_bram_read_ptr,
    
    // interface to crash detection
    output  logic [15:0]    o_cd_accel_z,
    output  logic [15:0]    o_cd_accel_y,
    output  logic [15:0]    o_cd_accel_x,
    output  logic [15:0]    o_cd_gyro_z,
    output  logic [15:0]    o_cd_gyro_y,
    output  logic [15:0]    o_cd_gyro_x,
    output  logic [31:0]    o_cd_gps_ground_speed
    );
    
    logic all_sensors_valid = i_accel_valid & i_gyro_valid & i_gps_valid;

    logic accel_done_sampling, gyro_done_sampling, gps_done_sampling;
    logic all_sensors_done_sampling = accel_done_sampling & gyro_done_sampling & gps_done_sampling;

    logic buffer_write_done;

    // --- FSM ---
    typedef enum logic [2:0] {
        IDLE                = 3'b000,
        START_SAMPLING      = 3'b001,
        SAMPLING            = 3'b010,
        DONE                = 3'b011,
        WRITING_TO_BUFFER   = 3'b100,
        COMPLETE            = 3'b101
    } data_packager_state_t;
    
    data_packager_state_t state, state_next;

    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            state       <= IDLE;
        end else begin
            state       <= state_next;
        end
    end

    always_comb begin
        state_next = state;
        case(state)
            IDLE: begin
                state_next = IDLE;
                if (all_sensors_valid) begin
                    state_next = START_SAMPLING;
                end
            end
            START_SAMPLING: begin
                state_next = SAMPLING;
            end
            SAMPLING: begin
                state_next = SAMPLING;
                if (all_sensors_done_sampling) begin
                    state_next = DONE;
                end
            end
            DONE: begin
                state_next = WRITING_TO_BUFFER;
            end
            WRITING_TO_BUFFER: begin
                state_next = WRITING_TO_BUFFER;
                if (buffer_write_done) begin
                    state_next = COMPLETE;
                end
            end
            COMPLETE: begin
                state_next = IDLE;
            end
            default: state_next = IDLE;
        endcase
    end
    
    // --- handshake ---
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            o_data_recv     <= 1'b0;
        end else if (state == COMPLETE) begin
            o_data_recv     <= 1'b1;
        end else begin
            o_data_recv     <= 1'b0;
        end
    end
    
    // --- gps sampling ---
    logic start_nmea_extract;
    logic done_nmea_extract;
    logic busy;
    
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            start_nmea_extract <= 1'b0;
        end else if (state == START_SAMPLING) begin
            start_nmea_extract <= 1'b1;
        end else begin
            start_nmea_extract <= 1'b0;
        end
    end

    logic   [31:0]          w_gps_utc_time;
    logic   [31:0]          w_gps_latitude, w_gps_longitude;
    logic                   w_gps_north, w_gps_east;
    logic   [31:0]          w_gps_ground_speed;
    
    nmea_field_extract #(
        .SENTENCE_BITS(GPS_SENTENCE_BITS)
    ) u_gps_field_extract(
        .clk(clk),
        .rst_n(arst_n),
        .start(start_nmea_extract),
        .done(done_nmea_extract),
        .busy(busy),
        .sentence(i_gps_sentence),
        .utc_time(w_gps_utc_time),
        .latitude(w_gps_latitude),
        .north(w_gps_north),
        .longitude(w_gps_longitude),
        .east(w_gps_east),
        .ground_speed(w_gps_ground_speed)
    );

    logic   [31:0]          w_gps_utc_time_d;
    logic   [31:0]          w_gps_latitude_d, w_gps_longitude_d;
    logic                   w_gps_north_d, w_gps_east_d;
    logic   [31:0]          w_gps_ground_speed_d;
    
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            w_gps_utc_time_d        <= '0;
            w_gps_latitude_d        <= '0;
            w_gps_longitude_d       <= '0;
            w_gps_north_d           <= 1'b0;
            w_gps_east_d            <= 1'b0;
            w_gps_ground_speed_d    <= '0;
        end else if (done_nmea_extract) begin
            w_gps_utc_time_d        <= w_gps_utc_time;
            w_gps_latitude_d        <= w_gps_latitude;
            w_gps_longitude_d       <= w_gps_longitude;
            w_gps_north_d           <= w_gps_north;
            w_gps_east_d            <= w_gps_east;
            w_gps_ground_speed_d    <= w_gps_ground_speed;
        end
    end

    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            gps_done_sampling       <= 1'b0;
        end else if ((state == SAMPLING) & (done_nmea_extract)) begin
            gps_done_sampling       <= 1'b1;
        end else if ((state == DONE) || (state == IDLE)) begin
            gps_done_sampling       <= 1'b0;
        end
    end

    // --- acceleration sampling ---
    logic   [15:0]          w_accel_z_d, w_accel_y_d, w_accel_x_d;

    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            w_accel_z_d             <= '0;
            w_accel_y_d             <= '0;
            w_accel_x_d             <= '0;
            accel_done_sampling     <= 1'b0;
        end else if (state == START_SAMPLING) begin
            w_accel_z_d             <= i_accel_z;
            w_accel_y_d             <= i_accel_y;
            w_accel_x_d             <= i_accel_x;
            accel_done_sampling     <= 1'b0;
        end else if (state == SAMPLING) begin
            accel_done_sampling     <= 1'b1;
        end else if ((state == DONE) || (state == IDLE)) begin
            accel_done_sampling     <= 1'b0;
        end
    end

    // --- gyro sampling ---
    logic   [15:0]          w_gyro_z_d, w_gyro_y_d, w_gyro_x_d;

    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            w_gyro_z_d             <= '0;
            w_gyro_y_d             <= '0;
            w_gyro_x_d             <= '0;
            gyro_done_sampling     <= 1'b0;
        end else if (state == START_SAMPLING) begin
            w_gyro_z_d             <= i_gyro_z;
            w_gyro_y_d             <= i_gyro_y;
            w_gyro_x_d             <= i_gyro_x;
            gyro_done_sampling     <= 1'b0;
        end else if (state == SAMPLING) begin
            gyro_done_sampling     <= 1'b1;
        end else if ((state == DONE) || (state == IDLE)) begin
            gyro_done_sampling     <= 1'b0;
        end
    end

    // --- packet ---
    logic [10*32-1:0]            packet;
    assign o_packet         = packet;
    assign o_packet_valid   = all_sensors_done_sampling;
    
    always_comb begin
        packet = {
            w_gps_utc_time_d,
            w_gps_latitude_d,
            w_gps_longitude_d,
            {30'b0,w_gps_north_d,w_gps_east_d},
            w_gps_ground_speed_d,
            {16'b0,w_accel_z_d},
            {w_accel_y_d,w_accel_x_d},
            {16'b0,w_gyro_z_d},
            {w_gyro_y_d,w_gyro_x_d},
            {32'b0} // placeholder for temperature data
        };
    end
    
    // --- sensor data to crash detection (passthrough for now) ---
    assign o_cd_accel_z = w_accel_z_d;
    assign o_cd_accel_y = w_accel_y_d;
    assign o_cd_accel_x = w_accel_x_d;
    assign o_cd_gyro_z = w_gyro_z_d;
    assign o_cd_gyro_y = w_gyro_y_d;
    assign o_cd_gyro_x = w_gyro_x_d;
    assign o_cd_gps_ground_speed = w_gps_ground_speed_d;
    
    // --- BRAM write ---
    // data_packet_mem is 8K, can store 2048 32-bit words
    // need 11 bits to count all the words
    
    logic buffer_full, buffer_empty, buffer_ready;
    logic [10:0] buffer_write_ptr, buffer_next_write_ptr;

    assign buffer_next_write_ptr = buffer_write_ptr + 11'd4; // bram is byte-addressed
    // will wrap around automatically
    
    assign buffer_full = (buffer_next_write_ptr == i_data_packet_bram_read_ptr);
    assign buffer_empty = (buffer_write_ptr == i_data_packet_bram_read_ptr);
    assign buffer_ready = !buffer_full;

    assign o_data_packet_bram_write_ptr = buffer_write_ptr;
    assign o_data_packet_bram_status_empty = buffer_empty;
    assign o_data_packet_bram_status_full = buffer_full;

    logic buffer_write_started;
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            buffer_write_started            <= 1'b0;
            buffer_write_done               <= 1'b0;
        end else if (state_next == WRITING_TO_BUFFER) begin
            buffer_write_started            <= 1'b1;
            buffer_write_done               <= 1'b0;
        end else if (packet_idx == 4'd9) begin
            buffer_write_started            <= 1'b0;
            buffer_write_done               <= 1'b1;
        end else if (state == IDLE) begin
            buffer_write_started            <= 1'b0;
            buffer_write_done               <= 1'b0;
        end
    end

    logic buffer_write_en;
    logic [31:0] bram_write_data;
    logic [3:0] packet_idx;
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            buffer_write_en         <= 1'b0;
            buffer_write_ptr        <= '0;
            bram_write_data         <= '0;
            packet_idx              <= '0;
        end else if (buffer_write_started & buffer_ready) begin
            buffer_write_en         <= 1'b1;
            buffer_write_ptr        <= buffer_next_write_ptr;
            bram_write_data         <= packet[(packet_idx*32) +: 32];
            packet_idx              <= packet_idx + 4'd1;
        end else begin
            buffer_write_en         <= 1'b0;
            bram_write_data         <= '0;
            packet_idx              <= '0;
        end
    end
    
    bram_writer u_data_packet_mem_writer(
        .clk(clk),
        .arst_n(arst_n),
        .i_valid(buffer_write_en),
        .i_data(bram_write_data),
        .i_bram_addr({21'd0, buffer_write_ptr}),
        .o_bram_addr(o_data_packet_bram_addr),
        .o_bram_din(o_data_packet_bram_din),
        .o_bram_we(o_data_packet_bram_we),
        .o_bram_en(o_data_packet_bram_en)
    );
endmodule
