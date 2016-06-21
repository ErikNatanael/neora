///////////////////// HID Joystick code for the Neora Sampler instrument \\\\\\\\\\\\\\\\\\\\\\\
// Remember to set hidraw permissions first on Linux. Instructions in HID permissions help file

/* For debugging purposes:
HID.postAvailable;
HID.debug = true;
HID.debug = false;

~joystick.postElements
~joystick.postInputElements
~joystick.postOutputElements
~joystick.postUsages
~joystick.close;


s.boot; // boot the server*/

HID.findAvailable; // Run to initialise HID before opening a device

// This ensures that there are no trailing actions associated with the joystick controls when you run the file multiple times
if (~joystick != nil)  {
	~joystick.close();
};
~moveWaveCursor.stop();
~changeWaveSelection.stop();

~joystick = HID.open( 1103, 45320 ); // Should be cross platform compatible for this joystick Thrustmaster, T.Flight Hotas X

~trigg = false; // True if the trigger button is held down
~cursorChange = 0;
~throttleXChange = 0;
~viewsOrder = [\wave, \playback, \delay, \envelope, \dist, \reverb];
~joyX = 0.5;
~joyY = 0.5;
~joyZ = 0.5;
~but3 = false;

//X axis
~joystick.elements.at(15).action = { |value|
	~joyX = value;
	switch(~globalParams.activeView)
	{\delay}  { {
		~instrWin.delSlider.x = value;
		if(~trigg) { ~instrWin.delSlider.action.value(); }
	}.defer; }
	{\playback}  { {
		//~instrWin.playbackSliderXY.x = value;
		if(~trigg) { ~instrWin.playbackSliderXY.action.value(); }
	}.defer; }
	{\wave}   { {
		var change = (value.round(0.001) - 0.5);
		if(change > 0, { // change is positive, move forwards
			change = change.linexp(0, 0.5, 1, 20000); // maps the range to an exponential one 1-20000
		}, {
			//change is negative, move backwards
			change = (change.abs.linexp(0, 0.5, 1, 20000)).neg;
		});

		~cursorChange = change;
	}.defer; }
	{\envelope} {
		if(~trigg) { ~channels[~currentChannel].updateEnvelopeXY(~joyX, 1 - ~joyY) };
	};
};

//Y axis // The joystick y axis is inverted compared to the GUI one
~joystick.elements.at(17).action = { |value|
	~joyY = value;
	switch(~globalParams.activeView)
	{\delay} { {
		~instrWin.delSlider.y = 1 - value;
		if(~trigg == true) { ~instrWin.delSlider.action.value(); };
	}.defer; }
	{\playback} { {
		//~instrWin.playbackSliderXY.y = 1 - value;
		if(~trigg == true) { ~instrWin.playbackSliderXY.action.value(); };
	}.defer; }
	{\wave} { {}.defer }
	{\envelope} {
		if(~trigg) { ~channels[~currentChannel].updateEnvelopeXY(~joyX, 1 - ~joyY) };
	};
};
//Z axis
~joystick.elements.at(20).action = { |value|
	~joyZ = value;
	switch(~globalParams.activeView)
	{\envelope} {
		if(~trigg) { ~channels[~currentChannel].updateSustainTime(~joyZ); };
	};
};

// Every button sends two different element messages
// Trigger button
~joystick.elements.at(0).action = { | value |
	if(value == 1, {
		~trigg = true;
		switch(~globalParams.activeView)
		{\delay} { {~instrWin.delSlider.action.value(); }.defer }
		{\envelope} {
			~channels[~currentChannel].updateEnvelopeXY(~joyX, 1 - ~joyY);
		}
		{\wave}  {
			~moveWaveCursor.stop();
			~changeWaveSelection.reset().play(AppClock);
		}
		{\playback} {
			{~instrWin.playbackSliderXY.action.value(); }.defer;
		};
	}, {
		~trigg = false;
		switch(~globalParams.activeView)
		{\wave}  {
			~changeWaveSelection.stop();
			~moveWaveCursor.reset.play(AppClock);
			{("Selection size: " ++ ~instrWin.soundFileView.selectionSize(0).asString).postln;}.defer;
			// Update the selection on the channel playback
			~updateChannelSelection.value();
		};
	});
};

