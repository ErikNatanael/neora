/////////////////////// Creating a channel event object for the Neora instrument \\\\\\\\\\\\\\\\
/*
This uses Events as class prototypes. Remeber that, like in Python, the first argument to an event function is itself.
*/
~createChannel = { | index | // index is the number used for creating a symbol for th Pdef
	var startPos, endPos, buffer, soundFile, pbind, dur,
	eqBus, filterBus, distBus, envBus, delBus, revBus, masterBus, envTrigBus,
	posSpec, playRate, density, speed, grainSize, symbol;

	symbol = ("chan" ++ (index.asString)).asSymbol; // For use in the Pdef
	startPos = 0;
	endPos = 0;
	buffer = nil;
	soundFile = nil;
	dur = 1;
	playRate = 1; //rate is reserved
	density = 50;
	speed = 1;
	grainSize = 0.3;
	pbind = Pbind(
		\instrument, \play_granular,
		\dur, dur,
		\bufnum, buffer,
		\start, startPos,
		\end, endPos,
		\rate, playRate,
		\attack, 0.001,
		\release, 0.001,
		\grainSize, grainSize,
		\speed, speed,
		\density, density,
		\outBus, distBus
	);
	// The busses are private and are created on channel creation
	eqBus = Bus.audio(s, 1);
	filterBus = Bus.audio(s, 1);
	distBus = Bus.audio(s, 1);
	envBus = Bus.audio(s, 1);
	delBus = Bus.audio(s, 1);
	revBus = Bus.audio(s, 1);
	masterBus = Bus.audio(s, 1); // Could make the output from delay or reverb stereo

	envTrigBus = Bus.control(s, 1);

	posSpec = ControlSpec(0, 1);

	// The Event is returned because it is the last statement
	(
		startPos: startPos,
		endPos: endPos,
		buffer: buffer,
		soundFile: soundFile,
		pbind: pbind,
		dur: dur,
		playRate: playRate,
		density: density,
		speed: speed,
		grainSize: grainSize,
		playStyle: \loop, //Possibilities: \loop = granular looping, \seq = granular playing one time through in pbind
		// Envelope settings:
		attackTimeRatio: 0.1, // Time as a percentage of the length of the selection
		attackLevel: 0.9,
		sustainTimeRatio: 0.8,
		sustainLevel: 0.7,
		decayTimeRatio: 0.1,
		activeEnvelopeNode: 0,
		numEnvNodes: 2,
		setLoopDur: { |self| var lengthSec, lengthOfBeat;
			lengthSec = (self.endPos-self.startPos)/s.sampleRate;
			lengthOfBeat = 1/~globalParams.clock.tempo;
			self.dur = lengthSec/lengthOfBeat;
		},
		updatePbind: { | self | // Change to pdef
			var size = self.buffer.numFrames,
			start = self.startPos/size,
			end = self.endPos/size;
			/*self.pbind = Pbind(
				\instrument, \play_granular,
				\dur, self.dur,
				\bufnum, self.buffer,
				\start, start,
				\end, end,
				\rate, self.playRate,
				\attack, 0.001,
				\release, 0.001,
				\grainSize, self.grainSize,
				\speed, self.speed,
				\density, self.density,
				\outBus, distBus
			);*/
			self.pbind = Pbind(
				\instrument, \play_buffer,
				\dur, self.dur,
				\bufnum, self.buffer,
				\start, self.startPos,
				\end, self.endPos,
				\rate, self.playRate,
				\speed, self.speed,
				\envTrigBus, envTrigBus,
				\outBus, distBus
			);
		},
		updatePdef: { |self |
			self.updatePbind.value();
			Pdef(symbol, self.pbind);
		},
		updatePosSpec: { | self |
			var size = self.buffer.numFrames,
			start = self.startPos/size,
			end = self.endPos/size;
			self.posSpec = ControlSpec(start, end);
		},
		updatePlaying: { | self |
			var size = self.buffer.numFrames,
			start = self.startPos/size,
			end = self.endPos/size;
			self.updateEnvelope.value();
			switch(self.playStyle)
			{\loop} {
				self.grainSynth.set(\density, self.density);
				self.grainSynth.set(\grainSize, self.grainSize);
				self.grainSynth.set(\rate, self.playRate);
				self.grainSynth.set(\speed, self.speed);
				self.grainSynth.set(\start, start);
				self.grainSynth.set(\end, end);
				//self.grainSynth.set(\grainSize, self.grainSize);
			}
			{\seq} {
				//self.playChan.value();
				self.updatePdef.value();
			};

		},
		// NEVER USE play OR stop IN AN EVENT, they are reserved
		playChan: { | self |
			var size = self.buffer.numFrames,
			start = self.startPos/size,
			end = self.endPos/size;
			//if(self.streamer != nil, {self.streamer.stop() });
			if(self.grainSynth != nil, {self.grainSynth.release() });
			self.updateEnvelope.value();
			switch(self.playStyle)
			{\seq} {
				//self.setLoopDur.value();

				self.updatePdef.value();
				Pdef(symbol).play(~globalParams.clock, quant: 1);
				//self.streamer = self.pbind.play(~globalParams.clock, quant: ~channels[~currentChannel].dur);
			}
			{\loop} {

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
					\envTrigBus, envTrigBus,
					\bufnum, self.buffer,
					\winenv, ~globalParams.winenv,
					\density, self.density,
					\rate, self.playRate,
					\grainSize, self.grainSize,
					\speed, self.speed,
					\start, start,
					\end, end
				]);
			}
		},
		playOnce: { | self |

			Synth(\play_buffer, [
				\bufnum, self.buffer,
				\start, self.startPos,
				\end, self.endPos,
				\rate, self.playRate,
				\speed, self.speed,
				\envTrigBus, envTrigBus,
				\outBus, distBus]
			);
			"Channel played once".postln;
		},
		stopChan: { |self|
			switch(self.playStyle)
			{\seq} {
				//self.streamer.stop();
				Pdef(symbol).stop;
			}
			{\loop} {
				self.grainSynth.set(\gate, 0);
			}
		},
		updateEnvelope: { |self|
			var size = self.buffer.numFrames,
			length = (size - self.startPos - ( size - self.endPos)) / self.buffer.sampleRate;

			self.envSynth.set(\attackTime, self.attackTimeRatio*length/self.speed);
			self.envSynth.set(\sustainTime, self.sustainTimeRatio*length/self.speed);
			self.decayTimeRatio = 1 - (self.attackTimeRatio + self.sustainTimeRatio);
			self.envSynth.set(\decayTime, self.decayTimeRatio*length/self.speed);

			self.envSynth.set(\attackLevel, self.attackLevel);
			self.envSynth.set(\sustainLevel, self.sustainLevel);
		},
		startSynths: { | self |

			self.revSynth = Synth(\split, [
				\inBus, revBus,
				\outBus1, ~globalParams.masterBus,
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

			self.envSynth = Synth(\envelope, [
				\inBus, envBus,
				\outBus, delBus,
				\inTrigBus, envTrigBus
			],
			target: self.delSynth,
			addAction: \addBefore);

			self.distSynth = Synth(\distortion, [
				\inBus, distBus,
				\outBus, envBus,
				\mix, 0
			],
			target: self.envSynth,
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

Pdef(\channil).stop;
*/