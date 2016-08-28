/*
Ideas for a reverse reverb:

Analyse the amplitude to find good places to lead up to.
The reverse reverb is stored in a parallell buffer. The playhead reads until an amplitude peak and then jumps to right before the next peak.
The buffer is effectively divided up into segments.
Maybe it isn't more complicated than to record the reversed reverb and then play it back with a negative delay.

*/