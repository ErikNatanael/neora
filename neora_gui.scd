///////////// GUI for the Neora sampler \\\\\\\\\\\\\\\\\\

~isRec = false;
Window.closeAll; // So that windows don't stack

// Short for instrument window
~instrWin = {var window, channelsView, channelButtons, waveformView, waveformMiniView, delayView,
	soundFileView, soundFileMiniView, bottomView,
	playBut, stopBut, waveBut, delBut, delSlider, topView, delMixSlider, effectsView, effectsMiniView, distBut, distSlider, distMixSlider,
	revBut, revView, revMixSlider, playbackView, playbackSliderXY, playbackSlider2, playbackBut, playLoopBut, playSeqBut, playJumpBut,
	playbackMiniView, playbackMiniSliderXY, combView, combMiniView, combXY, combLFODepth,
	combLFOFreq, combFreqGridBut, combBut, combResBut,
	resBut, resonantXY, resCombBut, resView,
	pitchView, pitchBut, pitchSelector, pitchMiniSelector,
	revdelXY, revmix, revdelView, revdelMiniView,
	loadSampleGUI,
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
		~instrWin.revdelView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.effectsView.visible_(false);
		~instrWin.combView.visible_(false);
		~instrWin.pitchView.visible_(false);
		~instrWin.resView.visible_(false);
		~globalParams.activeView = \wave;
		~changeJoystickView.value(\wave);
	});
	playbackBut = Button(topView, Rect(90, 0, 80, 30)).states_([["Playback", Color.black, Color.white]])
	.action_({ var playStyle;
		~instrWin.waveformView.visible_(false);
		~instrWin.revdelView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.playbackView.visible_(true);
		~instrWin.effectsView.visible_(false);
		~instrWin.combView.visible_(false);
		~instrWin.pitchView.visible_(false);
		~instrWin.resView.visible_(false);
		~globalParams.activeView = \playback;
		~changeJoystickView.value(\playback);
	});
	delBut = Button(topView, Rect(180, 0, 80, 30)).states_([["Delay", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.revdelView.visible_(true);
		~instrWin.envelopeView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.effectsView.visible_(false);
		~instrWin.combView.visible_(false);
		~instrWin.pitchView.visible_(false);
		~instrWin.resView.visible_(false);
		~globalParams.activeView = \delay;
		~changeJoystickView.value(\delay);
	});
	envBut = Button(topView, Rect(270, 0, 80, 30)).states_([["Envelope", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.revdelView.visible_(false);
		~instrWin.envelopeView.visible_(true);
		~instrWin.playbackView.visible_(false);
		~instrWin.effectsView.visible_(false);
		~instrWin.combView.visible_(false);
		~instrWin.pitchView.visible_(false);
		~instrWin.resView.visible_(false);
		~globalParams.activeView = \envelope;
		~changeJoystickView.value(\envelope);
	});
	distBut = Button(topView, Rect(360, 0, 80, 30)).states_([["Dist", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.revdelView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.effectsView.visible_(true);
		~instrWin.combView.visible_(false);
		~instrWin.pitchView.visible_(false);
		~instrWin.resView.visible_(false);
		~globalParams.activeView = \dist;
		~changeJoystickView.value(\dist);
	});
	combBut = Button(topView, Rect(540, 0, 80, 30)).states_([["Comb filter", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.revdelView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.effectsView.visible_(false);
		~instrWin.combView.visible_(true);
		~instrWin.pitchView.visible_(false);
		~instrWin.resView.visible_(false);
		~globalParams.activeView = \filter;
		~changeJoystickView.value(\filter);
	});
	pitchBut = Button(topView, Rect(630, 0, 80, 30)).states_([["Pitch", Color.black, Color.white]])
	.action_({
		~instrWin.waveformView.visible_(false);
		~instrWin.revdelView.visible_(false);
		~instrWin.playbackView.visible_(false);
		~instrWin.envelopeView.visible_(false);
		~instrWin.effectsView.visible_(false);
		~instrWin.combView.visible_(false);
		~instrWin.pitchView.visible_(true);
		~instrWin.resView.visible_(false);
		~globalParams.activeView = \pitch;
		~changeJoystickView.value(\pitch);
	});
	waveformView = View(window, Rect(160, 140, 740, 400));
	StaticText(waveformView, Rect(0, 0, 350, 40)).string_("Waveform").font_(Font("Astron Boy", 40));

	//TODO: Fix selection:
	//1. The whole soundFileView cannot be clicked
	//2. The Mini version doesn't reflect the big one
	// Setting up the SoundFileView
	soundFileView = SoundFileView.new(waveformView, Rect(0,40, 500, 100));

	soundFileView.setSelectionColor(0, Color.red);  // set...( index, value )
	soundFileView.timeCursorOn = true;          // a settable cursor
	soundFileView.timeCursorColor = Color.white;
	soundFileView.gridOn = false; // grid is currently not working, drawing a 1 second long segments instead of grid
	soundFileView.mouseUpAction = {
		~updateChannelSelection.value();
	};

	waveformMiniView = View(window, Rect(160, 80, 200, 50));
	soundFileMiniView = SoundFileView.new(waveformMiniView, Rect(0,0, 200, 50));

	soundFileMiniView.setSelectionColor(0, Color.red);  // set...( index, value )
	soundFileMiniView.timeCursorOn = true;          // a settable cursor
	soundFileMiniView.timeCursorColor = Color.white;
	soundFileMiniView.gridOn = false; // grid is currently not working, drawing a 1 second long segments instead of grid

	/*delayView = View(window, Rect(160, 140, 740, 400)).visible_(false);
	StaticText(delayView, Rect(0, 0, 350, 40)).string_("Delay").font_(Font("Astron Boy", 40));
	delSlider = Slider2D(delayView, Rect(0, 40, 350, 350))
	.action_({ var x, y;
		x = ~instrWin.delSlider.x;
		y = ~instrWin.delSlider.y;

		~channels[~currentChannel].delSynth.set(\decaytime, ~specs.delayDecay.map(x));
		~channels[~currentChannel].delSynth.set(\feedback, ~specs.delayFeedback.map(x));
		~channels[~currentChannel].delSynth.set(\delaytime, ~specs.delayTime.map(y));
	});
	delMixSlider = Slider(delayView, Rect(360, 40, 30, 350))
	.action_({ var v = ~instrWin.delMixSlider.value;
		~channels[~currentChannel].delSynth.set(\mix, ~specs.mix.map(v));
	});*/

	envelopeView = View(window, Rect(160, 140, 740, 400)).visible_(false);
	StaticText(envelopeView, Rect(0, 0, 350, 40)).string_("Envelope").font_(Font("Astron Boy", 40));
	envelopeEditor = ~createEnvelopeView.value(envelopeView, 0, 40, ~globalParams.envelopeEditorWidth, ~globalParams.envelopeEditorHeight);
	envelopeMiniView = View(window, Rect(700, 400, 140, 100)).visible_(true);
	envelopeMiniEditor = ~createEnvelopeView.value(envelopeMiniView, 0, 0, ~globalParams.envelopeEditorWidth/3, ~globalParams.envelopeEditorHeight/3);

	combView = View(window, Rect(160, 140, 740, 450)).visible_(false);
	StaticText(combView, Rect(0, 0, 350, 40)).string_("Comb filter").font_(Font("Astron Boy", 40));

	combXY = ~createCombXY.value(combView, 50, 40, ~globalParams.xySliderSize);
	combLFODepth = ~createCombLFODepthView.value(combView, 0, 40, 40, ~globalParams.xySliderSize);
	combLFOFreq = ~createCombLFOFreqView.value(combView, 50, ~globalParams.xySliderSize+50, ~globalParams.xySliderSize, 25);
	combResBut = Button(combView, Rect(400, 40, 80, 30))
	.states_([["Resonant filters", Color.black, Color.yellow], ["Resonant filters", Color.black, Color.red]])
	.action_( { | but |
		~instrWin.resView.visible_(true);
		~instrWin.combView.visible_(false);
		~globalParams.activeView = \resonant;
	});
	combMiniView = View(window, Rect(200, 570, 300, 300)).visible_(true);
	~createCombMini.value(combMiniView);

	revdelView = View(window, Rect(160, 140, 740, 450)).visible_(false);
	StaticText(revdelView, Rect(0, 0, 350, 40)).string_("Reverb/delay").font_(Font("Astron Boy", 40));

	revdelXY = ~createRevdelXY.value(revdelView, 50, 40, ~globalParams.xySliderSize);
	revmix = ~createRevMixView.value(revdelView, 0, 40, 40, ~globalParams.xySliderSize);
	revdelMiniView = View(window, Rect(500, 570, 300, 300)).visible_(true);
	~createRevdelMini.value(revdelMiniView);

	resView = View(window, Rect(160, 140, 740, 450)).visible_(false);
	StaticText(resView, Rect(0, 0, 350, 40)).string_("Resonant filters").font_(Font("Astron Boy", 40));

	resonantXY = ~createResonantXY.value(resView, 50, 40, ~globalParams.xySliderSize);

	resCombBut = Button(resView, Rect(400, 40, 80, 30))
	.states_([["Comb filters", Color.black, Color.yellow], ["Comb filters", Color.black, Color.red]])
	.action_( { | but |
		~instrWin.resView.visible_(false);
		~instrWin.combView.visible_(true);
		~globalParams.activeView = \filter;
	});

	pitchView = View(window, Rect(160, 140, 740, 450)).visible_(false);
	StaticText(pitchView, Rect(0, 0, 350, 40)).string_("Pitch").font_(Font("Astron Boy", 40));
	pitchSelector = ~createPitchView.value(pitchView, 0, 40, ~globalParams.xySliderSize, ~globalParams.xySliderSize);
	pitchMiniSelector = ~createPitchView.value(window, 20, 180, ~globalParams.xySliderSize/~globalParams.miniatureRatio,
		~globalParams.xySliderSize/~globalParams.miniatureRatio, false);



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
	playbackSliderXY = ~createPlaybackSliderXY.value(playbackView, 50, 40);

	playbackSlider2 = Slider(playbackView, Rect(0, 40, 30, 350))
	.action_({ var v = ~instrWin.playbackSlider2.value;
		//~channels[~currentChannel].grainSize = ~specs.grainSize.map(v);
		~channels[~currentChannel].grainSize = ~specs.grainSize.map(v);
		~channels[~currentChannel].density = ~specs.grainDensity.map(v);
		~channels[~currentChannel].updatePlaying.value();
		("grainSize: " ++ ~specs.grainSize.map(v).asString).postln;
		("density: " ++ ~specs.grainDensity.map(v).asString).postln;
	});
	playbackMiniView = View(window, Rect(20, 300, 200, 200)).visible_(true);
	playbackMiniSliderXY = ~createPlaybackMiniSliderXY.value(playbackMiniView, 0, 40);

	playLoopBut = Button(playbackView, Rect(400, 40, 80, 30))
	.states_([["Loop", Color.black, Color.yellow], ["Loop", Color.black, Color.red]])
	.action_( { | but |
		but.value = 1;
		~instrWin.playSeqBut.value = 0;
		~instrWin.playJumpBut.value = 0;
		// In case it was playing before, we don't want it to continue playing the old way when switching to the new one
		if(~channels[~currentChannel].playStyle != \loop, {~instrWin.stopBut.action.value(); });
		~channels[~currentChannel].playStyle = \loop;
	});
	playSeqBut = Button(playbackView, Rect(400, 80, 80, 30))
	.states_([["Sequencer", Color.black, Color.yellow], ["Sequencer", Color.black, Color.red]])
	.action_( { | but |
		but.value = 1;
		~instrWin.playLoopBut.value = 0;
		~instrWin.playJumpBut.value = 0;
		if(~channels[~currentChannel].playStyle != \seq, {~instrWin.stopBut.action.value(); });
		~channels[~currentChannel].playStyle = \seq;
	});
	playJumpBut = Button(playbackView, Rect(400, 120, 80, 30))
	.states_([["Jumping", Color.black, Color.yellow], ["Jumping", Color.black, Color.red]])
	.action_( { | but |
		but.value = 1;
		~instrWin.playLoopBut.value = 0;
		~instrWin.playSeqBut.value = 0;
		if(~channels[~currentChannel].playStyle != \jump, {~instrWin.stopBut.action.value(); });
		~channels[~currentChannel].playStyle = \jump;
	});
	//TODO: create small playback view. Small blobs instead of buttons?

	effectsView = View(window, Rect(160, 140, 740, 400)).visible_(false);
	StaticText(effectsView, Rect(0, 0, 350, 40)).string_("Effects").font_(Font("Astron Boy", 40));

	distMixSlider = ~createDistMixView.value(effectsView, 0, 40, 40, ~globalParams.xySliderSize);
	effectsMiniView = View(window, Rect(700, 180, 40, ~globalParams.xySliderSize/~globalParams.miniatureRatio)).visible_(true);
	~createEffectsMini.value(effectsMiniView);

	revView = View(window, Rect(160, 140, 740, 400)).visible_(false);
	StaticText(revView, Rect(0, 0, 350, 40)).string_("Reverb").font_(Font("Astron Boy", 40));

	revMixSlider = Slider(revView, Rect(360, 40, 30, 350))
	.action_({ var v = ~instrWin.revMixSlider.value;
		~channels[~currentChannel].revSynth.set(\amp2, ~specs.mix.map(v)); // Only sets wet level
	});
	bottomView = View(window, Rect(200, 700, 640, 90));
	playBut = Button.new(bottomView, Rect(0, 0, 80, 30)).states_([["Play", Color.black, Color.green(1)]])
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
	stopBut = Button.new(bottomView, Rect(90, 0, 80, 30)).states_([["Stop", Color.white, Color.black]])
	.action_({
		~channels[~currentChannel].stopChan.value();
	});

	loadSampleGUI = ~createLoadSampleView.value(window, 180, 100, 400, 400).visible_(false);
	(
		window: window,
		channelButtons: channelButtons,
		waveformView: waveformView,
		revdelView: revdelView,
		envelopeView: envelopeView,
		playbackView: playbackView,
		effectsView: effectsView,
		soundFileView: soundFileView,
		soundFileMiniView: soundFileMiniView,
		combView: combView,
		resView: resView,
		pitchView: pitchView,
		delSlider: delSlider,
		delMixSlider: delMixSlider,
		envelopeEditor: envelopeEditor,
		playbackSliderXY: playbackSliderXY,
		playbackSlider2: playbackSlider2,
		playLoopBut: playLoopBut,
		playSeqBut: playSeqBut,
		playJumpBut: playJumpBut,
		distMixSlider: distMixSlider,
		revMixSlider: revMixSlider,
		playBut: playBut,
		stopBut: stopBut,
		waveBut: waveBut,
		delBut: delBut,
		envBut: envBut,
		playbackBut: playbackBut,
		distBut: distBut,
		revBut: revBut,
		combBut: combBut,
		pitchBut: pitchBut,
		resCombBut: resCombBut,
		combResBut: combResBut,
		loadSampleGUI: loadSampleGUI
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
~changeChannel = { {
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
	{\loop} {~instrWin.playLoopBut.value = 1; ~instrWin.playSeqBut.value = 0; ~instrWin.playJumpBut.value = 0;}
	{\seq} {~instrWin.playLoopBut.value = 0; ~instrWin.playSeqBut.value = 1; ~instrWin.playJumpBut.value = 0;}
	{\jump} {~instrWin.playLoopBut.value = 0; ~instrWin.playSeqBut.value = 0; ~instrWin.playJumpBut.value = 1;};

}.defer;
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

{ ~instrWin.channelButtons[0].valueAction = 1; }.defer;

// Free everything on cmd + period
CmdPeriod.add({
	Window.closeAll;
});

/*
~instrWin.soundFileView.timeCursorPosition = 7000
~instrWin.soundFileView.setSelectionSize(0, -4000);
~instrWin.soundFileView.selectionSize(0);
*/