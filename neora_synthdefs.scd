/////////////////////// SynthDefs for the Neora live sampler instrument \\\\\\\\\\\\\\\\\\\\\


SynthDef(\record_buffer, { |bufnum, inChan = 0, reclevel = 1.0, prelevel = 0.0, run = 1,
	stopTrig = 0, trigID = 1|
	var in, time;

	in = SoundIn.ar(inChan);
	time = Line.kr(0, ~recParams.maxBufferLength, ~recParams.maxBufferLength); //Measure the time recorded in seconds
	RecordBuf.ar(in, bufnum, 0, reclevel, prelevel, run, loop: 0);
	SendTrig.kr(stopTrig, trigID, time); //Send the time recorded to the language
	FreeSelf.kr(stopTrig);
	Line.kr(0, 1, ~recParams.maxBufferLength, doneAction: 2); //Frees the synth after 3 minutes
}).add;

SynthDef(\record_output, { |bufnum, inBus = 10, reclevel = 1.0, prelevel = 0.0, run = 1,
	stopTrig = 0, trigID = 1|
	var in, time;

	in = In.ar(inBus);
	time = Line.kr(0, ~recParams.maxBufferLength, ~recParams.maxBufferLength); //Measure the time recorded in seconds
	RecordBuf.ar(in, bufnum, 0, reclevel, prelevel, run, loop: 0);
	SendTrig.kr(stopTrig, trigID, time); //Send the time recorded to the language
	FreeSelf.kr(stopTrig);
	Line.kr(0, 1, ~recParams.maxBufferLength, doneAction: 2); //Frees the synth after 3 minutes
}).add;


// You always have to supply the end argument
SynthDef(\play_buffer, { |bufnum, outBus = 0, amp = 1, start = 0, end = 1, attack = 0.01, release = 0.01,
	rate = 1, envTrigBus = 10|

	var index, src, env, dur;

	//Send a trigger to the envelope as soon as the synth is started
	Out.kr(envTrigBus, Impulse.kr(0));

	dur = end - start / BufSampleRate.ir(bufnum); // Duration in seconds

	env = EnvGen.kr(Env(
		levels: [0, 1, 0],
		times: [attack, dur - (attack + release), release]
	));
	// Scroll through the buffer
	index = Line.ar(start, end, dur / rate, doneAction: 2);
	//index = Phasor.ar(trig: 0,  rate: BufRateScale.kr(bufnum), start: start, end: end);

	// WARNING: The phase (index) argument of the BufRd only has the resolution to play up to ca 6.3 min at 44100.
	src = BufRd.ar(1, bufnum, index, interpolation: 4, loop: 0);
	src = src * env;

	Out.ar(outBus, src);
}).add;

// Play with granular synthesis
// TODO: Add jitter to the grain density/impulses to remove hum
SynthDef(\play_granular, {arg amp = 0.8, bufnum, envbuf,
	modtime = 60, rate = 1, outBus = 0, start = 0, end = 0, grainSize = 0.01, density = 100, speed = 1, jitter = 0.1;
	var env, posmod, grainmod, numSecs, synthDur;
	//pan = LFNoise1.kr(rrand(0.1, 0.3));

	numSecs = BufSamples.kr(bufnum)/BufSampleRate.kr(bufnum); // number of seconds in the buffer
	posmod = Phasor.ar(0,
		// rate has to be based on sample rate and number of samples to be played
		rate: 1/(s.sampleRate*numSecs) * speed, // BufRateScale is not the right thing because it assumes going from 0 to numFrames
		start: start,
		end: end,
	);

	// Calculate how long it will take to play the synth through
	synthDur = numSecs - (numSecs * start) - (numSecs * (1-end)); // First remove the time up to and after start and end
	synthDur = synthDur / speed; // Then compensate for speed ( == synthDur * (1/speed) )

	env = EnvGen.kr(
		Env([0, 1, 1, 0], [0.0001, synthDur - 0.0002, 0.0001]),
		doneAction: 2);

	//grainmod = Dust.kr(SinOsc.kr(1/5).range(20, 30));
	// Add jitter to the grain density/impulses to remove hum
	grainmod = TDuty.ar(1 / (density * Dwhite(1 - jitter, 1 + jitter, inf)));

	//grainsizemod = LFNoise1.kr(1/5).range(0.05, 0.5);
	//grainsizemod = TExpRand.kr(0.4, 1, trigger);

	Out.ar(outBus,
		GrainBuf.ar(1, grainmod, grainSize, bufnum, rate,
			posmod, 4, envbufnum: -1) * env)
}).add;

