// The Tiny Tapeout top module for the music track (the shell). It is given and you do not edit it.
// ui_in[7:0] are the eight keys, uio[0] is the PWM audio output. The screen is piano hero: Mario theme tiles fall onto the piano.
`default_nettype none

module tt_um_maxeland07_music_instrument (
    input  wire [7:0] ui_in,    // dedicated inputs
    output wire [7:0] uo_out,   // dedicated outputs
    input  wire [7:0] uio_in,   // bidirectional pins, input path
    output wire [7:0] uio_out,  // bidirectional pins, output path
    output wire [7:0] uio_oe,   // bidirectional pins, 1 = drive
    input  wire       ena,      // high when the design is powered, ignore
    input  wire       clk,      // clock
    input  wire       rst_n     // reset, active low
);
    wire        hsync, vsync, active, frame;
    wire [9:0]  x, y;
    wire [5:0]  rgb;
    wire [7:0]  level;
    wire [7:0]  keys_down;
    wire        pwm;

    vga_sync vga (.clk(clk), .rst_n(rst_n), .hsync(hsync), .vsync(vsync), .active(active), .x(x), .y(y), .frame(frame));

    music_core core (
        .clk(clk), .rst_n(rst_n),
        .keys(ui_in),
        .pwm(pwm), .level(level), .keys_down(keys_down)
    );

    piano_hero hero (.clk(clk), .rst_n(rst_n), .frame(frame), .x(x), .y(y), .active(active), .down(keys_down), .rgb(rgb));

    // TinyVGA PMOD pin order: {hsync, B0, G0, R0, vsync, B1, G1, R1}
    assign uo_out = {hsync, rgb[0], rgb[2], rgb[4], vsync, rgb[1], rgb[3], rgb[5]};
    // PWM audio on uio[0] (as documented) and also on uio[7], where the Tiny Tapeout audio PMOD listens
    assign uio_out = {pwm, 6'd0, pwm};
    assign uio_oe  = 8'b1000_0001;

    wire _unused = &{ena, uio_in, level, 1'b0};
endmodule
