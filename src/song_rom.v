// The song: the Mario theme, one entry per eighth note. Slot 0 is the first slot of the loop.
// Each entry is 5 bits: bit 4 says the note is still being held from the slot before, and
// bits 3:0 are the key (0 = C4 up to 7 = C5). Key 15 means no note, so the slot is a rest.
//
// The tune is moved onto the eight white keys C4 to C5: down an octave, and the notes that then
// fall below C4 are moved up an octave. The black note (Bb) is played as A.
// The first note comes 14 slots in, so that its tile has time to fall in from the top of the screen.
// 26 slots have a note, so a perfect run scores 26 x 16 = 416 frames. Change MAX_HITS
// in piano_hero.v if you change the song.
`default_nettype none
module song_rom (
    input  wire [5:0] slot,
    output reg  [4:0] note
);
    always @(*) begin
        case (slot)
            6'd14: note = 5'b0_0010;   // E4
            6'd15: note = 5'b0_0010;   // E4
            6'd17: note = 5'b0_0010;   // E4
            6'd19: note = 5'b0_0000;   // C4
            6'd20: note = 5'b0_0010;   // E4
            6'd22: note = 5'b0_0100;   // G4
            6'd23: note = 5'b1_0100;   // G4 (held)
            6'd26: note = 5'b0_0100;   // G4
            6'd27: note = 5'b1_0100;   // G4 (held)
            6'd30: note = 5'b0_0000;   // C4
            6'd33: note = 5'b0_0100;   // G4
            6'd36: note = 5'b0_0010;   // E4
            6'd39: note = 5'b0_0101;   // A4
            6'd41: note = 5'b0_0110;   // B4
            6'd43: note = 5'b0_0101;   // A4
            6'd44: note = 5'b0_0101;   // A4
            6'd46: note = 5'b0_0100;   // G4
            6'd47: note = 5'b0_0010;   // E4
            6'd48: note = 5'b0_0100;   // G4
            6'd49: note = 5'b0_0101;   // A4
            6'd51: note = 5'b0_0011;   // F4
            6'd52: note = 5'b0_0100;   // G4
            6'd54: note = 5'b0_0010;   // E4
            6'd56: note = 5'b0_0000;   // C4
            6'd57: note = 5'b0_0001;   // D4
            6'd58: note = 5'b0_0110;   // B4
            default: note = 5'b0_1111;   // rest
        endcase
    end
endmodule
