/////////////////////// Creating a channel event object for the Neora instrument \\\\\\\\\\\\\\\\
/*
This uses Events as class prototypes. Remeber that, like in Python, the first argument to an event function is itself.
*/
~createChannel = { var startPos, endPos, buffer, soundFile, pbind, dur,
	eqBus, filterBus, distBus, envBus, delBus, revBus, masterBus,
	posSpec;
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

	posSpec = ControlSpec(0, 1);

	// The Event is returned because it is the last statement
	(
		startPos: startPos,
		endPos: endPos,
		buffer: buffer,
		soundFile: soundFile,
		pbind: pbind,
		dur: dur,
		playStyle: \granular,
		setLoopDur: { |self| var lengthSec, lengthOfBeat;
			lengthSec = (self.endPos-self.startPos)/s.sampleRate;
			lengthOfBeat = 1/~globalParams.clock.tempo;
			self.dur = lengthSec/lengthOfBeat;
		},
		updatePbind: { | self |
			self.pbind = Pbind(
				\instrument, \play_buffer,
				\dur, self.dur,
				\bufnum, self.buffer,
				\start, self.startPos,
				\end, self.endPos,
				\attack, 0.001,
				\release, 0.001,
				\outBus, distBus
			);
		},
		updatePosSpec: { | self |
			var size = self.buffer.numFrames,
			start = self.startPos/size,
			end = self.endPos/size;
			self.posSpec = ControlSpec(start, end);
		},
		// NEVER USE play OR stop IN AN EVENT
		playChan: { | self |
			self.streamer.stop();
			switch(self.playStyle)
			{\playLoop} {
				self.setLoopDur.value();
				self.updatePbind.value();
				self.streamer = self.pbind.play(~globalParams.clock, quant: ~channels[~currentChannel].dur);
			}
			{\granular} {
				var size = self.buffer.numFrames,
				start = self.startPos/size,
				end = self.endPos/size;
				/*self.grainSynth = Synth(\play_granular, [
					\outBus, distBus,
					\bufnum, self.buffer,
					\winenv, ~globalParams.winenv,
					\density, 30,
					\rate, 1,
					\grainSize, 0.2,
					\pos, 0.3
					//\pos, self.startPos/self.buffer.numFrames
				]);*/
				self.grainSynth = Synth(\loop_granular, [
					\outBus, distBus,
					\bufnum, self.buffer,
					\winenv, ~globalParams.winenv,
					\density, 30,
					\rate, 1,
					\grainSize, 0.2,
					\start, start,
					\end, end
				]);
			}
		},
		stopChan: { |self|
			switch(self.playStyle)
			{\playLoop} {
				self.streamer.stop();
			}
			{\granular} {
				self.grainSynth.set(\gate, 0);
			}
		},
		startSynths: { | self |

			self.revSynth = Synth(\split, [
				\inBus, revBus,
				\outBus1, 0,
				\amp1, 1,
				\outBus2, ~globalParams.revBus, // Output to global reverb synth
				\amp2, 0.4
			],
			target: ~globalParams.synthGroup,
			addAction: \addBefore);

			self.delSynth = Synth(\comb_delay, [
				\inBus, delBus,
				\outBus, revBus
			],
			target: self.revSynth,
			addAction: \addBefore);

			// Skip envelope for the time being

			self.distSynth = Synth(\distortion, [
				\inBus, distBus,
				\outBus, delBus,
				\mix, 0
			],
			target: self.delSynth,
			addAction: \addBefore);
		},
		// nil variables provided for reference. No error passed if they wouldn't be here
		streamer: nil,
		grainSynth: nil,
		eqSynth: nil,
		filterSynth: nil,
		distSynth: nil,
		envSynth: nil,
		delSynth: nil,
		revSynth: nil,
		masterSynth: nil;
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