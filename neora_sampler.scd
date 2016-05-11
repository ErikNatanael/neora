//////////// Neora Sampler \\\\\\\\\\\\\\\\\\\


// Start server
(
s = Server.local;
s.options.memSize_(65536 * 4);
s.boot;
)

// Load required functions from files
"neora_create_channel.scd".resolveRelative.loadPaths;

// Load parameters
(
~globalParams = (
	sampleRate: s.sampleRate,
	numberOfChannels: 8
);
~recParams = (
	maxBufferLength: 60 * 5,    //The buffer length in seconds
	saveFilePath: "/home/erik/Dokument/SuperCollider/neora/recorded/"
);
~channels = Array.fill(8, {~createChannel.value()});
~currentChannel = 0;
~masterChannel = ~createChannel.value();
)

// Allocate buffers
~localRecBuffer = Buffer.alloc(s, s.sampleRate * ~recParams.maxBufferLength, 1); // A buffer only for recording

// Load recording SynthDefs
(
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
SynthDef(\play_buffer, { |bufnum, outBus = 0, amp = 1, start = 0, end = 1|
	var index, src, env, dur;
	dur = end - start / BufSampleRate.ir(bufnum);
	// Scroll through the buffer
	index = Line.ar(start, end, dur, doneAction: 2);
	//index = Phasor.ar(trig: 0,  rate: BufRateScale.kr(bufnum), start: start, end: end);

	// WARNING: The phase (index) argument of the BufRd only has the resolution to play up to ca 6.3 min at 44100.
	src = BufRd.ar(1, bufnum, index, interpolation: 2, loop: 0);

	Out.ar(outBus, src);
}).add;
)

Synth(\play_buffer, [\bufnum, ~channel1.buffer, \start, ~channel1.start, \end, ~channel1.end]);
{{PlayBuf.ar(1, ~sf.asBuffer)*0.5}!2}.play;

// Load OSCresponders

"neora_osc.scd".resolveRelative.loadPaths;

// Create GUI

"neora_gui.scd".resolveRelative.loadPaths;

// Set NanoKontrol2 input

"neora_nano.scd".resolveRelative.loadPaths;

