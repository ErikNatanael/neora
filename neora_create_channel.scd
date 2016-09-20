/////////////////////// Creating a channel event object for the Neora instrument \\\\\\\\\\\\\\\\

// Helper functions\\\\\\\\\\\\\\\
~createScaleSelectionMatrix = { | octave, numRows, numNotes |
	var matrix = [];
	numRows.do { |i|
		var row = []; // degrees and octaves are stored in pairs [scaleIndex, octave]
		numNotes.do { |j| var scaleIndex, noteOctave = 0;
			if(i%2 == 0) { //even row (0, 2, 4, 6...)
				// Add 1 if it is the first element
				if(j == 0) { scaleIndex = 0; noteOctave = 1} { scaleIndex = numNotes-j};
				noteOctave = noteOctave + (octave + (numRows-i));
			} {
				//odd row (1, 3, 5, 7...)
				scaleIndex = (j + 1) % numNotes;
				noteOctave = noteOctave + (octave + (numRows-i)); // Octave gets lower on higher number rows
				noteOctave = noteOctave + (j/(numNotes-1)).trunc(1); // Adds 1 if it is the last element
			};
			row = row.add([scaleIndex, noteOctave]);
		};
		matrix = matrix.add(row);
	};
	matrix
};



/*
This uses Events as class prototypes. Remeber that, like in Python, the first argument to an event function is itself.
*/
~createChannel = { | index | // index is the number used for creating a symbol for th Pdef
	var startPos, endPos, buffer, soundFile, pbind, dur,
	eqBus, filterBus, distBus, envBus, delBus, revBus, masterBus, envTrigBus, combBus,
	posSpec, playRate, density, speed, grainSize, symbol, octave, scale, rootNote, pitchMatrix, playBus;

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

	playBus = eqBus;

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
		\outBus, playBus
	);

	// Pitch stuff
	scale = ~globalParams.scales[0][0]; // A list of Scale objects
	rootNote = 2;
	octave = 4;
	pitchMatrix = ~createScaleSelectionMatrix.value(octave, 4, scale.degrees.size);

	// The Event is returned because it is the last statement
	(
		playBus: playBus, // The bus to which all sample playing synths write their data
		amplitude: 0.5,
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
		// Comb filter
		combLFOFreq: 1,
		combLFODepth: 0,
		combFreq: 80,
		combMix: 0.0,
		combFeedback: 0,
		combLPFFreq: 20000,
		combPitchGrid: false,
		// Pitch selection
		scale: scale,
		rootNote: rootNote,
		octave: octave,
		pitches: [200, 400, 800, 1600], // Current pitches in freq
		playingPitchesIndexes: Set.new, // Contains the set containing the coordinates for the currently playing pitches
		selectedPitches: Set.new, // Selected future pitches in coordinates to the matrix [row, column]
		pitchMatrix: pitchMatrix,

		// Resonant filters
		resdbs: [24], // Must be the same size as pitches
		resrqs: [0.1], // Must be the same size as pitches
		resPartialRatio: 0.5,
		numPartials: 10,
		resdb: 24,
		resdbTilt: 1, // How much the amplitude should be tilted from the middle
		resrq: 0.1,
		resFade: 0.05, // Allows one to set a higher fade value when change are not rapid (so rapid that they create too many nodes)
		whiteNoiseAmp: 0.0,

		// Reverb/delay settings
		reverbMix: 0.2,
		delayMix: 0.3,
		delayTime: 0.3,
		delayFeedback: 0.3,

		//Effects settings
		distortionMix: 0.0,

		// Sequencer stuff
		seqTab: \dur, // \dur, \speed, \amp, \jumpf
		durPattern: \pseq, // \pseq, \prand, \pxrand, \pwrand
		durValues: [1, 1, 0, 0], // What note values are permitted (normal, triplets, quintuplets, septuplets)
		durNormal: [1/8, 1/4, 1/2, 1, 2, 4],
		durTriplets: [1/12, 1/6, 1/3, 4/3, 8/3],
		durNoteValues: [], // initialised at creation by self.updateDurNoteValues
		durList: [1, 0.125, 0.125, 1, 0, 0, 0, 0], // 8 cells
		durList2: [0, 0, 0, 0, 0, 0, 0, 0], //only used for pseq
		durWeights: [1, 1, 1, 1, 1, 1, 1, 1],
		selectedDur: -1, // -1 = none
		selectedWeight: -1, // -1 = none

		setLoopDur: { |self| var lengthSec, lengthOfBeat;
			lengthSec = (self.endPos-self.startPos)/s.sampleRate;
			lengthOfBeat = 1/~globalParams.clock.tempo;
			self.dur = lengthSec/lengthOfBeat;
		},
		updatePbind: { | self | // Change to pdef
			var size = self.buffer.numFrames,
			start = self.startPos/size,
			end = self.endPos/size,
			durP;

			switch(self.durPattern)
			{\pseq} {
				durP = Pseq(self.durList.addAll(self.durList2), inf);
			}
			{\prand} {
				durP = Prand(self.durList, inf)
			}
			{\pxrand} {
				durP = Pxrand(self.durList, inf)
			}
			{\pwrand} {
				durP = Pwrand(self.durList, self.durWeights.normalizeSum, inf);
			};
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
				\dur, durP,
				\bufnum, self.buffer,
				\start, self.startPos,
				\end, self.endPos,
				\rate, self.playRate,
				\speed, self.speed,
				\envTrigBus, envTrigBus,
				\outBus, self.playBus
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
			}
			{\jump} {
				self.grainSynth.set(\density, self.density);
				self.grainSynth.set(\grainSize, self.grainSize);
				self.grainSynth.set(\rate, self.playRate);
				self.grainSynth.set(\speed, self.speed);
				self.grainSynth.set(\start, start);
				self.grainSynth.set(\end, end);
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
					\outBus, self.playBus,
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
			{\jump} {
				self.grainSynth = Synth(\jump_granular, [
					\outBus, self.playBus,
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
				\outBus, self.playBus]
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
			{\jump} {
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
		updateReverb: { | self |
			self.revSynth.set(\amp2, self.reverbMix);
		},
		updateDelay: { | self |
			self.delSynth.set(\mix, self.delayMix);
			self.delSynth.set(\delaytime, self.delayTime);
			self.delSynth.set(\feedback, self.delayFeedback);
		},
		updateDistortion: { |self |
			self.distSynth.set(\mix, self.distortionMix);
		},
		updateComb: { | self |
			self.combSynths.do { |synth|
				synth.set(\mix, self.combMix,
					\feedback, self.combFeedback,
					\lfoDepth, self.combLFODepth,
					\lfoFreq, self.combLFOFreq,
					\lpfFreq, self.combLPFFreq
				);
			};
		},
		selectPitch: { |self, index|
			if(self.selectedPitches.includes(index) == false) {
				self.selectedPitches.add(index)
			} {
				self.selectedPitches.remove(index)
			};
		},
		updatePitches: { | self |
			self.playingPitchesIndex = self.selectedPitches.copy;
			self.pitches = [];
			// Calculate the new frequencies
			self.playingPitchesIndex.do { |item|
				var freq, row = item[0], column = item[1];
				freq = self.scale.degreeToFreq(self.pitchMatrix[row][column][0], self.rootNote, self.pitchMatrix[row][column][1]);
				self.pitches = self.pitches.add(freq);
			};
			("pitches: " + self.pitches.asString).postln;
			// Update all synths using these pitches
			self.combSynths.do { |synth|
				synth.release;
			};
			self.combSynths = [];
			self.pitches.do { |fr |
				self.combSynths = self.combSynths.add(
					Synth(\comb_filter, [
						\inBus, combBus,
						\outBus, distBus,
						\mix, self.combMix,
						\lfoFreq, self.combLFOFreq,
						\lfoDepth, self.combLFODepth,
						\pitch, fr,
						\feedback, self.combFeedback,
						\lpfFreq, self.combLPFFreq,
						\amp, 1/self.pitches.size
					],
					target: self.distSynth,
					addAction: \addBefore)
				);
				("fr: " + fr.asString).postln;
			};
			// Update resonant filters
			self.resFade = 0.5;
			self.createEQ();
		},
		updateResonant: { |self|
			var partialdb = self.numPartials.collect {|i| 1 * self.resPartialRatio.pow(i)};
			partialdb = partialdb.normalizeSum;

			self.resrqs = self.resrq!(self.pitches.size);
			self.resdbs = self.resdb!(self.pitches.size);

			self.pitches.do({ |item, i|
				self.numPartials.do({|j|
					self.resonantSynths[j*(i+1)].set(
						\rq, self.resrqs[i],
						\db, self.resdbs[i]*partialdb[j]
					);
				});
		});
		},
		createEQ: { |self|
			var partialdb = self.numPartials.collect {|i| 1 * self.resPartialRatio.pow(i)};
			partialdb = partialdb.normalizeSum;
			self.resonantSynths.do {|synth| synth.release(); };
			self.resrqs = self.resrq!(self.pitches.size);
			self.resdbs = self.resdb!(self.pitches.size);

			self.resonantSynths = self.pitches.collect({ |item, i|
				self.numPartials.collect({|j|
					Synth(\resonant_filter, [
						\freq, item*(j+1),
						\rq, self.resrqs[i],
						\db, self.resdbs[i]*partialdb[j],
						\inBus, self.playBus,
						\outBus, self.combBus,
						\fade, self.resFade
					],
					target: self.combSynths[0],
					addAction: \addBefore);
				});
		}).flat;
		},
		updateDurNoteValues: { |self|
			self.durNoteValues = [0]; // 0 is always available
			if(self.durValues[0] == 1) {
				self.durNoteValues = self.durNoteValues.addAll(self.durNormal);
			};
			if(self.durValues[1] == 1) {
				self.durNoteValues = self.durNoteValues.addAll(self.durTriplets);
			};
			self.durNoteValues = self.durNoteValues.sort;
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

			self.delSynth = Synth(\feedback_delay, [
				\inBus, delBus,
				\outBus, revBus,
				\delaytime, self.delayTime,
				\feedback, self.delayFeedback
			],
			target: self.revSynth,
			addAction: \addBefore);

			self.envSynth = Synth(\envelope, [
				\inBus, envBus,
				\outBus, delBus,
				\inTrigBus, envTrigBus,
				\amp, self.amplitude
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

			self.combSynths.add(Synth(\comb_filter, [
				\inBus, combBus,
				\outBus, distBus,
				\mix, self.combMix,
				\lfoFreq, self.combLFOFreq,
				\lfoDepth, self.combLFODepth,
				\freq, self.combFreq,
				\lpfFreq, self.combLPFFreq,
				\feedback, self.combFeedback,
				\amp, 1
			],
			target: self.distSynth,
			addAction: \addBefore));

			self.createEQ();

			self.whiteSynth = Synth(\noise, [\amp, self.whiteNoiseAmp, \outBus, self.playBus],
				addAction: \addToHead);

			self.updateDurNoteValues();
		},
		combBus: combBus,
		// nil variables provided for reference. No error passed if they wouldn't be here
		streamer: nil,
		grainSynth: nil,
		eqSynth: nil,
		filterSynth: nil,
		distSynth: nil,
		envSynth: nil,
		delSynth: nil,
		revSynth: nil,
		combSynths: [],
		resonantSynths: [],
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