// Throttle
~joystick.elements.at(19).action = { | value |
	var val = 1 - value.round(0.01);
	switch(~globalParams.activeView)
	{\delay} { {
		~instrWin.delMixSlider.valueAction = val;
	}.defer; }
	{\wave} { {}.defer }
	{\dist} { {
		~instrWin.distMixSlider.valueAction = val;
	}.defer; }
	{\reverb} { {
		~instrWin.revMixSlider.valueAction = val;
	}.defer; }
	{\playback} { {
		~instrWin.playbackSlider2.valueAction = val;
	}.defer; }
	{\envelope} {
		~channels[~currentChannel].decayLevel = val;
		~channels[~currentChannel].sustainLevel = val; // decayLevel == sustainLevel for now

		~channels[~currentChannel].updateEnvelope();
	}
};

// Throttle X axis
~joystick.elements.at(21).action = { | value |
	var val = value.round(0.01);
	switch(~globalParams.activeView)
	{\envelope} {
		if((val - 0.5).abs > 0.1, {
			var change = val - 0.5;
			if(change > 0, { // change is positive, move forwards
				change = change.linexp(0, 0.5, 0.001, 0.1); // maps the range to an exponential one 1-20000
			}, {
				//change is negative, move backwards
				change = (change.abs.linexp(0, 0.5, 0.001, 0.1)).neg;
			});
			~throttleXChange = change;
			~throttleXChange.postln;
		}, {
			~throttleXChange = 0;
		});


	}
};

// Joystick selector (four way round thingy)
~joystick.elements.at(25).action = { | value | // Left
	var currentIndex, newView;
	if(value == 1) { //Push down
		~viewsOrder.do {| obj, index | if(obj == ~globalParams.activeView, { currentIndex = index }) };
		if(currentIndex != 0) {
			newView = ~viewsOrder[currentIndex-1];
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);

		};
	};
};
~joystick.elements.at(24).action = { | value | // Right
	var currentIndex, newView;
	if(value == 1) { //Push down
		~viewsOrder.do {| obj, index | if(obj == ~globalParams.activeView, { currentIndex = index }) };
		if(currentIndex != (~viewsOrder.size-1)) {
			newView = ~viewsOrder[currentIndex+1];
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);

		};
	};
};
~joystick.elements.at(26).action = { | value | // Up
	var currentIndex, newView;
	if(value == 1) { //Push down
		~viewsOrder.do {| obj, index | if(obj == ~globalParams.activeView, { currentIndex = index }) };
		if(currentIndex != (~viewsOrder.size-1)) {
			newView = ~viewsOrder[currentIndex+1];
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);

		};
	};
};
~joystick.elements.at(27).action = { | value | // Down
	var currentIndex, newView;
	if(value == 1) { //Push down
		~viewsOrder.do {| obj, index | if(obj == ~globalParams.activeView, { currentIndex = index }) };
		if(currentIndex != (~viewsOrder.size-1)) {
			newView = ~viewsOrder[currentIndex+1];
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);

		};
	};
};

// Button 2
~joystick.elements.at(1).action = { | value |
	if(value == 1) { //Push down
		~channels[~currentChannel].playOnce.value();
	};
};
// Button 3
~joystick.elements.at(2).action = { | value |
	if(value == 1, { //Push down
		~but3 = true;
	}, {
		~but3 = false;
	});
};
// Button 5
~joystick.elements.at(4).action = { | value |
	if(value == 1) { //Push down
		{ ~instrWin.playLoopBut.valueAction = 1 }.defer;
	};
};
// Button 6
~joystick.elements.at(5).action = { | value |
	if(value == 1) { //Push down
		{ ~instrWin.playSeqBut.valueAction = 1 }.defer;
	};
};
// Button 8
~joystick.elements.at(7).action = { | value |
	if(value == 1) { //Push down
		{ ~instrWin.playBut.valueAction = 1 }.defer;
	};
};
// Button 9
~joystick.elements.at(8).action = { | value |
	if(value == 1) { //Push down
		switch(~globalParams.activeView)
		{\envelope} { // Change active node
			if(~channels[~currentChannel].activeEnvelopeNode != 0, {
				~channels[~currentChannel].activeEnvelopeNode = ~channels[~currentChannel].activeEnvelopeNode - 1;
			});
		}
	};
};
// Button 10
~joystick.elements.at(9).action = { | value | // Left
	if(value == 1) { //Push down
		switch(~globalParams.activeView)
		{\envelope} { // Change active node
			if(~channels[~currentChannel].activeEnvelopeNode < (~channels[~currentChannel].numEnvNodes -1) , {
				~channels[~currentChannel].activeEnvelopeNode = ~channels[~currentChannel].activeEnvelopeNode + 1;
			});
		}
	};
};


