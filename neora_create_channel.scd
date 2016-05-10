/////////////////////// Creating a channel event object for the Neora instrument \\\\\\\\\\\\\\\\
/*
This uses Events as class prototypes. Remeber that, like in Python, the first argument to an event function is itself.
*/
(
~createChannel = {
	// The Event is returned because it is the last statement
	(
		startPos: 0,
		endPos: rrand(0, 100),
		buffer: nil,
		soundFile: nil;
	)
};
// Keeping this code in the meantime in case I would want to go back to set/get methods. Otherwise safe to remove.
~createChannel2 = {
	var startPos = 0,
	endPos = 0,
	buffer = nil,
	soundFile = nil;
	// The Event is returned because it is the last statement
	(
		getBuffer: {buffer},
		setBuffer: {|self, buf| buffer = buf; },
		getSoundFile: {soundFile},
		setSoundFile: {|self, sf| soundFile = sf},
		getStartPos: {startPos},
		setStartPos: {|self, sp| startPos = sp},
		getEndPos: {endPos},
		setEndPos: {|self, ep| endPos = ep},
		startPos: 0,
		endPos: 0,
		buffer: nil,
		soundFile: nil;
	)
};
)

/* Testing functionality code:
a = ~createChannel.value();
a.endPos = 70;
a.endPos
a.setStartPos(10);
a.startPos
a.buffer
a.buffer = Buffer.alloc(s, 500, 1);
a.getSoundFile
a.setSoundFile(SoundFile());
b = ~createChannel.value();
b.startPos
b.startPos = 5;
b.buffer = Buffer.alloc(s, 500, 1);
b.buffer;*/


/* More testing
b = ~createChannel2.value();
b.startPos
b.startPos = 5;
b.buffer = Buffer.alloc(s, 500, 1);
b.buffer;
c = ~createChannel2.value();
c.startPos
c.startPos = 40;
c.buffer = Buffer.alloc(s, 5600, 1);
c.buffer;
*/
