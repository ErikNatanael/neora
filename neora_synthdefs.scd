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

// You always have to supply the end argument
SynthDef(\play_buffer, { |bufnum, outBus = 0, amp = 1, start = 0, end = 1, attack = 0.01, release = 0.01|
	var index, src, env, dur;
	dur = end - start / BufSampleRate.ir(bufnum); // Duration in seconds

	env = EnvGen.kr(Env(
		levels: [0, 1, 0],
		times: [attack, dur - (attack + release), release]
	));
	// Scroll through the buffer
	index = Line.ar(start, end, dur, doneAction: 2);
	//index = Phasor.ar(trig: 0,  rate: BufRateScale.kr(bufnum), start: start, end: end);

	// WARNING: The phase (index) argument of the BufRd only has the resolution to play up to ca 6.3 min at 44100.
	src = BufRd.ar(1, bufnum, index, interpolation: 2, loop: 0);
	src = src * env;

	Out.ar(outBus, src);
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
	sig = (in*1000).tanh;
	sig = sig * amp;
	// sig = Decimator.ar(sig, s.sampleRate, 24);
	sig = Mix([sig * mix, in * (1-mix)]);

	Out.ar(outBus, sig);
}).add;
