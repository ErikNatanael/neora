///////////// GUI for the Neora sampler \\\\\\\\\\\\\\\\\\

~isRec = false;
Window.closeAll; // So that windows don't stack

// Short for instrument window
~instrWin = {var window, channelsView, channelButtons, mainAreaView, soundFileView, bottomView, playBut;
	window = Window.new("Instrument Window", Rect(800, Window.screenBounds.height - 120, 840, 740))
	.alwaysOnTop_(true)
	.front;
	channelsView = View(window, Rect(0, 0, 740, 40));
	channelsView.decorator_(FlowLayout(channelsView.bounds, 7@7, 40@40));
	channelButtons = Array.fill(~globalParams.numberOfChannels, { |index|
		Button(channelsView, 30@30)
		.states_([[(index+1).asString, Color.black, Color.blue], [(index+1).asString, Color.black, Color.red]])
		.action_({
			// Set the old selected channel to not selected in the GUI
			if(~currentChannel != index) {~instrWin.channelButtons[~currentChannel].value = 0; };
			// Set a new active channel
			~currentChannel = index;
			//index.postln;
			// Call function for changing the SoundFileView and others
			~changeChannel.value();
		});
	});
	mainAreaView = View(window, Rect(0, 40, 740, 200));
	soundFileView = SoundFileView.new(mainAreaView, Rect(20,20, 700, 100));
	bottomView = View(window, Rect(0, 240, 740, 200));
	playBut = Button.new(bottomView, Rect(100, 100, 80, 30)).states_([["Play", Color.black, Color.green(1)]])
	.action_({
		~playSynth = Synth(\play_buffer,
			[\bufnum, ~channels[~currentChannel].buffer,
				\start, ~channels[~currentChannel].startPos,
				\end, ~channels[~currentChannel].endPos]);
	});
	(
		window: window,
		channelButtons: channelButtons,
		soundFileView: soundFileView,
		playBut: playBut
	)
}.value();

~inputWin = {var window, inputView, recBut, catchBut, cutView, soundFileView, sendChanView, sendChanButs;
	window = Window.new("soundfile test", Rect(50, Window.screenBounds.height - 120, 540, 500)).alwaysOnTop_(true).front;
	inputView = View(window, Rect(0, 40, 440, 200));
	// TODO: Add a custom UserView that visualises incoming sound
	recBut = Button.new(inputView, Rect(10, 100, 80, 30))
	.states_([["Rec", Color.black, Color.red(1)], ["Stop", Color.black, Color.red(0.5)]])
	.action = {
		if(~isRec == false, {
			~recSynth = Synth(\record_buffer, [\bufnum, ~localRecBuffer, \trigID, 1]);
			~isRec = true;
		}, {
			~recSynth.set(\stopTrig, 1);
			~isRec = false;
		});
	};
	catchBut = Button.new(inputView, Rect(100, 100, 80, 30))
	.states_([["Catch", Color.black, Color.cyan(0.6)]]);
	cutView = View(window, Rect(20, 250, 420, 200));
	soundFileView = SoundFileView.new(cutView, Rect(0, 0, 420, 100));
	sendChanView = View(cutView, Rect(0, 130, 440, 40));
	sendChanView.decorator_(FlowLayout(sendChanView.bounds, 7@7, 40@40));
	sendChanButs = Array.fill(~globalParams.numberOfChannels, { |index|
		Button(sendChanView, 30@30)
		.states_([[(index+1).asString, Color.black, Color.blue]])
		.action_({
			// Send selected data to that channel
		});
	});
	(
		window: window,
		recBut: recBut,
		catchBut: catchBut,
		soundFileView: soundFileView,
		sendChanButs: sendChanButs
	)
}.value();


~instrWin.channelButtons[~currentChannel].value = 1;

~inputWin.recBut.action = {
	if(~isRec == false, {
		~recSynth = Synth(\record_buffer, [\bufnum, ~localRecBuffer, \trigID, 1]);
		~isRec = true;
	}, {
		~recSynth.set(\stopTrig, 1);
		~isRec = false;
	});
};


// Setting up the SoundFileView

~instrWin.soundFileView.timeCursorOn = true;          // a settable cursor
~instrWin.soundFileView.timeCursorColor = Color.red;
~instrWin.soundFileView.setSelectionColor(0, Color.red);  // set...( index, value )
~instrWin.soundFileView.gridOn = false; // grid is currently not working, drawing a 1 second long segments instead of
//~soundFileView.gridResolution = 2;     // or set resolution in seconds


       // mouseUpAction
~instrWin.soundFileView.mouseUpAction = { var start, end;
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
		~instrWin.soundFileView.drawsWaveForm = true;
		~instrWin.soundFileView.timeCursorOn = true;
		~setGUISoundFile.value(~channels[~currentChannel].soundFile);
		~instrWin.soundFileView.setSelection(0, [start, end-start]);
	} {
		// Hide the waveform when nothing is recorded on that channel
		~instrWin.soundFileView.drawsWaveForm = false;
		~instrWin.soundFileView.setSelection(0, [0, 0]);
		~instrWin.soundFileView.timeCursorOn = false;
	};

};

~masterChannelChanged = {
	var start = ~masterChannel.startPos,
	end = ~masterChannel.endPos;
	if(~masterChannel.soundFile != nil) {
		~soundFileView.drawsWaveForm = true;
		~soundFileView.timeCursorOn = true;
		~setGUISoundFile.value(~masterChannel.soundFile);
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
		~instrWin.soundFileView.soundfile = soundFile;            // set soundfile
		if(soundFile != nil) {
			~instrWin.soundFileView.read(0, soundFile.numFrames); // read in the entire file.
		};
		~instrWin.soundFileView.refresh;                  // refresh to display the file.
	}.defer;
};

// Read the previous file on startup (can't be played yet)
f = SoundFile.new;
if(f.openRead(~recParams.saveFilePath ++ "0.wav")) {
	~setGUISoundFile.value(f);
};