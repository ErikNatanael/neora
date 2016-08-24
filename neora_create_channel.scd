/////////////////////// Creating a channel event object for the Neora instrument \\\\\\\\\\\\\\\\
/*
This uses Events as class prototypes. Remeber that, like in Python, the first argument to an event function is itself.
*/
~createChannel = { | index | // index is the number used for creating a symbol for th Pdef
	var startPos, endPos, buffer, soundFile, pbind, dur,
	eqBus, filterBus, distBus, envBus, delBus, revBus, masterBus, envTrigBus, combBus,
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
	combBus = Bus.audio(s, 1);
	revBus = Bus.audio(s, 1);
	masterBus = Bus.audio(s, 1); // Could make the output from delay or reverb stereo

	envTrigBus = Bus.control(s, 1);

	posSpec = ControlSpec(0, 1);

	// The Event is returned because it is the last statement
	(
		startPos: startPos,
		endPos: endPos,
		selLength: 0,
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
		attackTime: 0.1,
		attackLevel: 1,
		decayTime: 0.1,
		decayLevel: 0.7,
		sustainTime: 0.8,
		sustainLevel: 0.7,
		releaseTime: 0.1,
		releaseTimeRatio: 1,
		combLFOFreq: 8,
		combLFODepth: 0,
		combFreq: 80,
		combMix: 0.5,
		combFeedback: 1,
		combPitchGrid: false,

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
					\outBus, combBus,
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
		updateSustainTime: { | self, z |
			self.sustainTime = 0.1 + (z * (self.selLength/self.buffer.sampleRate - 0.1));
		},
		updateEnvelopeXY: { |self, x, y |
			self.attackTime = ~specs.attackTime.map(x);
			self.decayTime = ~specs.decayTime.map(y);
			self.updateEnvelope();
		},
		updateEnvelope: { |self|
			var size = self.buffer.numFrames,
			selectionLength = (size - self.startPos - ( size - self.endPos)) / self.buffer.sampleRate,
			envLength = self.attackTime + self.decayTime + self.sustainTime;

			// Make sure the envelope is not longer than the selection
			if(envLength > selectionLength) {
				var overflow = envLength - selectionLength;
				if (overflow > (self.sustainTime - 0.1), {
					// If reducing the sustainTime is not enough
					overflow = overflow - (self.sustainTime - 0.1);
					self.sustainTime = 0.1;
					self.attackTime = self.attackTime - (overflow / 2);
					self.releaseTime = self.releaseTime - (overflow / 2);
				}, {
					// otherwise just reduce the sustainTime
					self.sustainTime = self.sustainTime - overflow;
				});
				// recalculate the envelope length
				envLength = self.attackTime + self.decayTime + self.sustainTime;
			};

			// Calculate the releaseTime
			self.releaseTime = (selectionLength - envLength) * self.releaseTimeRatio;

			self.envSynth.set(\attackTime, self.attackTime);
			self.envSynth.set(\decayTime, self.decayTime);
			self.envSynth.set(\sustainTime, self.sustainTime);
			self.envSynth.set(\releaseTime, self.releaseTime);

			self.envSynth.set(\attackLevel, self.attackLevel);
			self.envSynth.set(\decayLevel, self.decayLevel);
			self.envSynth.set(\sustainLevel, self.sustainLevel);
		},
		updateComb: { | self |
			self.combSynth.set(\pitch, self.combFreq,
				\mix, self.combMix,
				\feedback, self.combFeedback,
				\lfoDepth, self.combLFODepth,
				\lfoFreq, self.combLFOFreq
			);
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

			self.combSynth = Synth(\comb_filter, [
				\inBus, combBus,
				\outBus, distBus,
				\mix, self.combMix,
				\lfoFreq, self.combLFOFreq,
				\lfoDepth, self.combLFODepth,
				\freq, self.combFreq,
				\feedback, self.combFeedback
			],
			target: self.distSynth,
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
		combSynth: nil,
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