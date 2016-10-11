//////////////////// NanoKontrol2 input for Neora sampler \\\\\\\\\\\\\\\\\\\\\\\\\

Task({ var id;
	//MIDIClient.init;
	//5.wait;
	MIDIIn.connectAll;
	id = MIDIIn.findPort("nanoKONTROL2", "nanoKONTROL2 MIDI 1").uid;
	MIDIdef.new(\nanodef, { |val, num, chan, src |
		[val, num, chan, src].postln;
		switch(num,
			45, { // rec button
				if(val == 127, { // If pushed down
					"rec pushed".postln;
					{
					// Change the GUI button state
						~inputWin.recBut.action.value();

					}.defer();
				});
			},
			41, { // play button
				if(val == 127, { // If pushed down
					//"play pushed".postln;
					~instrWin.playBut.action.value();
				});
			},
			42, { // stop button
				if(val == 127, { // If pushed down
					//"stop pushed".postln;
					~instrWin.stopBut.action.value();
				});
			}
		);
		//Faders
		if((num >= 0) && (num <= 7)) {
			// Sets the amplitude setting on the envelope synth for the channel
			// Uses a little trick for making an exponential curve that starts at 0
			~channels[num].amplitude = (val/127).linexp(0, 1, 0.1, 1.1)-0.1;
			~channels[num].masterSynth.set(\amp, ~channels[num].amplitude);
			("amp: " + ~channels[num].amplitude.asString).postln;
		};
		if((num >= 32) && (num <= 39) && (val == 127)) { // Channel S buttons
			{~instrWin.channelButtons[num-32].action.value(~instrWin.channelButtons[num-32]);}.defer;
			//"Channel change".postln;
		};
	}, msgType: \control, srcID: id);


}).play;

/*m = MIDIOut.newByName("nanoKONTROL2", "nanoKONTROL2 MIDI 1");
m.connect(0);*/

/*
(
MIDIClient.sources.do({|m, i|
	m.postln;
	m.name.postln;
	m.name.contains("nanoKONTROL2").if({// check this
		~midi = MIDIOut.newByName(m.device, m.name);
		"MIDIOut created".postln;
		~midi.connect(i-2); //-2 offset because the first two MIDIEndPoints don't count in jack's graph
		i .postln;
	});
});
)
MIDIClient.destinations*/