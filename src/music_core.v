// The music core: eight keys, each a note. Two voices play the note: a sine, and a square wave
// one octave lower. A mixer adds them and PWM turns the result into sound.
`default_nettype none

module music_core #(
    parameter DB      = 500000,   // debounce time in clocks, 20 ms at 25 MHz
    parameter TICKDIV = 512       // clocks per sample, 48.8 kHz at 25 MHz
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] keys,      // eight raw buttons, key 0 is the lowest note
    output wire       pwm,       // PWM audio output
    output wire [7:0] level      // the sample, for the screen
);
    // 1. clean up all eight keys
    wire [7:0] k;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : keys_db
            ip_debounce #(.N(DB)) db (.clk(clk), .rst_n(rst_n), .noisy(keys[i]), .clean(k[i]));
        end
    endgenerate

    // 2. which note? the highest key held wins
    reg [2:0] note;
    always @(*) begin
        casez (k)
            8'b1???????: note = 3'd7;
            8'b01??????: note = 3'd6;
            8'b001?????: note = 3'd5;
            8'b0001????: note = 3'd4;
            8'b00001???: note = 3'd3;
            8'b000001??: note = 3'd2;
            8'b0000001?: note = 3'd1;
            default:     note = 3'd0;
        endcase
    end
    wire any_key = |k;

    wire [15:0] step;
    ip_note_rom notes (.note(note), .step(step));

    // 3. a sample every TICKDIV clocks, and two phase accumulators: one at the note, one an octave below
    wire tick;
    ip_tick #(.DIV(TICKDIV)) sample_tick (.clk(clk), .rst_n(rst_n), .en(1'b1), .tick(tick));

    wire [15:0] phase_hi, phase_lo;
    ip_phase_acc #(.W(16)) acc_hi (.clk(clk), .rst_n(rst_n), .en(tick), .step(step),              .phase(phase_hi));
    ip_phase_acc #(.W(16)) acc_lo (.clk(clk), .rst_n(rst_n), .en(tick), .step({1'b0, step[15:1]}), .phase(phase_lo));

    // 4. voice 1 is the sine table, voice 2 is a square wave from the top bit
    wire [7:0] voice1;
    ip_rom_sine rom (.addr(phase_hi[15:12]), .data(voice1));
    wire [7:0] voice2 = phase_lo[15] ? 8'd192 : 8'd64;

    // 5. mix, silence if no key, and out through PWM
    wire [7:0] mixed;
    ip_mixer mix (.a(voice1), .b(voice2), .y(mixed));

    assign level = any_key ? mixed : 8'd128;

    ip_pwm audio (.clk(clk), .rst_n(rst_n), .duty(level), .out(pwm));
endmodule
