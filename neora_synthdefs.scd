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
	src = src * min(amp, 1);

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
	modtime = 60, rate = 1, outBus = 0, start = 0, end = 0, grainSize = 0.01, density = 100, speed = 1,  jitter = 0.2;
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

	// Add jitter to the grain density/impulses to remove hum
	grainmod = TDuty.ar(1 / ((density * Dwhite(1 - jitter, 1 + jitter, inf))*rate));

	grainSize = grainSize/rate;

	sig = GrainBuf.ar(1, grainmod, grainSize, bufnum, rate,
			posmod, 4, envbufnum: envbuf);
	sig = sig * env;

	Out.ar(outBus, sig)
}).add;

SynthDef(\jump_granular, {arg amp = 0.8, bufnum, envbuf, gate = 1, envTrigBus = 10,
	modtime = 60, rate = 1, outBus = 0, start = 0, end = 0, grainSize = 0.01, density = 100, speed = 1,  jitter = 0.2, jumpRate = 2;
	var env, posmod, grainmod, grainsizemod, trigmod, trigger, sig, numSecs;

	env = EnvGen.kr(
		Env([0, 1, 0], [0.001, 0.1], releaseNode: 1),
		gate: gate,
		doneAction: 2);

	trigger = Impulse.kr(jumpRate);
	numSecs = BufSamples.kr(bufnum)/BufSampleRate.kr(bufnum);
	posmod = Phasor.ar(trig: trigger,
		rate: 1/(s.sampleRate*numSecs) * speed,
		start: start,
		end: end,
		resetPos: TRand.kr(start, end, trigger)
	);

	//posmod = Ramp.kr(posmod, 0.2); //Because of the envelope, this might be unnecessary

	// Trigger envelope on every jump
	Out.kr(envTrigBus, trigger);

	// Add jitter to the grain density/impulses to remove hum
	grainmod = TDuty.ar(1 / ((density * Dwhite(1 - jitter, 1 + jitter, inf))*rate));

	grainSize = grainSize/rate;

	sig = GrainBuf.ar(1, grainmod, grainSize, bufnum, rate,
		posmod, 4, envbufnum: envbuf);
	sig = sig * env;

	Out.ar(outBus, sig)
}).add;

// SynthDef from Daniel Mayer's Buffer Granulation tutorial
SynthDef(\gran_1b, { arg out = 0, bufNum = 0, posLo = 0.0, posHi = 1.0,
    posRateE = 0, posRateM = 1, posDev = 0.01, trigRate = 100, trigRateDev = 0,
    trigRateOsc = 1, granDur = 0.1, granDurDev = 0, rate = 1.0, rateDev = 0,
    panMax = 1, amp = 0.1, interp = 4, gate = 1;

    var trig, pan, pos, bufDur, bufDurSection, posDif, posRate, env;

	env = EnvGen.kr(
		Env([0, 1, 0], [0.001, 0.1], releaseNode: 1),
		gate: gate,
		doneAction: 2);

    posDif = posHi - posLo;
    bufDur = BufDur.kr(bufNum);
    bufDurSection = bufDur * posDif;
    trig = Impulse.kr(LFDNoise3.kr(trigRateOsc, trigRate * trigRateDev, trigRate));
    posRate = 10 ** posRateE * posRateM;
    pos = posLo * bufDur +
        (Phasor.ar(0, BufRateScale.kr(bufNum) * posRate / SampleRate.ir, posLo * bufDur, posHi * bufDur) +
        (TRand.kr(-0.5, 0.5, trig) * posDev * bufDur)).mod(bufDurSection);
    pan = Demand.kr(trig, 0, Dseq([panMax, panMax.neg],inf) * 0.999);
    Out.ar(out, TGrains.ar(2, trig, bufNum, rate * (TRand.kr(-1, 1.0, trig) * rateDev + 1), pos,
        granDur * (TRand.kr(-1, 1.0, trig) * granDurDev + 1), pan, amp * env, interp));
    }, metadata: (
        specs: (
            posLo: [0.01, 0.99, \lin, 0.01, 0],
            posHi: [0.01, 0.99, \lin, 0.01, 1],
            posRateE: [-3, 4, \lin, 1, 0],
            posRateM: [0.1, 10, \exp, 0.01, 1],
            posDev: [0, 0.2, 5, 0, 0.05],
            trigRate: [1, 200, \lin, 0.01, 100],
            trigRateDev: [0.0, 1, \lin, 0.01, 0],
            trigRateOsc: [0.1, 2, \lin, 0.01, 3],
            granDur: [0.01, 0.3, \lin, 0.01, 0.1],
            granDurDev: [0.0, 0.95, \lin, 0.01, 0],

            rate: [0.1, 2, \lin, 0.01, 1],
            rateDev: [0.0, 0.99, \linear, 0.01, 0.05],
            panMax: [0.0, 1, \lin, 0.005, 0.8],
            amp: [0.0, 0.5, \lin, 0.005, 0.25]
        )
    )
).add;

