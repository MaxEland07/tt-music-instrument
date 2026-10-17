// The music core: eight keys, each a note. Every key held plays its own sine wave, so you can
// play chords. A mixer adds the sines together and PWM turns the result into sound.
`default_nettype none
module music_core #(
    parameter DB        = 500000,   // debounce time in clocks, 20 ms at 25 MHz
    parameter TICKDIV   = 512,      // clocks per sample, 48.8 kHz at 25 MHz
    parameter MIX_SHIFT = 2         // the sum of the notes is divided by 2^MIX_SHIFT. 2 means four notes
                                    // at once use the full range, more than four notes clip.
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] keys,      // eight raw buttons, key 0 is the lowest note
    output wire       pwm,       // PWM audio output
    output wire [7:0] level,     // the sample
    output wire [7:0] keys_down  // the eight cleaned-up keys, for the screen
);
    // 1. clean up all eight keys
    wire [7:0] k;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : keys_db
            ip_debounce #(.N(DB)) db (.clk(clk), .rst_n(rst_n), .noisy(keys[i]), .clean(k[i]));
        end
    endgenerate

    assign keys_down = k;

    // 2. a sample every TICKDIV clocks
    wire tick;
    ip_tick #(.DIV(TICKDIV)) sample_tick (.clk(clk), .rst_n(rst_n), .en(1'b1), .tick(tick));

    // 3. one phase accumulator per key. A key that is not held sits at phase 0, so every note
    //    starts from the same point in the wave.
    reg  [127:0] phases;           // eight 16 bit phases, key 0 in the lowest bits
    generate
        for (i = 0; i < 8; i = i + 1) begin : voices
            wire [15:0] step;
            ip_note_rom notes (.note(i[2:0]), .step(step));
            always @(posedge clk) begin
                if (!rst_n || !k[i]) phases[i*16 +: 16] <= 16'd0;
                else if (tick)       phases[i*16 +: 16] <= phases[i*16 +: 16] + step;
            end
        end
    endgenerate

    // 4. after each tick, visit the eight voices one per clock. One sine table and one adder
    //    are shared by all of them. A held key adds (sine - 128), so silence adds nothing.
    reg  [2:0]        voice;       // which voice is being added
    reg               busy;        // adding up is in progress
    reg signed [10:0] sum;         // running total of the sines, -1016 to 1016 for eight notes
    reg  [7:0]        mixed;       // the finished sample

    wire [15:0] phase_now = phases[voice*16 +: 16];
    wire [7:0]  sine;
    ip_rom_sine rom (.addr(phase_now[15:12]), .data(sine));

    wire signed [10:0] swing     = $signed({3'b000, sine}) - 11'sd128;           // -127 to 127
    wire signed [10:0] sum_next  = sum + (k[voice] ? swing : 11'sd0);
    wire signed [10:0] scaled    = sum_next >>> MIX_SHIFT;
    wire signed [10:0] clipped   = (scaled >  11'sd127) ? 11'sd127 :
                                   (scaled < -11'sd128) ? -11'sd128 : scaled;   // keep it in 8 bits

    always @(posedge clk) begin
        if (!rst_n) begin
            voice <= 3'd0;
            busy  <= 1'b0;
            sum   <= 11'sd0;
            mixed <= 8'd128;
        end else if (tick) begin
            voice <= 3'd0;
            busy  <= 1'b1;
            sum   <= 11'sd0;
        end else if (busy) begin
            sum   <= sum_next;
            voice <= voice + 3'd1;
            if (voice == 3'd7) begin
                busy  <= 1'b0;
                mixed <= clipped[7:0] + 8'd128;   // back to 0 to 255, silence is 128
            end
        end
    end

    // 5. out through PWM
    assign level = mixed;
    ip_pwm audio (.clk(clk), .rst_n(rst_n), .duty(level), .out(pwm));
endmodule
