// Piano hero. The Mario theme falls down the screen as coloured tiles, one lane for each of the
// eight keys. When a tile reaches the piano, flip that key's switch and hold it until the tile has
// gone past. A key that is held goes down: it turns green if it is the right key, red if not.
// The bar along the top fills up with every frame you play the right note.
//
// The screen is 640 x 480. The lanes are 64 pixels wide, x from 64 to 575.
// The piano keys start at y = 392. A tile reaches the piano when its lower edge touches y = 392.
//
// How the scrolling works: pos is how far through the song we are, in pixels, and it goes up by
// SPEED every picture. Every slot of the song is 32 pixels tall. For a pixel at height y, the
// place in the song is  sc = pos + 392 - y,  so pixels higher up the screen are further ahead
// in the song. The song table says which key, if any, plays in that slot.
`default_nettype none
module piano_hero #(
    parameter SPEED    = 2,     // pixels the song scrolls per picture. 2 is 16 pictures (0.27 s) per slot
    parameter MAX_HITS = 416    // frames of right notes in a perfect run, see song_rom.v
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame,     // one clock pulse per picture
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active,
    input  wire [7:0] down,      // 1 = that key is held, key 0 is the leftmost
    output reg  [5:0] rgb        // {R[1:0], G[1:0], B[1:0]}, one clock after x and y
);
    localparam [5:0] FELT  = 6'b010000;   // dark red background
    localparam [5:0] WHITE = 6'b111111;
    localparam [5:0] LIP   = 6'b101010;   // grey strip along the front of a key
    localparam [5:0] BLACK = 6'b000000;
    localparam [5:0] GREEN = 6'b001100;   // right key held
    localparam [5:0] RED   = 6'b110000;   // wrong key held
    localparam [5:0] LINE  = 6'b101010;   // the line where tiles meet the piano
    localparam [5:0] GOLD  = 6'b111100;   // the score
    localparam [5:0] TRACK = 6'b010101;   // where the score can reach

    // ---- where are we in the song, and are you playing the right key? ----------------------
    reg  [10:0] pos;                       // 64 slots of 32 pixels, wraps back to the start
    reg  [8:0]  hits;                      // frames of right notes so far this time round

    wire [4:0]  now_note;
    song_rom now_rom (.slot(pos[10:5]), .note(now_note));
    wire [3:0]  now_key = now_note[3:0];
    // right means: there is a note now, and that key is the only key held
    wire        right   = (now_key != 4'd15) && (down == (8'd1 << now_key[2:0]));

    wire        song_ends = ({1'b0, pos} + SPEED) >= 12'd2048;   // this picture is the last of the loop

    always @(posedge clk) begin
        if (!rst_n) begin
            pos  <= 11'd0;
            hits <= 9'd0;
        end else if (frame) begin
            pos <= pos + SPEED;
            if (song_ends)                    hits <= 9'd0;           // the song starts again
            else if (right && hits != 9'd511) hits <= hits + 9'd1;
        end
    end

    // ---- the picture ------------------------------------------------------------------------
    wire        in_lanes = (x >= 10'd64) && (x < 10'd576);
    wire [2:0]  idx      = x[8:6] - 3'd1;       // which key's lane: 64 to 127 is key 0, ...
    wire [5:0]  col      = x[5:0];              // 0 to 63 across the lane

    // the tile at this pixel: which slot of the song is it, and is there a note in that slot?
    wire [10:0] sc       = pos + 11'd392 - {1'b0, y};
    wire [4:0]  draw_note;
    song_rom draw_rom (.slot(sc[10:5]), .note(draw_note));
    wire        held_on  = draw_note[4];        // a held note carries on from the slot before
    wire        tile_gap = !held_on && (sc[4:0] < 5'd3);        // small gap between two tiles
    wire        in_tile  = in_lanes && (y < 10'd392) && (draw_note[3:0] == {1'b0, idx}) &&
                           !tile_gap && (col >= 6'd3) && (col < 6'd61);

    reg  [5:0]  tile_color;                     // each lane has its own colour
    always @(*) begin
        case (idx)
            3'd0:    tile_color = 6'b110000;    // red
            3'd1:    tile_color = 6'b110100;    // orange
            3'd2:    tile_color = 6'b111100;    // yellow
            3'd3:    tile_color = 6'b001100;    // green
            3'd4:    tile_color = 6'b001111;    // cyan
            3'd5:    tile_color = 6'b000011;    // blue
            3'd6:    tile_color = 6'b100011;    // purple
            default: tile_color = 6'b110010;    // pink
        endcase
    end

    // the piano: a held key sits 8 pixels lower
    wire        held     = down[idx];
    wire        is_right = held && (idx == now_key[2:0]) && (now_key != 4'd15);
    wire [9:0]  top      = held ? 10'd400 : 10'd392;
    wire [9:0]  bottom   = held ? 10'd470 : 10'd462;
    wire        in_key   = in_lanes && (y >= top) && (y < bottom);
    wire        edge_px  = (col == 6'd0) || (col == 6'd63);       // thin black line between keys
    wire        lip_px   = (y >= bottom - 10'd8);

    // black keys sit across the joins between keys 0|1, 1|2, 3|4, 4|5 and 5|6. They are for looks only.
    wire        black_y  = (y >= 10'd392) && (y < 10'd440);
    wire        black_x  = (x >= 10'd110 && x < 10'd146) ||
                           (x >= 10'd174 && x < 10'd210) ||
                           (x >= 10'd302 && x < 10'd338) ||
                           (x >= 10'd366 && x < 10'd402) ||
                           (x >= 10'd430 && x < 10'd466);

    // the score bar along the top
    wire        in_bar   = (y >= 10'd6) && (y < 10'd18);

    reg  [5:0]  rgb_next;
    always @(*) begin
        if (!active)                        rgb_next = 6'b000000;
        else if (in_bar && x < {1'b0, hits}) rgb_next = GOLD;
        else if (in_bar && x < MAX_HITS)    rgb_next = TRACK;
        else if (black_y && black_x)        rgb_next = BLACK;
        else if (in_tile)                   rgb_next = tile_color;
        else if (in_lanes && y >= 10'd388 && y < 10'd392) rgb_next = LINE;
        else if (!in_key)                   rgb_next = FELT;
        else if (edge_px)                   rgb_next = BLACK;
        else if (held)                      rgb_next = is_right ? (lip_px ? 6'b000100 : GREEN)
                                                                : (lip_px ? 6'b010000 : RED);
        else                                rgb_next = lip_px ? LIP : WHITE;
    end

    // one register stage so the picture is easy to time at 25 MHz
    always @(posedge clk) rgb <= rgb_next;

endmodule
