/////////////////////// Creating a channel event object for the Neora instrument \\\\\\\\\\\\\\\\
/*
This uses Events as class prototypes. Remeber that, like in Python, the first argument to an event function is itself.
*/
(
~createChannel = { var startPos, endPos, buffer, soundFile, pbind, dur, eqBus, filterBus, distBus, envBus, delBus, revBus;
	startPos = 0;
	endPos = 0;
	buffer = nil;
	soundFile = nil;
	dur = 1;
	pbind = Pbind(
		\instrument, \play_buffer,
		\dur, dur,
		\bufnum, buffer,
		\start, startPos,
		\end, endPos
	);
	// The busses are private and are created on channel creation
	eqBus = Bus.audio(s, 1);
	filterBus = Bus.audio(s, 1);
	distBus = Bus.audio(s, 1);
	envBus = Bus.audio(s, 1);
	delBus = Bus.audio(s, 1);
	revBus = Bus.audio(s, 1);
	masterBus = Bus.audio(s, 1); // Could make the output from delay or reverb stereo
	// The Event is returned because it is the last statement
	(
		startPos: startPos,
		endPos: endPos,
		buffer: buffer,
		soundFile: soundFile,
		pbind: pbind,
		dur: dur,
		setLoopDur: { |self| var lengthSec, lengthOfBeat;
			lengthSec = (self.endPos-self.startPos)/s.sampleRate;
			lengthOfBeat = 1/~globalParams.clock.tempo;
			self.dur = lengthSec/lengthOfBeat;
			self.dur.postln;
		},
		updatePbind: { | self |
			self.pbind = Pbind(
				\instrument, \play_buffer,
				\dur, self.dur,
				\bufnum, self.buffer,
				\start, self.startPos,
				\end, self.endPos
			);
		},
		// nil variables provided for reference. No error passed if they wouldn't be here
		streamer: nil,
		eqSynth: nil,
		filterSynth: nil,
		distSynth: nil,
		envSynth: nil,
		delSynth: nil,
		revSynth: nil;
	)
};


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
