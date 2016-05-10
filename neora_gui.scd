///////////// GUI for the Neora sampler \\\\\\\\\\\\\\\\\\

~isRec = false;
Window.closeAll; // So that windows don't stack
 // make a simple SoundFileView
y = Window.screenBounds.height - 120;
w = Window.new("soundfile test", Rect(200, y, 740, 740)).alwaysOnTop_(true);
w.front;

// Setting up buttons
~channelsView = View(w, Rect(0, 0, 740, 40));
~channelsView.decorator_(FlowLayout(~channelsView.bounds, 7@7, 40@40));

~channelButtons = Array.fill(~globalParams.numberOfChannels, { |index|

	Button(~channelsView, 30@30)
	.states_([[(index+1).asString, Color.black, Color.blue], [(index+1).asString, Color.black, Color.red]])
	.action_({
		// Set the old selected channel to not selected in the GUI
		if(~currentChannel != index) {~channelButtons[~currentChannel].value = 0; };
		// Set a new active channel
		~currentChannel = index;
		//index.postln;
		// Call function for changing the SoundFileView and others
		~changeChannel.value();
	});

});
~channelButtons[~currentChannel].value = 1;
~mainAreaView = View(w, Rect(0, 40, 740, 200));

~bottomView = View(w, Rect(0, 240, 740, 200));

~recBut = Button.new(~bottomView, Rect(10, 100, 80, 30)).states_([["Rec", Color.black, Color.red(1)], ["Stop", Color.black, Color.red(0.5)]]);
~recBut.action = {
	if(~isRec == false, {
		~recSynth = Synth(\record_buffer, [\bufnum, ~localRecBuffer, \trigID, 1]);
		~isRec = true;
	}, {
		~recSynth.set(\stopTrig, 1);
		~isRec = false;
	});
};
~playBut = Button.new(~bottomView, Rect(100, 100, 80, 30)).states_([["Play", Color.black, Color.green(1)]])
.action_({
	~playSynth = Synth(\play_buffer,
		[\bufnum, ~channels[~currentChannel].buffer,
			\start, ~channels[~currentChannel].startPos,
			\end, ~channels[~currentChannel].endPos]);
});

// Setting up the SoundFileView
~soundFileView = SoundFileView.new(~mainAreaView, Rect(20,20, 700, 100));
~soundFileView.timeCursorOn = true;          // a settable cursor
~soundFileView.timeCursorColor = Color.red;
~soundFileView.setSelectionColor(0, Color.red);  // set...( index, value )
~soundFileView.gridOn = false; // grid is currently not working, drawing a 1 second long segments instead of
//~soundFileView.gridResolution = 2;     // or set resolution in seconds


       // mouseUpAction
~soundFileView.mouseUpAction = { var start, end;
    ("mouseUp, current selection is now:"
        + ~soundFileView.selections[~soundFileView.currentSelection]).postln;
	// Set the start and end point for the sample
	start = ~soundFileView.selections[0][0];
	end = ~soundFileView.selections[0][0] + ~soundFileView.selections[0][1];
	~channels[~currentChannel].startPos = start;
	~channels[~currentChannel].endPos = end;
	// TODO: update the currently playing synth on the end position?
};

// Called when the channel is changed or a new sound is recorded onto that channel
~changeChannel = {
	var start = ~channels[~currentChannel].startPos,
	end = ~channels[~currentChannel].endPos;
	if(~channels[~currentChannel].soundFile != nil) {
		~soundFileView.drawsWaveForm = true;
		~soundFileView.timeCursorOn = true;
		~setGUISoundFile.value(~channels[~currentChannel].soundFile);
		~soundFileView.setSelection(0, [start, end-start]);
	} {
		// Hide the waveform when nothing is recorded on that channel
		~soundFileView.drawsWaveForm = false;
		~soundFileView.setSelection(0, [0, 0]);
		~soundFileView.timeCursorOn = false;
	};

};


~setGUISoundFile = { | soundFile |
	{
		~soundFileView.soundfile = soundFile;            // set soundfile
		if(soundFile != nil) {
			~soundFileView.read(0, soundFile.numFrames); // read in the entire file.
		};
		~soundFileView.refresh;                  // refresh to display the file.
	}.defer;
};

// Read the previous file on startup (can't be played yet)
f = SoundFile.new;
if(f.openRead(~recParams.saveFilePath ++ "0.wav")) {
	~setGUISoundFile.value(f);
};