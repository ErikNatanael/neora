///////////// GUI for the Neora sampler \\\\\\\\\\\\\\\\\\

~isRec = false;
~isPlay = false;

 // make a simple SoundFileView
y = Window.screenBounds.height - 120;
w = Window.new("soundfile test", Rect(200, y, 740, 200)).alwaysOnTop_(true);
w.front;

// Setting up buttons
~recBut = Button.new(w, Rect(10, 100, 80, 30)).states_([["Rec", Color.black, Color.red(1)], ["Stop", Color.black, Color.red(0.5)]]);
~recBut.action = {
	if(~isRec == false, {
		~recSynth = Synth(\record_buffer, [\bufnum, ~localRecBuffer, \trigID, 1]);
		~isRec = true;
	}, {
		~recSynth.set(\stopTrig, 1);
		~isRec = false;
	});
};
b = Button.new(w, Rect(100, 100, 80, 30)).states_([["Play", Color.black, Color.green(1)], ["Stop", Color.black, Color.green(0.5)]]);
b.action = {
	if(~isPlay == false, {
		~playSynth = Synth(\play_buffer, [\bufnum, ~channel1.buffer, \start, ~channel1.start, \end, ~channel1.end]);
		~isPlay = true;
	}, {
		~playSynth.free;
		~isPlay = false;
	});
};

// Setting up the SoundFileView
~soundFileView = SoundFileView.new(w, Rect(20,20, 700, 60));
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
	~channel1.start = start;
	~channel1.end = end;
	// TODO: update the currently playing synth on the end position?
};


~setGUISoundFile = { | soundFile |
	{
	~soundFileView.soundfile = soundFile;            // set soundfile
	~soundFileView.read(0, soundFile.numFrames);     // read in the entire file.
	~soundFileView.refresh;                  // refresh to display the file.
	}.defer;
};

// Read the previous file on startup (can't be played yet)
f = SoundFile.new;
if(f.openRead(~recParams.saveFilePath ++ "A.wav")) {
	~setGUISoundFile.value(f);
};


