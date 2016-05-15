//////////// Neora Sampler \\\\\\\\\\\\\\\\\\\


// Start server
(
s = Server.local;
s.options.memSize_(65536 * 4); // JPverb recommends this
s.options.numAudioBusChannels_(512); // We need a lot of busses, especially while testing
s.boot;
)

(
Task({
	// recParams need to go before loading synth definitions
	~recParams = (
		maxBufferLength: 60 * 5,    //The buffer length in seconds 60 * 5 = 5min
		saveFilePath: "/home/erik/Dokument/SuperCollider/neora/recorded/"
	);

	// Load synth definitions
	"neora_synthdefs.scd".resolveRelative.loadPaths;
	s.sync(); // Make sure synthdefs are loaded before they need to be used

	// Load required functions from files
	"neora_create_channel.scd".resolveRelative.loadPaths;

	// Load parameters
	~globalParams = (
		sampleRate: s.sampleRate,
		numberOfChannels: 8,
		// Tempo for the TempoClock is set in beats per second; bpm/60
		clock: TempoClock(110/60),
		revBus: Bus.audio(s, 1),
		synthGroup: Group.new;
	);

	~channels = Array.fill(8, {~createChannel.value()});
	~channels.do { | chan | chan.startSynths.value() };
	~currentChannel = 0;
	~masterChannel = ~createChannel.value(); // The master recording channel doesn't need synths


	// Allocate buffers
	~localRecBuffer = Buffer.alloc(s, s.sampleRate * ~recParams.maxBufferLength, 1); // A buffer only for recording

	// Start global synths
	~revSynth = Synth(\reverb, [
		\inBus, ~globalParams.revBus,
		\outBus, 0
	],
	target: ~globalParams.synthGroup,
	)
}).play;
)

Synth(\play_buffer, [\bufnum, ~channel1.buffer, \start, ~channel1.start, \end, ~channel1.end]);
{{PlayBuf.ar(1, ~sf.asBuffer)*0.5}!2}.play;

// Load OSCresponders

"neora_osc.scd".resolveRelative.loadPaths;

// Create GUI

"neora_gui.scd".resolveRelative.loadPaths;

// Set NanoKontrol2 input

"neora_nano.scd".resolveRelative.loadPaths;

5