SynthDef(\loop_granular, {arg amp = 0.8, bufnum, envbuf, gate = 1, envTrigBus = 10,
	modtime = 60, rate = 1, outBus = 0, start = 0, end = 0, pos = 0, grainSize = 0.01, density = 100, speed = 1,  jitter = 0.1;
	var env, posmod, grainmod, grainsizemod, trigmod, trigger, sig, numSecs;
	//pan = LFNoise1.kr(rrand(0.1, 0.3));
	env = EnvGen.kr(
		Env([0, 1, 0], [0.001, 0.1], releaseNode: 1),
		gate: gate,
		doneAction: 2);

	//trigger = Dust.kr(Rand(0.5, 2));

	//posmod = LFNoise2.kr(posrate).range(0.05, 0.95);
	//posmod = Line.kr(0.05, 0.95, posrate);

	numSecs = BufSamples.kr(bufnum)/BufSampleRate.kr(bufnum); // number of seconds in the buffer
	posmod = Phasor.ar(0,
		// rate has to be based on sample rate and number of samples to be played
		rate: 1/(s.sampleRate*numSecs) * speed, // BufRateScale is not the right thing because it assumes going from 0 to numFrames
		start: start,
		end: end,
	);
	// Send envelope trigger.
	// HPZ1 compares two samples of the Phasor. If it jumps back, the difference is < 0, thereby creating a trigger
	// (this only works if start<end, a more general solution would use Changed.kr)
	// Also send a trigger when the synth is just starting (Impulse)
	Out.kr(envTrigBus, (HPZ1.kr(A2K.kr(posmod)) < 0) + Impulse.kr(0));

	//grainmod = Dust.kr(SinOsc.kr(1/5).range(20, 30));
	// Add jitter to the grain density/impulses to remove hum
	grainmod = TDuty.ar(1 / (density * Dwhite(1 - jitter, 1 + jitter, inf)));

	//grainsizemod = LFNoise1.kr(1/5).range(0.05, 0.5);
	//grainsizemod = TExpRand.kr(0.4, 1, trigger);

	sig = GrainBuf.ar(1, grainmod, grainSize, bufnum, rate,
			posmod, 4, envbufnum: envbuf);
	sig = sig * env;

	Out.ar(outBus, sig)
}).add;

SynthDef(\reverb, { |inBus, outBus = 0, t60 = 1, damp = 0, size = 1, earlyDiff = 0.707, modDepth = 0.1, modFreq = 2, low = 1, mid = 1, high = 1, lowcut = 500, highcut = 2000 |
	var src, in, sig;
	in = In.ar(inBus, 1); // Input to JPverb can be either one or two channels
	src = JPverb.ar(in, t60, damp, size, earlyDiff, modDepth, modFreq, low, mid, high, lowcut, highcut);
	//sig = Mix([src * mix, in * (1-mix)]);
	sig = src;
	Out.ar(outBus, sig);
}).add;

SynthDef(\comb_delay, { | inBus, outBus = 0, delaytime = 0.2, decaytime = 1, mix = 0.3 |
	var in, src, sig;
	in = In.ar(inBus, 1);
	src = CombC.ar(in, 1, delaytime, decaytime);
	sig = Mix([src * mix, in * (1-mix)]);

	Out.ar(outBus, sig);
}).add;

SynthDef(\comb_filter, { | inBus, outBus = 0, pitch = 40, feedback = 1, mix = 0.3, lfoDepth = 0, lfoFreq = 8 |
	var in, src, sig, lfo, osc;
	in = In.ar(inBus, 1);
	lfo = SinOsc.kr(lfoFreq).range(1-lfoDepth, 1+lfoDepth);
	src = CombC.ar(in, 2, (pitch * lfo).reciprocal, feedback);
	sig = Mix([src * mix, in * (1-mix)]);

	Out.ar(outBus, sig);
}).add;

SynthDef(\split, { | inBus, outBus1, outBus2, amp1 = 0, amp2 = 0 |
	var in = In.ar(inBus, 1);
	Out.ar(outBus1, in * amp1);
	Out.ar(outBus2, in * amp2);
}).add;

// TODO: Amplitude match the dist with the original?
SynthDef(\distortion, { | inBus, outBus = 0, mix = 0.3|
	var in, sig, amp;
	in = In.ar(inBus, 1);
	amp = Amplitude.kr(in, 0.001, 0.001);
	sig = (in*50).tanh;
	sig = LPF.ar(sig, 7000);
	sig = sig * amp;
	// sig = Decimator.ar(sig, s.sampleRate, 24);
	sig = Mix([sig * mix, in * (1-mix)]);

	Out.ar(outBus, sig);
}).add;

SynthDef(\envelope, { | attackTime = 0.001, attackLevel = 1, decayTime = 0.01,
	decayLevel = 1, sustainTime = 0.5, sustainLevel = 1, releaseTime = 0.5,
	inTrigBus, inBus, outBus = 0, amp = 1 |
	var env, trig, in;
	in = In.ar(inBus, 1);
	trig = In.kr(inTrigBus, 1);
	env = EnvGen.kr(
		Env(
			[0, attackLevel, decayLevel, sustainLevel, 0],
			[attackTime, decayTime, sustainTime, releaseTime]
		),
		trig
	);

	Out.ar(outBus, in*env*Lag.kr(amp, 0.01));
}).add;

SynthDef(\master, { | inBus = 20, outBus = 0, amp = 1 |
	Out.ar(outBus, In.ar(inBus, 2)*amp);
}).add;

// numSecs = BufSamples.kr(bufnum)/BufSampleRate.kr(bufnum) // number of seconds in the buffer
// rate = 1/(s.sampleRate*numSecs)