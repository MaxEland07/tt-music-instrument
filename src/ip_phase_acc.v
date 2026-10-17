// A phase accumulator: adds step to phase on every enabled clock. The top bits of phase
// say where you are in one cycle of a wave, and step sets how fast you go round.
`default_nettype none

module ip_phase_acc #(
    parameter W = 16
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         en,
    input  wire [W-1:0] step,
    output reg  [W-1:0] phase
);
    always @(posedge clk) begin
        if (!rst_n)  phase <= {W{1'b0}};
        else if (en) phase <= phase + step;
    end
endmodule
