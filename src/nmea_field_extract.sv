`timescale 1ns / 1ps
module nmea_field_extract #(
    parameter SENTENCE_BITS = 1024
)(
    input  logic                     clk,
    input  logic [SENTENCE_BITS-1:0] sentence,
    output logic [31:0]              utc_time,
    output logic [31:0]              latitude,
    output logic                     north,
    output logic [31:0]              longitude,
    output logic                     east,
    output logic [31:0]              ground_speed
);
    
    // turn sentence [1023:0] into bytes (ASCII interpretable)
    logic [7:0] bytes [0:127];
    genvar i;
    generate
        for (i = 0; i < 128; i = i+1)
            assign bytes[i] = sentence[8*i +: 8];
    endgenerate

    // initialize output fields
    logic [31:0] c_utc_time;
    logic [31:0] c_latitude;
    logic        c_north;
    logic [31:0] c_longitude;
    logic        c_east;
    logic [31:0] c_ground_speed;

    always_comb begin
        // initialize ASCII -> integer conversion parameters
        logic [3:0]  field_idx; // tracks nth comma
        logic [31:0] acc; // acccumlator for values before decimal point
        logic [31:0] frac_acc; // accumulator for values after decimal point
        logic [31:0] scale; // remember the scale for each field
        logic [31:0] frac_scale; // remaining scale after consuming fractional digits
        logic        dot_seen; // if an ASCII dot has been passed

        c_utc_time     = 32'd0;
        c_latitude     = 32'd0;
        c_north        = 1'b0;
        c_longitude    = 32'd0;
        c_east         = 1'b0;
        c_ground_speed = 32'd0;

        field_idx  = 4'd0;
        acc        = 32'd0;
        frac_acc   = 32'd0;
        scale      = 32'd10000;
        frac_scale = 32'd10000;
        dot_seen   = 1'b0;

        for (int j = 0; j < 128; j++) begin
            if (bytes[j] == 8'h2C) begin // checking if the byet is an ASCII comma
                case (field_idx)
                    4'd1: c_utc_time     = acc * scale + frac_acc * frac_scale; // after first comma -> UTC time (hhmmss.sss)
                    4'd3: c_latitude     = acc * scale + frac_acc * frac_scale; // third comma -> latitude (ddmm.mmmm)
                    4'd5: c_longitude    = acc * scale + frac_acc * frac_scale; // fifth comma -> longitude (dddmm.mmmm)
                    4'd7: c_ground_speed = acc * scale + frac_acc * frac_scale; // seventh comma -> ground speed (knots)
                    default: ;
                endcase
                field_idx  = field_idx + 4'd1;
                acc        = 32'd0;
                frac_acc   = 32'd0;
                dot_seen   = 1'b0;
                
                // set scales depending on field type
                case (field_idx)
                    4'd1:       begin scale = 32'd1000;  frac_scale = 32'd1000;  end
                    4'd3, 4'd5: begin scale = 32'd10000; frac_scale = 32'd10000; end
                    4'd7:       begin scale = 32'd100;   frac_scale = 32'd100;   end
                    default:    begin scale = 32'd1;     frac_scale = 32'd1;     end
                endcase
            end else begin
                case (field_idx)
                    4'd1, 4'd3, 4'd5, 4'd7: begin
                        if (bytes[j] == 8'h2E) // period/dot ASCII symbol
                            dot_seen = 1'b1;
                        else if (bytes[j] >= 8'h30 && bytes[j] <= 8'h39) begin // sum before and after dot symbol
                            if (!dot_seen)
                                acc = acc * 10 + {24'd0, bytes[j] - 8'h30};
                            else begin
                                frac_acc   = frac_acc * 10 + {24'd0, bytes[j] - 8'h30};
                                frac_scale = frac_scale / 10;
                            end
                        end
                    end
                    4'd4: c_north = (bytes[j] == 8'h4E);
                    4'd6: c_east  = (bytes[j] == 8'h45);
                    default: ;
                endcase
            end
        end

        case (field_idx)
            4'd1: c_utc_time     = acc * scale + frac_acc * frac_scale;
            4'd3: c_latitude     = acc * scale + frac_acc * frac_scale;
            4'd5: c_longitude    = acc * scale + frac_acc * frac_scale;
            4'd7: c_ground_speed = acc * scale + frac_acc * frac_scale;
            default: ;
        endcase
    end
    
    // on next clock populate field values
//    always_ff @(posedge clk) begin
//        utc_time     <= c_utc_time;
//        latitude     <= c_latitude;
//        north        <= c_north;
//        longitude    <= c_longitude;
//        east         <= c_east;
//        ground_speed <= c_ground_speed;
//    end

    // simply passthrough?
    assign utc_time = c_utc_time;
    assign latitude = c_latitude;
    assign north = c_north;
    assign longitude = c_longitude;
    assign east = c_east;
    assign ground_speed = c_ground_speed;

endmodule
