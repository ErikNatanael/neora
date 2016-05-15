///////////// GUI for the Neora sampler \\\\\\\\\\\\\\\\\\

~isRec = false;
Window.closeAll; // So that windows don't stack

// Short for instrument window
~instrWin = {var window, channelsView, channelButtons, mainAreaView, soundFileView, bottomView, playBut, stopBut;
	window = Window.new("Instrument Window", Rect(800, Window.screenBounds.height - 120, 740, 740))
	.alwaysOnTop_(true)
	.front;
	channelsView = View(window, Rect(20, 0, 740, 40));
	channelsView.decorator_(FlowLayout(channelsView.bounds, 7@7, 40@40));
	channelButtons = Array.fill(~globalParams.numberOfChannels, { |index|
		Button(channelsView, 30@30)
		.states_([[(index+1).asString, Color.black, Color.blue], [(index+1).asString, Color.black, Color.red]])
		.action_({ | butt | // TODO: Change to mouseDownAction?
			// Set the old selected channel to not selected in the GUI
			if(~currentChannel != index) {~instrWin.channelButtons[~currentChannel].value = 0; };
			butt.value = 1;
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
		/*
		~playSynth = Synth(\play_buffer,
		[\bufnum, ~channels[~currentChannel].buffer,
		\start, ~channels[~currentChannel].startPos,
		\end, ~channels[~currentChannel].endPos]);*/
		~channels[~currentChannel].streamer.stop();
		~channels[~currentChannel].setLoopDur.value();
		~channels[~currentChannel].updatePbind.value();
		~channels[~currentChannel].streamer = ~channels[~currentChannel].pbind.play(~globalParams.clock, quant: 1);
	});
	stopBut = Button.new(bottomView, Rect(150, 100, 80, 30)).states_([["Stop", Color.white, Color.black]])
	.action_({
		~channels[~currentChannel].streamer.stop();
	});
	(
		window: window,
		channelButtons: channelButtons,
		soundFileView: soundFileView,
		playBut: playBut,
		stopBut: stopBut
	)
}.value();

~inputWin = {var window, inputView, recBut, catchBut, cutView, soundFileView, sendChanView, sendChanButs;
	window = Window.new("soundfile test", Rect(0, Window.screenBounds.height - 120, 500, 500)).alwaysOnTop_(true).front;
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
	// Setting up the input SoundFileView
	soundFileView = SoundFileView.new(cutView, Rect(0, 0, 420, 100));
	soundFileView.gridOn_(false).timeCursorOn_(true).timeCursorColor_(Color.red);
	soundFileView.mouseUpAction = { var start, end;
		("mouseUp, current selection is now:"
			+ ~inputWin.soundFileView.selections[~inputWin.soundFileView.currentSelection]).postln;
		// Set the start and end point for the sample
		start = ~inputWin.soundFileView.selections[0][0];
		end = ~inputWin.soundFileView.selections[0][0] + ~inputWin.soundFileView.selections[0][1];
		~masterChannel.startPos = start;
		~masterChannel.endPos = end;
		// TODO: update the currently playing synth on the end position?
	};
	StaticText(cutView, Rect(0, 105, 420, 30)).string_("Send to channel");
	sendChanView = View(cutView, Rect(0, 130, 440, 40));
	sendChanView.decorator_(FlowLayout(sendChanView.bounds, 7@7, 15@2));
	sendChanButs = Array.fill(~globalParams.numberOfChannels, { |index|
		Button(sendChanView, 30@30)
		.states_([[(index+1).asString, Color.black, Color.blue]])
		.action_({
			var newBuf, lengthFrames;
			// Send selected data to that channel
			lengthFrames = ~masterChannel.endPos - ~masterChannel.startPos;
			newBuf = Buffer.alloc(s, lengthFrames);
			Task({
				// Copying from master channel to new buffer
				~masterChannel.buffer.copyData(newBuf, srcStartAt: ~masterChannel.startPos, numSamples: lengthFrames);
				~channels[index].buffer = newBuf;
				// Select the whole file
				~channels[index].startPos = 0;
				~channels[index].endPos = lengthFrames;
				~channels[index].buffer.write(~recParams.saveFilePath ++ index.asString ++ ".wav", "WAV", "int16", numFrames: -1);
				s.sync();
				~channels[index].soundFile = SoundFile.new;
				~channels[index].soundFile.openRead(~recParams.saveFilePath ++ index.asString ++ ".wav");
				~currentChannel = index;
				{~channelChanged.value()}.defer;
				// Set channel buttons in instrument window
				{~instrWin.channelButtons.do { | obj | obj.value = 0}; // Set all channels to off
					~instrWin.channelButtons[index].valueAction = 1; }.defer;
			}).play;

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
        + ~instrWin.soundFileView.selections[~instrWin.soundFileView.currentSelection]).postln;
	// Set the start and end point for the sample
	start = ~instrWin.soundFileView.selections[0][0];
	end = ~instrWin.soundFileView.selections[0][0] + ~instrWin.soundFileView.selections[0][1];
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
		~inputWin.soundFileView.drawsWaveForm = true;
		~inputWin.soundFileView.timeCursorOn = true;
		~inputWin.soundFileView.soundfile = ~masterChannel.soundFile;            // set soundfile
		~inputWin.soundFileView.read(0, ~masterChannel.soundFile.numFrames); // read in the entire file.
		~inputWin.soundFileView.refresh;                  // refresh to display the file.
		// Select the whole file per default?
		~inputWin.soundFileView.setSelection(0, [start, end-start]);
	} {
		// Hide the waveform when nothing is recorded on that channel
		~inputWin.soundFileView.drawsWaveForm = false;
		~inputWin.soundFileView.setSelection(0, [0, 0]);
		~inputWin.soundFileView.timeCursorOn = false;
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
		};
	};
	~currentChannel = 0;
	{
		~instrWin.channelButtons[0].valueAction = 1;
	}.defer;
}).play;
