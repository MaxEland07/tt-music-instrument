// A lookup table (ROM): 16 samples of one cycle of a sine wave, centred on 128 and swinging 1 to 255.
`default_nettype none

module ip_rom_sine (
    input  wire [3:0] addr,
    output reg  [7:0] data
);
    always @(*) begin
        case (addr)
            4'd0: data = 8'd128;
            4'd1: data = 8'd177;
            4'd2: data = 8'd218;
            4'd3: data = 8'd245;
            4'd4: data = 8'd255;
            4'd5: data = 8'd245;
            4'd6: data = 8'd218;
            4'd7: data = 8'd177;
            4'd8: data = 8'd128;
            4'd9: data = 8'd79;
            4'd10: data = 8'd38;
            4'd11: data = 8'd11;
            4'd12: data = 8'd1;
            4'd13: data = 8'd11;
            4'd14: data = 8'd38;
            4'd15: data = 8'd79;
            default: data = 8'd128;
        endcase
    end
endmodule
