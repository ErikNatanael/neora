///////////// GUI for the Neora sampler \\\\\\\\\\\\\\\\\\

~isRec = false;
Window.closeAll; // So that windows don't stack

// Short for instrument window
~instrWin = {var window, channelsView, channelButtons, waveformView, waveformMiniView, delayView,
	soundFileView, soundFileMiniView, bottomView,
	playBut, stopBut, waveBut, delBut, delSlider, topView, delMixSlider, distView, distBut, distSlider, distMixSlider,
	revBut, revView, revMixSlider, playbackView, playbackSliderXY, playbackSlider2, playbackBut, playLoopBut, playSeqBut,
	envBut, envelopeView, envelopeEditor, envelopeMiniView, envelopeMiniEditor;
	window = Window.new("Neora Instrument Window", Rect(700, Window.screenBounds.height - 120, 840, 740))
	.alwaysOnTop_(true)
	.front;
	channelsView = View(window, Rect(160, 0, 640, 40));
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
	topView = View(window, Rect(160, 40, 640, 100));
	waveBut = Button(topView, Rect(0, 0, 80, 30)).states_([["Waveform", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(true);
		~instrWin.delayView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.distView.visible_(false);
		~instrWin.revView.visible_(false);
		~globalParams.activeView = \wave;
		~changeJoystickView.value(\wave);
	});
	playbackBut = Button(topView, Rect(90, 0, 80, 30)).states_([["Playback", Color.black, Color.white]])
	.action_({ var playStyle;
		~instrWin.waveformView.visible_(false);
		~instrWin.delayView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.playbackView.visible_(true);
		~instrWin.distView.visible_(false);
		~instrWin.revView.visible_(false);
		~globalParams.activeView = \playback;
		~changeJoystickView.value(\playback);
	});
	delBut = Button(topView, Rect(180, 0, 80, 30)).states_([["Delay", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.delayView.visible_(true);
		~instrWin.envelopeView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.distView.visible_(false);
		~instrWin.revView.visible_(false);
		~globalParams.activeView = \delay;
		~changeJoystickView.value(\delay);
	});
	envBut = Button(topView, Rect(270, 0, 80, 30)).states_([["Envelope", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.delayView.visible_(false);
		~instrWin.envelopeView.visible_(true);
		~instrWin.playbackView.visible_(false);
		~instrWin.distView.visible_(false);
		~instrWin.revView.visible_(false);
		~globalParams.activeView = \envelope;
		~changeJoystickView.value(\envelope);
	});
	distBut = Button(topView, Rect(360, 0, 80, 30)).states_([["Dist", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.delayView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.distView.visible_(true);
		~instrWin.revView.visible_(false);
		~globalParams.activeView = \dist;
		~changeJoystickView.value(\dist);
	});
	revBut = Button(topView, Rect(450, 0, 80, 30)).states_([["Reverb", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.delayView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.distView.visible_(false);
		~instrWin.revView.visible_(true);
		~globalParams.activeView = \reverb;
		~changeJoystickView.value(\reverb);
	});
	waveformView = View(window, Rect(160, 140, 740, 400));
	StaticText(waveformView, Rect(60, 0, 350, 40)).string_("Waveform").font_(Font("Astron Boy", 40));

	//TODO: Fix selection:
	//1. The whole soundFileView cannot be clicked
	//2. The Mini version doesn't reflect the big one
	// Setting up the SoundFileView
	soundFileView = SoundFileView.new(waveformView, Rect(20,40, 500, 100));

	soundFileView.setSelectionColor(0, Color.red);  // set...( index, value )
	soundFileView.timeCursorOn = true;          // a settable cursor
	soundFileView.timeCursorColor = Color.white;
	soundFileView.gridOn = false; // grid is currently not working, drawing a 1 second long segments instead of grid
	soundFileView.mouseUpAction = {
		~updateChannelSelection.value();
	};

	waveformMiniView = View(window, Rect(160, 80, 200, 400));
	soundFileMiniView = SoundFileView.new(waveformMiniView, Rect(0,0, 200, 50));

	soundFileMiniView.setSelectionColor(0, Color.red);  // set...( index, value )
	soundFileMiniView.timeCursorOn = true;          // a settable cursor
	soundFileMiniView.timeCursorColor = Color.white;
	soundFileMiniView.gridOn = false; // grid is currently not working, drawing a 1 second long segments instead of grid

	delayView = View(window, Rect(160, 140, 740, 400)).visible_(false);
	StaticText(delayView, Rect(0, 0, 350, 40)).string_("Delay").font_(Font("Astron Boy", 40));
	delSlider = Slider2D(delayView, Rect(0, 40, 350, 350))
	.action_({ var x, y;
		x = ~instrWin.delSlider.x;
		y = ~instrWin.delSlider.y;

		~channels[~currentChannel].delSynth.set(\decaytime, ~specs.delayDecay.map(x));
		~channels[~currentChannel].delSynth.set(\delaytime, ~specs.delayTime.map(y));
	});
	delMixSlider = Slider(delayView, Rect(360, 40, 30, 350))
	.action_({ var v = ~instrWin.delMixSlider.value;
		~channels[~currentChannel].delSynth.set(\mix, ~specs.mix.map(v));
	});

	envelopeView = View(window, Rect(160, 180, 740, 400)).visible_(false);
	envelopeEditor = ~createEnvelopeView.value(envelopeView, ~globalParams.envelopeEditorWidth, ~globalParams.envelopeEditorHeight);
	envelopeMiniView = View(window, Rect(700, 400, 140, 100)).visible_(true);
	envelopeMiniEditor = ~createEnvelopeView.value(envelopeMiniView, ~globalParams.envelopeEditorWidth/3, ~globalParams.envelopeEditorHeight/3);

	playbackView = View(window, Rect(160, 140, 740, 400)).visible_(false);
	StaticText(playbackView, Rect(0, 0, 350, 40)).string_("Playback").font_(Font("Astron Boy", 40));
	/*playbackSliderXY = Slider2D(playbackView, Rect(60, 40, 350, 350))
	.action_({ var x, y;
		x = ~instrWin.playbackSliderXY.x;
		y = ~instrWin.playbackSliderXY.y;
		~channels[~currentChannel].playRate = ~specs.grainRate.map(x);
		~channels[~currentChannel].density = ~specs.grainDensity.map(y);
		~channels[~currentChannel].updatePlaying.value();
	});*/
	playbackSliderXY = ~createPlaybackSliderXY.value(playbackView, 0, 40, ~globalParams.xySliderSize, ~globalParams.xySliderSize);
	playbackSlider2 = Slider(playbackView, Rect(360, 40, 30, 350))
	.action_({ var v = ~instrWin.playbackSlider2.value;
		//~channels[~currentChannel].grainSize = ~specs.grainSize.map(v);
		~channels[~currentChannel].grainSize = ~specs.grainSize.map(v);
		~channels[~currentChannel].density = ~specs.grainDensity.map(v);
		~channels[~currentChannel].updatePlaying.value();
		("grainSize: " ++ ~specs.grainSize.map(v).asString).postln;
		("density: " ++ ~specs.grainDensity.map(v).asString).postln;
	});
	playLoopBut = Button(playbackView, Rect(460, 40, 80, 30))
	.states_([["Loop", Color.black, Color.yellow], ["Loop", Color.black, Color.red]])
	.action_( { | but |
		but.value = 1;
		~instrWin.playSeqBut.value = 0;
		// In case it was playing before, we don't want it to continue playing the old way when switching to the new one
		if(~channels[~currentChannel].playStyle != \loop, {~instrWin.stopBut.action.value(); });
		~channels[~currentChannel].playStyle = \loop;
	});
	playSeqBut = Button(playbackView, Rect(460, 80, 80, 30))
	.states_([["Sequencer", Color.black, Color.yellow], ["Sequencer", Color.black, Color.red]])
	.action_( { | but |
		but.value = 1;
		~instrWin.playLoopBut.value = 0;
		if(~channels[~currentChannel].playStyle != \seq, {~instrWin.stopBut.action.value(); });
		~channels[~currentChannel].playStyle = \seq;
	});
	//TODO: create small playback view. Small blobs instead of buttons?

	distView = View(window, Rect(0, 140, 740, 400)).visible_(false);
	StaticText(distView, Rect(60, 0, 350, 40)).string_("Distortion").font_(Font("Astron Boy", 40));

	distMixSlider = Slider(distView, Rect(420, 40, 30, 350))
	.action_({ var v = ~instrWin.distMixSlider.value;
		~channels[~currentChannel].distSynth.set(\mix, ~specs.mix.map(v));
	});
	revView = View(window, Rect(0, 140, 740, 400)).visible_(false);
	StaticText(revView, Rect(60, 0, 350, 40)).string_("Reverb").font_(Font("Astron Boy", 40));

	revMixSlider = Slider(revView, Rect(420, 40, 30, 350))
	.action_({ var v = ~instrWin.revMixSlider.value;
		~channels[~currentChannel].revSynth.set(\amp2, ~specs.mix.map(v)); // Only sets wet level
	});
	bottomView = View(window, Rect(0, 540, 740, 200));
	playBut = Button.new(bottomView, Rect(100, 0, 80, 30)).states_([["Play", Color.black, Color.green(1)]])
	.action_({
		/*
		~playSynth = Synth(\play_buffer,
		[\bufnum, ~channels[~currentChannel].buffer,
		\start, ~channels[~currentChannel].startPos,
		\end, ~channels[~currentChannel].endPos]);*/
		/*~channels[~currentChannel].streamer.stop();
		~channels[~currentChannel].setLoopDur.value();
		~channels[~currentChannel].updatePbind.value();
		~channels[~currentChannel].streamer = ~channels[~currentChannel].pbind.play(~globalParams.clock, quant: ~channels[~currentChannel].dur);
		*/
		~channels[~currentChannel].updatePlaying.value();
		~channels[~currentChannel].playChan.value();
	});
	stopBut = Button.new(bottomView, Rect(190, 0, 80, 30)).states_([["Stop", Color.white, Color.black]])
	.action_({
		~channels[~currentChannel].stopChan.value();
	});
	(
		window: window,
		channelButtons: channelButtons,
		waveformView: waveformView,
		delayView: delayView,
		envelopeView: envelopeView,
		playbackView: playbackView,
		distView: distView,
		revView: revView,
		soundFileView: soundFileView,
		soundFileMiniView: soundFileMiniView,
		delSlider: delSlider,
		delMixSlider: delMixSlider,
		envelopeEditor: envelopeEditor,
		playbackSliderXY: playbackSliderXY,
		playbackSlider2: playbackSlider2,
		playLoopBut: playLoopBut,
		playSeqBut: playSeqBut,
		distMixSlider: distMixSlider,
		revMixSlider: revMixSlider,
		playBut: playBut,
		stopBut: stopBut,
		waveBut: waveBut,
		delBut: delBut,
		envBut: envBut,
		playbackBut: playbackBut,
		distBut: distBut,
		revBut: revBut
	)
}.value();

~inputWin = {var window, inputView, recBut, catchBut, cutView, soundFileView, sendChanView, sendChanButs, sourceSelector;
	window = Window.new("Neora Input Window", Rect(0, Window.screenBounds.height - 120, 500, 500)).alwaysOnTop_(true).front;
	inputView = View(window, Rect(0, 40, 440, 200));
	// TODO: Add a custom UserView that visualises incoming sound
	recBut = Button.new(inputView, Rect(10, 100, 80, 30))
	.states_([["Rec", Color.black, Color.red(1)], ["Stop", Color.black, Color.red(0.5)]])
	.action = { | but |
		if(~isRec == false, {
			switch(~globalParams.recordingSource)
			{\input} {
				~recSynth = Synth(\record_buffer, [\bufnum, ~localRecBuffer, \trigID, 1]);
			}
			{\output} {
				~recSynth = Synth(\record_output,
					[\inBus, ~globalParams.masterBus, \bufnum, ~localRecBuffer, \trigID, 1],
					target: ~globalParams.synthGroup, addAction: \addAfter
				);
				"Rec synth created".postln;
			};
			~isRec = true;
			~inputWin.recBut.value = 1;
		}, {
			~recSynth.set(\stopTrig, 1);
			~isRec = false;
			~inputWin.recBut.value = 0;
		});
	};
	catchBut = Button.new(inputView, Rect(100, 100, 80, 30))
	.states_([["Catch", Color.black, Color.cyan(0.6)]]);
	sourceSelector = PopUpMenu(inputView, Rect(200, 100, 100, 20))
	.items_(["Input", "Output"])
	.action_( { | menu |
		switch(menu.value)
		{0} {~globalParams.recordingSource = \input; }
		{1} {~globalParams.recordingSource = \output; };
	});
	cutView = View(window, Rect(20, 250, 420, 200));
	// Setting up the input SoundFileView
	soundFileView = SoundFileView.new(cutView, Rect(0, 0, 420, 100));
	soundFileView.gridOn_(false).timeCursorOn_(true).timeCursorColor_(Color.white);
	// mouseUpAction
	soundFileView.mouseUpAction = {
		~updateInputSelection.value();
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


// Create view functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\

~createEnvelopeView = { | parent, width, height |
	UserView(parent, Rect(0, 0, width, height))
	.background_(Color.green(0.2))
	.frameRate_(20)
	.animate_(true)
	.clearOnRefresh_(true)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var width = ~globalParams.envelopeEditorWidth,
		height = ~globalParams.envelopeEditorHeight,
		nodes = List[],
		ovalSize = 15,
		selection = ~channels[~currentChannel].selLength/~channels[~currentChannel].buffer.sampleRate,
		attackPos = width * (~channels[~currentChannel].attackTime/selection),
		decayPos = width * (~channels[~currentChannel].decayTime/selection),
		sustainPos = width * (~channels[~currentChannel].sustainTime/selection),
		releasePos = width * (~channels[~currentChannel].releaseTime/selection);

		nodes = nodes.add(
			attackPos @
			(height - (height * ~channels[~currentChannel].attackLevel))
		);
		nodes = nodes.add(
			attackPos + decayPos @
			(height - (height * ~channels[~currentChannel].decayLevel)) // Y = 0 is in the upper corner
		);
		nodes = nodes.add(
			attackPos + decayPos + sustainPos @
			(height - (height * ~channels[~currentChannel].sustainLevel)) // Y = 0 is in the upper corner
		);
		nodes = nodes.add(
			attackPos + decayPos + sustainPos + releasePos @
			height // Y = 0 is in the upper corner
		);

		// Draw lines between nodes
		Pen.color = Color.green(0.8);
		Pen.moveTo(0@height);
		nodes.do {|node| Pen.lineTo(node) };
		Pen.stroke;

		// Draw nodes
		Pen.color = Color.cyan;
		nodes.do { |point| Pen.fillOval(Rect(point.x - (ovalSize/2), point.y - (ovalSize/2), ovalSize, ovalSize)); };

	});
};

~createPlaybackSliderXY = { | parent, x, y, width, height |
	UserView(parent, Rect(x, y, width, height))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var size = ~globalParams.xySliderSize,
		numRows = ~globalParams.rateRatios.size,
		crosshairSize = size/20,
		realX = ~joyX*size,
		realY = ~joyY*size;

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, size, size));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw rows
		numRows.do {|i| Pen.addRect(Rect(0, size/numRows*i, size, size/numRows*(i+1))) };
		Pen.stroke;
		// Draw boxes
		numRows.do { |i|
			var numColumns = ~globalParams.rateRatios[i].size;
			numColumns.do { |j|
				var rect = Rect(size/numColumns*j, size/numRows*i, size/numColumns, size/numRows);
				Pen.addRect(rect);
				Pen.stringAtPoint(~globalParams.rateRatios[i][j].round(0.01).asString,
					(size/numColumns*j + (size/numColumns/4)) @ (size/numRows*i + (size/numRows/2)));
			};
		};
		Pen.stroke;

		// Draw X/Y
		Pen.color = Color.cyan;
		Pen.line((realX - (crosshairSize/2))@realY, (realX + (crosshairSize/2))@realY);
		Pen.line(realX@(realY - (crosshairSize/2)), realX@(realY + (crosshairSize/2)));
		Pen.addArc(realX@realY, crosshairSize/2, pi, 2*pi);
		Pen.addArc(realX@realY, crosshairSize/4, pi, 2*pi);
		Pen.stroke;
	})
	.action_({ var x, y, row, column;
		x = ~joyX;
		y = ~joyY;
		~changePlaybackRate.value(x, y);
	})
	.mouseDownAction_( { | view, x, y |
		var relX = x/~globalParams.xySliderSize,
		relY = y/~globalParams.xySliderSize;
		~changePlaybackRate.value(relX, relY);
		~joyX = relX;
		~joyY = relY;
	});
};


//Update selection
~updateChannelSelection = {
	var start, end;
	{
		// Set the start and end point for the sample
		start = ~instrWin.soundFileView.selections[0][0];
		end = ~instrWin.soundFileView.selections[0][0] + ~instrWin.soundFileView.selections[0][1];
		~channels[~currentChannel].startPos = start;
		~channels[~currentChannel].endPos = end;
		~channels[~currentChannel].selLength = ~instrWin.soundFileView.selections[0][1];
		// TODO: update the currently playing synth on the end position?
		//~instrWin.playBut.action.value();
		~channels[~currentChannel].updatePosSpec.value();
		~channels[~currentChannel].updatePlaying.value();
	}.defer;
};

~updateInputSelection = {
	var start, end;
	{
		// Set the start and end point for the sample
		start = ~inputWin.soundFileView.selections[0][0];
		end = ~inputWin.soundFileView.selections[0][0] + ~inputWin.soundFileView.selections[0][1];
		~masterChannel.startPos = start;
		~masterChannel.endPos = end;
	}.defer;
};


// Called when the channel is changed or a new sound is recorded onto that channel
~changeChannel = {
	var playStyle,
	start = ~channels[~currentChannel].startPos,
	end = ~channels[~currentChannel].endPos;
	if(~channels[~currentChannel].soundFile != nil) {
		//Big view
		~instrWin.soundFileView.drawsWaveForm = true;
		~instrWin.soundFileView.timeCursorOn = true;
		~setGUISoundFile.value(~channels[~currentChannel].soundFile);
		~instrWin.soundFileView.setSelection(0, [start, end-start]);
		~instrWin.soundFileView.timeCursorPosition = start;
		//Mini view
		~instrWin.soundFileMiniView.drawsWaveForm = true;
		~instrWin.soundFileMiniView.timeCursorOn = true;
		~setGUISoundFile.value(~channels[~currentChannel].soundFile);
		~instrWin.soundFileMiniView.setSelection(0, [start, end-start]);
		~instrWin.soundFileMiniView.timeCursorPosition = start;
	} {
		// Hide the waveform when nothing is recorded on that channel
		//Big view
		~instrWin.soundFileView.drawsWaveForm = false;
		~instrWin.soundFileView.setSelection(0, [0, 0]);
		~instrWin.soundFileView.timeCursorOn = false;
		//Mini view
		~instrWin.soundFileMiniView.drawsWaveForm = false;
		~instrWin.soundFileMiniView.setSelection(0, [0, 0]);
		~instrWin.soundFileMiniView.timeCursorOn = false;
	};

	// Init play style buttons
	playStyle = ~channels[~currentChannel].playStyle;
	switch(playStyle)
	{\loop} {~instrWin.playLoopBut.value = 1; ~instrWin.playSeqBut.value = 0;}
	{\seq} {~instrWin.playLoopBut.value = 0; ~instrWin.playSeqBut.value = 1;};


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

~changePlaybackRate = { | x, y |
	var row, column;
	// Find out inside which box we are
	row = (y * ~globalParams.rateRatios.size).floor;
	// If y = 1 row becomes bigger than the array
	if(row > (~globalParams.rateRatios.size-1), {row = ~globalParams.rateRatios.size-1 } );
	column = (x * ~globalParams.rateRatios[row].size).floor;
	if(column > (~globalParams.rateRatios[row].size-1), {column = ~globalParams.rateRatios[row].size-1} );
	~channels[~currentChannel].playRate = ~globalParams.rateRatios[row][column];
	~channels[~currentChannel].updatePlaying.value();
};

~setGUISoundFile = { | soundFile |
	{
		~instrWin.soundFileView.soundfile = soundFile;            // set soundfile
		~instrWin.soundFileMiniView.soundfile = soundFile;            // set soundfile
		if(soundFile != nil) {
			~instrWin.soundFileView.read(0, soundFile.numFrames); // read in the entire file.
			~instrWin.soundFileMiniView.read(0, soundFile.numFrames); // read in the entire file.

		};
		~instrWin.soundFileView.refresh;                  // refresh to display the file.
		~instrWin.soundFileMiniView.refresh;                  // refresh to display the file.

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
			~channels[index].selLength = ~channels[index].buffer.numFrames;
		};
	};
	~currentChannel = 0;
	{
		~instrWin.channelButtons[0].valueAction = 1;
	}.defer;
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
/*
~instrWin.soundFileView.timeCursorPosition = 7000
~instrWin.soundFileView.setSelectionSize(0, -4000);
~instrWin.soundFileView.selectionSize(0);
*/