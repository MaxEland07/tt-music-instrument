// A note table: the phase accumulator step for eight notes, C4 up to C5.
// Phase updates once every 512 clocks of a 25 MHz clock, so the note is step * 25e6 / 512 / 65536 Hz.
`default_nettype none

module ip_note_rom (
    input  wire [2:0]  note,
    output reg  [15:0] step
);
    always @(*) begin
        case (note)
            3'd0: step = 16'd351;   // C4
            3'd1: step = 16'd394;   // D4
            3'd2: step = 16'd442;   // E4
            3'd3: step = 16'd469;   // F4
            3'd4: step = 16'd526;   // G4
            3'd5: step = 16'd591;   // A4
            3'd6: step = 16'd663;   // B4
            3'd7: step = 16'd702;   // C5
            default: step = 16'd0;
        endcase
    end
endmodule
