//////////// Neora Sampler \\\\\\\\\\\\\\\\\\\


// Start server
(
s = Server.local;
s.options.memSize_(65536 * 4); // JPverb recommends this
s.options.numAudioBusChannels_(512); // We need a lot of busses, especially while testing
s.boot;
)

(
Task({ var winenv;
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

	// Granular winenv
	winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);


	// Load parameters
	~globalParams = (
		sampleRate: s.sampleRate,
		numberOfChannels: 8,
		// Tempo for the TempoClock is set in beats per second; bpm/60
		clock: TempoClock(110/60),
		recordingSource: \input, // \input \output
		revBus: Bus.audio(s, 1),
		masterBus: Bus.audio(s, 2),
		synthGroup: Group.new,
		activeView: \wave, // Possibilities: \wave, \delay, \dist, \reverb, \playback, \envelope
		updateRate: 0.02, // How long the tasks updating parameters whould wait between loops
		winenv: Buffer.sendCollection(s, winenv.discretize, 1),
		xySliderSize: 350, // Used for both width and height
		envelopeEditorWidth: 350,
		envelopeEditorHeight: 200,
		miniatureRatio: 3,
		maxLFOFreq: 20,
		rateRatios: [[16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
			[9/8/2, 5/4/2, 4/3/2, 3/2/2, 5/3/2, 15/8/2, 1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8],
			[1/2, 1/3, 1/4, 1/5, 1/6, 1/7, 1/8, 1/9, 1/10, 1/11, 1/12, 1/13, 1/14, 1/15, 1/16]];
	);
	~specs = (
		delayTime: ControlSpec(0.001, 1, \exp), // An exponential range cannot have 0 as its lowest number
		delayDecay: ControlSpec(-10, 10),
		mix: ControlSpec(0, 1),
		grainSize: ControlSpec(0.001, 1),
		grainDensity: ControlSpec(1, 100),
		grainRate: ControlSpec(0.25, 4, \exp),
		speed: ControlSpec(0.1, 10, \exp),
		attackTime: ControlSpec(0.0001, 1, \exp),
		decayTime: ControlSpec(0.01, 1, \exp)
	);
	~joyY = 0.5;
	~joyX = 0.5;

	~channels = Array.fill(8, {| index | ~createChannel.value(index)});
	~channels.do { | chan | chan.startSynths.value() };
	~currentChannel = 0;
	~masterChannel = ~createChannel.value(); // The master recording channel doesn't need synths


	// Allocate buffers
	~localRecBuffer = Buffer.alloc(s, s.sampleRate * ~recParams.maxBufferLength, 1); // A buffer only for recording

	// Start global synths
	~revSynth = Synth(\reverb, [
		\inBus, ~globalParams.revBus,
		\outBus, ~globalParams.masterBus,
		\t60, 3,
		\damp, 0.3,
		\size, 3,
		\earlyDiff, 0.85
	],
	target: ~globalParams.synthGroup,
	);

	~masterSynth = Synth(\master, [\inBus, ~globalParams.masterBus, \outBus, 0], ~globalParams.synthGroup, \addAfter);

	// Read the previous channel files on startup
	Task({ // Needs to be a Task to sync after buffer allocation
		~globalParams.numberOfChannels.do { | index |
			f = SoundFile.new;
			if(f.openRead(~recParams.saveFilePath ++ index.asString ++ ".wav")) {
				~currentChannel = index;
				~channels[index].soundFile = f;
				~channels[index].buffer = Buffer.read(s, ~recParams.saveFilePath ++ index.asString ++ ".wav");
				s.sync();
				~channels[index].startPos = 0;
				~channels[index].endPos = ~channels[index].buffer.numFrames;
				~channels[index].selLength = ~channels[index].buffer.numFrames;
			};
		};
		~currentChannel = 0;
	}).play;

	// Read the master channel file on startup
	Task({ // Needs to be a Task to sync after buffer allocation
		f = SoundFile.new;
		if(f.openRead(~recParams.saveFilePath ++ "master.wav")) {
			~masterChannel.soundFile = f;
			~masterChannel.buffer = Buffer.read(s, ~recParams.saveFilePath ++ "master.wav");
			s.sync();
			~masterChannel.startPos = 0;
			~masterChannel.endPos = ~masterChannel.buffer.numFrames;
		};
	}).play;
}).play;
)

// Load OSCresponders

"neora_osc.scd".resolveRelative.loadPaths;

// Create GUI
(
"neora_gui_components.scd".resolveRelative.loadPaths;
"neora_gui.scd".resolveRelative.loadPaths;
)

// Set NanoKontrol2 input

"neora_nano.scd".resolveRelative.loadPaths;

// Set joystick input

"neora_hid.scd".resolveRelative.loadPaths;