SynthDef(\reverb, { |inBus, outBus = 0, t60 = 1, damp = 0, size = 1, earlyDiff = 0.707, modDepth = 0.1, modFreq = 2, low = 1, mid = 1, high = 1, lowcut = 500, highcut = 2000 |
	var src, in, sig;
	in = In.ar(inBus, 2); // Input to JPverb can be either one or two channels
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

SynthDef(\feedback_delay, { | inBus, outBus = 0, delaytime = 0.2, feedback = 0.3, mix = 0.3|
	var in, src, sig, feed;
	in = In.ar(inBus, 1);
	feed = LocalIn.ar(1);
	// XFadeDelay from wslib quark, to avoid artificts when changing delaytime
	src = Limiter.ar(XFadeDelay.ar(in + feed, 1, delaytime));
	LocalOut.ar(src * feedback);
	sig = Mix([src * mix, in * (1-mix)]);

	Out.ar(outBus, Pan2.ar(sig));
}).add;

SynthDef(\comb_filter, { | inBus, outBus = 0, pitch = 40, feedback = 1, mix = 0.3, lfoDepth = 0, lfoFreq = 8, amp = 1, gate = 1, lpfFreq = 20000 |
	var in, src, sig, lfo, osc, releaseEnv;
	releaseEnv = EnvGen.kr(
		Env(
			levels: [0, 1, 1, 0],
			times: [ 1, 0.001, 1 ],
			releaseNode: 1),
		gate: gate,
		doneAction: 2
	);
	in = In.ar(inBus, 1);
	//lfo = SinOsc.kr(lfoFreq).range(1-lfoDepth, 1+lfoDepth);
	lfo = LFNoise2.kr(lfoFreq).range(1-lfoDepth, 1+lfoDepth);
	src = CombC.ar(in, 2, (pitch * lfo).reciprocal, feedback);
	//src = src * min((feedback.abs.reciprocal), 1);
	src = src * max(1 - (feedback * 0.01), 0);
	src = LPF.ar(src, lpfFreq);
	sig = Mix([src * mix, in * (1-mix)]);

	Out.ar(outBus, sig * amp * releaseEnv);
}).add;

SynthDef(\noise, { | outBus = 0, amp = 0 |
	var sig;
	sig = PinkNoise.ar(amp);

	Out.ar(outBus, sig);
}).add;

SynthDef(\resonant_filter, { | inBus, outBus = 0, freq = 440, db = 1, rq = 0.1, fade = 0.5, fadein = 0.5, amp = 1, gate = 1 |
	var in, env, sig;

	in = In.ar(inBus);
	sig = Resonz.ar(in, freq, rq) * db * (rq.reciprocal/100);
	env = EnvGen.kr(Env(
		levels: [0, 1, 1, 0],
		times: [fadein, 0.1, fade],
		releaseNode: 1),
	gate: gate,
	doneAction: 2);
	sig = Limiter.ar(sig, amp);

	Out.ar(outBus, sig*env*amp);
}).add;

SynthDef(\split, { | inBus, outBus1, outBus2, amp1 = 0, amp2 = 0 |
	var in = In.ar(inBus, 2);
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
	//sig = sig * amp;
	sig = sig * 0.5;
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
			[0, 0, attackLevel, decayLevel, sustainLevel, 0],
			[0.005, attackTime, decayTime, sustainTime, releaseTime]
		),
		trig
	);

	Out.ar(outBus, in*env*Lag.kr(amp, 0.01));
}).add;

SynthDef(\master, { | inBus = 20, outBus = 0, amp = 1 |
	var in = In.ar(inBus, 2);
	in = in*VarLag.kr(amp, 0.01, 0, \linear);
	in = Limiter.ar(in);
	Out.ar(outBus, in);
}).add;

// numSecs = BufSamples.kr(bufnum)/BufSampleRate.kr(bufnum) // number of seconds in the buffer
// rate = 1/(s.sampleRate*numSecs)