~changeViewJoystick = { arg newView;
	~moveWaveCursor.stop();
	~changeWaveSelection.stop();
	~moveEnvelopeNode.stop();
	switch(newView)
	{\wave} {
		{~instrWin.waveBut.action.value(); }.defer;
		~moveWaveCursor.reset.play(AppClock);
		~cursorChange = 0;
	}
	{\delay} { {~instrWin.delBut.action.value(); }.defer }
	{\dist} { {~instrWin.distBut.action.value(); }.defer }
	{\playback} { {~instrWin.playbackBut.action.value(); }.defer }
	{\envelope} {
		{~instrWin.envBut.action.value(); }.defer;
		~moveEnvelopeNode.reset.play();
	}
	{\reverb} { {~instrWin.revBut.action.value(); }.defer }
};

// Must be played on the AppClock
~moveWaveCursor = Routine({
	loop {
		var pos = ~instrWin.soundFileView.timeCursorPosition;
		~instrWin.soundFileView.timeCursorPosition = pos + ~cursorChange;
		if(~instrWin.soundFileView.timeCursorPosition < 0, {
			~instrWin.soundFileView.timeCursorPosition = 0;
		});
		if(~instrWin.soundFileView.timeCursorPosition > ~instrWin.soundFileView.numFrames, {
			~instrWin.soundFileView.timeCursorPosition = ~instrWin.soundFileView.numFrames;
		});
		~globalParams.updateRate.wait;
	}
});

~moveEnvelopeNode = Routine({
	loop {
		var releaseTimeRatio = ~channels[~currentChannel].releaseTimeRatio;
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			if(releaseTimeRatio + ~throttleXChange < 0, {
				~channels[~currentChannel].releaseTimeRatio = 0;
			}, {
				if(releaseTimeRatio + ~throttleXChange > 1, {
					~channels[~currentChannel].releaseTimeRatio = 1;
				}, {
					~channels[~currentChannel].releaseTimeRatio = releaseTimeRatio + ~throttleXChange;
				});
			});
			~channels[~currentChannel].updateEnvelope.value(); // calculates the envelope and updates the envelope synth
		};
		~globalParams.updateRate.wait;
	}
});

~changeWaveSelection = Routine({
	var pos = ~instrWin.soundFileView.timeCursorPosition,
	size = 0;
	//("pos: " ++ pos.asString).postln;
	~instrWin.soundFileView.setSelectionStart(0, pos);
	~instrWin.soundFileView.setSelectionSize(0, 0);
	loop {
		// Check so that the size does not get bigger than the buffer
		if((~instrWin.soundFileView.timeCursorPosition + size) >= 0 &&
			(~instrWin.soundFileView.timeCursorPosition + size <= ~instrWin.soundFileView.numFrames),{
				size = size + ~cursorChange;
		});
		// Correct the size
		if(~instrWin.soundFileView.timeCursorPosition + size < 0, { // If beyond the beginning
			size = ~instrWin.soundFileView.timeCursorPosition.neg;
		});
		if(~instrWin.soundFileView.timeCursorPosition + size > ~instrWin.soundFileView.numFrames, { // If beyond the end
			size = ~instrWin.soundFileView.numFrames - ~instrWin.soundFileView.timeCursorPosition;
		});
		//("size: " ++ size.asString).postln;
		~instrWin.soundFileView.setSelectionSize(0, size);
		// Needs to set start point every iteration too, otherwise negative selections jump backwards
		if(size < 0, {~instrWin.soundFileView.setSelectionStart(0, pos+size) });
		~globalParams.updateRate.wait;
	}
});

// INIT PROGRAM PARAMETERS
~changeViewJoystick.value();

/*
~instrWin.delSlider.x = 0.5
*/