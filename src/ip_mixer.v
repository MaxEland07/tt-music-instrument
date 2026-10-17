// A mixer: the average of two 8 bit samples. The sum needs 9 bits, so it is made 9 bits wide first.
`default_nettype none

module ip_mixer (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] y
);
    wire [8:0] sum = {1'b0, a} + {1'b0, b};
    assign y = sum[8:1];
endmodule
