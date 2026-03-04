`timescale 1ns / 1ps
module nmea_field_extract #(
    parameter SENTENCE_BITS = 1024
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     start,
    input  logic [SENTENCE_BITS-1:0] sentence,
    output logic                     done,
    output logic                     busy,
    output logic [31:0]              utc_time,
    output logic [31:0]              latitude,
    output logic                     north,
    output logic [31:0]              longitude,
    output logic                     east,
    output logic [31:0]              ground_speed
);

    localparam NUM_BYTES = SENTENCE_BITS / 8; // 128 for 1024-bit sentence
    localparam BYTE_IDX_W = $clog2(NUM_BYTES); // 7 bits

    // FSM state
    typedef enum logic [1:0] {
        S_IDLE,
        S_PARSE,
        S_DONE
    } state_t;

    state_t state, state_next;

    // initialize parsing states
    logic [BYTE_IDX_W-1:0] byte_idx,   byte_idx_next;
    logic [3:0]            field_idx,   field_idx_next;
    logic [31:0]           acc,         acc_next;
    logic [31:0]           frac_acc,    frac_acc_next;
    logic [31:0]           scale,       scale_next;
    logic [31:0]           frac_scale,  frac_scale_next;
    logic                  dot_seen,    dot_seen_next;

    // initialize output registers
    logic [31:0] utc_time_next;
    logic [31:0] latitude_next;
    logic        north_next;
    logic [31:0] longitude_next;
    logic        east_next;
    logic [31:0] ground_speed_next;

    // assign current byte value
    logic [7:0] cur_byte;
    assign cur_byte = sentence[8*byte_idx +: 8];

    // compute digit value
    logic [3:0] digit_val;
    assign digit_val = cur_byte[3:0]; // ASCII 0x30-0x39 ? 0-9

    logic is_comma, is_dot, is_digit, is_N, is_E;
    assign is_comma = (cur_byte == 8'h2C);
    assign is_dot   = (cur_byte == 8'h2E);
    assign is_digit = (cur_byte >= 8'h30) && (cur_byte <= 8'h39);
    assign is_N     = (cur_byte == 8'h4E);
    assign is_E     = (cur_byte == 8'h45);

    // ?compute value to be commiitted
    logic [31:0] committed_value;
    assign committed_value = acc * scale + frac_acc * frac_scale;

    // combinational logic for FSM
    always_comb begin
        // by default, hold every value to previous
        state_next      = state;
        byte_idx_next   = byte_idx;
        field_idx_next  = field_idx;
        acc_next        = acc;
        frac_acc_next   = frac_acc;
        scale_next      = scale;
        frac_scale_next = frac_scale;
        dot_seen_next   = dot_seen;

        utc_time_next     = utc_time;
        latitude_next     = latitude;
        north_next        = north;
        longitude_next    = longitude;
        east_next         = east;
        ground_speed_next = ground_speed;

        case (state)
            // idle FSM state
            S_IDLE: begin
                if (start) begin
                    state_next      = S_PARSE;
                    byte_idx_next   = '0;
                    field_idx_next  = 4'd0;
                    acc_next        = 32'd0;
                    frac_acc_next   = 32'd0;
                    scale_next      = 32'd10000;
                    frac_scale_next = 32'd10000;
                    dot_seen_next   = 1'b0;

                    utc_time_next     = 32'd0;
                    latitude_next     = 32'd0;
                    north_next        = 1'b0;
                    longitude_next    = 32'd0;
                    east_next         = 1'b0;
                    ground_speed_next = 32'd0;
                end
            end

            // parsing FSM state
            S_PARSE: begin
                // check current value
                if (is_comma) begin
                    // commit value to appropriate signal
                    case (field_idx)
                        4'd1: utc_time_next     = committed_value;
                        4'd3: latitude_next     = committed_value;
                        4'd5: longitude_next    = committed_value;
                        4'd7: ground_speed_next = committed_value;
                        default: ;
                    endcase

                    // advance field and reset accumulators
                    field_idx_next  = field_idx + 4'd1;
                    acc_next        = 32'd0;
                    frac_acc_next   = 32'd0;
                    dot_seen_next   = 1'b0;

                    // set scales for the NEXT field (field_idx + 1)
                    case (field_idx + 4'd1)
                        4'd1:       begin scale_next = 32'd1000;  frac_scale_next = 32'd1000;  end
                        4'd3, 4'd5: begin scale_next = 32'd10000; frac_scale_next = 32'd10000; end
                        4'd7:       begin scale_next = 32'd100;   frac_scale_next = 32'd100;   end
                        default:    begin scale_next = 32'd1;     frac_scale_next = 32'd1;     end
                    endcase
                end else begin
                    case (field_idx)
                        4'd1, 4'd3, 4'd5, 4'd7: begin
                            if (is_dot)
                                dot_seen_next = 1'b1;
                            else if (is_digit) begin
                                if (!dot_seen) begin
                                    acc_next = acc * 10 + {28'd0, digit_val};
                                end else begin
                                    frac_acc_next   = frac_acc * 10 + {28'd0, digit_val};
                                    frac_scale_next = frac_scale / 10;
                                end
                            end
                        end
                        4'd4: if (is_N) north_next = 1'b1;
                        4'd6: if (is_E) east_next  = 1'b1;
                        default: ;
                    endcase
                end

                // once past ground speed (field 8+), all needed data is captured
                if (field_idx_next > 4'd7) begin
                    state_next = S_DONE;
                end else if (byte_idx == NUM_BYTES[BYTE_IDX_W-1:0] - 1) begin
                    state_next = S_DONE;
                end else begin
                    byte_idx_next = byte_idx + 1;
                end
            end

            // done FSM state
            S_DONE: begin
                state_next = S_IDLE;
            end

            default: state_next = S_IDLE;
        endcase
    end

    // update values sequentially
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            byte_idx   <= '0;
            field_idx  <= 4'd0;
            acc        <= 32'd0;
            frac_acc   <= 32'd0;
            scale      <= 32'd10000;
            frac_scale <= 32'd10000;
            dot_seen   <= 1'b0;

            utc_time     <= 32'd0;
            latitude     <= 32'd0;
            north        <= 1'b0;
            longitude    <= 32'd0;
            east         <= 1'b0;
            ground_speed <= 32'd0;
            done         <= 1'b0;
            busy         <= 1'b0;
        end else begin
            state      <= state_next;
            byte_idx   <= byte_idx_next;
            field_idx  <= field_idx_next;
            acc        <= acc_next;
            frac_acc   <= frac_acc_next;
            scale      <= scale_next;
            frac_scale <= frac_scale_next;
            dot_seen   <= dot_seen_next;

            utc_time     <= utc_time_next;
            latitude     <= latitude_next;
            north        <= north_next;
            longitude    <= longitude_next;
            east         <= east_next;
            ground_speed <= ground_speed_next;

            done <= (state_next == S_DONE);
            busy <= (state_next == S_PARSE);
        end
    end

endmodule