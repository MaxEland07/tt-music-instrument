## How it works

Each key is debounced, and the highest key held picks a note from a table of phase steps. Two phase accumulators run at the note and at half the note. One feeds a sine table, the other gives a square wave. A mixer averages them and a PWM block makes the audio signal.

## How to test

Filter uio[0] with an RC filter and feed it to a speaker or headphones. Press the keys.

## External hardware

Eight push buttons, an RC filter and a speaker.
