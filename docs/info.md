## How it works

An eight key instrument with a piano hero game on the VGA screen.

**Sound.** Each key is debounced. Every key held plays its own sine wave, so you can play chords. A mixer adds the sines together and a PWM block makes the audio signal on uio[0] (and uio[7], for the audio PMOD).

**Game.** The Mario theme falls down the screen as coloured tiles, one lane for each key (ui[0] is C4 on the left, up to ui[7] as C5 on the right). When a tile reaches the piano, hold that key until the tile has gone past. A key that is held goes down: green if it is the right key and the only key held, red if not. The bar along the top fills up with every frame of right notes, and the grey track shows what a perfect run scores. The song loops.

The tune is moved onto the eight white keys: down an octave, with the notes that fall below C4 moved back up an octave and the one black note (Bb) played as A.

## How to test

Use a 25 MHz clock (the VGA pixel clock). Connect a VGA PMOD, or the TinyVGA PMOD, to uo and look at the screen. Flip the key inputs ui[0] to ui[7] to play.

## External hardware

Eight push buttons or switches on ui[0] to ui[7], a TinyVGA PMOD on uo, and an RC filter and speaker (or the audio PMOD) on uio[0] or uio[7].
