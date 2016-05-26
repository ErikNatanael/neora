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

/*Ndef( \sinewave, { |freq=500, amp=0.1| SinOsc.ar( freq, 0, amp * 0.2 ) } );
Ndef( \sinewave ).play;

~freqRange = [500, 5000, \exponential].asSpec; // create a frequency range

HIDdef.usageID( \freq, { |value| Ndef( \sinewave ).set( \freq, ~freqRange.map( value ) ); }, 48, 1 ); // X axis // Makes everything affect freq
// This does nothing
HIDdef.element( \amp, { |value| Ndef( \sinewave ).set( \amp, value ); }, 17, "T.Flight Hotas X"); // Y axis

// These two work
~myhid.elements.at(15).action = { |value| Ndef( \sinewave ).set( \freq, ~freqRange.map( value ) ); }; // X axis
~myhid.elements.at(17).action = { |value| Ndef( \sinewave ).set( \amp, value ); }; // X axis*/



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
	}.defer; };
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
	{\wave} { {}.defer };
};

// Every button sends two different element messages
// Trigger button
~joystick.elements.at(0).action = { | value |
	if(value == 1, {
		~trigg = true;
		switch(~globalParams.activeView)
		{\delay} { {~instrWin.delSlider.action.value(); }.defer }
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
	{\envelope} { var activeNode;
		activeNode = ~channels[~currentChannel].activeEnvelopeNode;
		switch(activeNode)
		{0} { ~channels[~currentChannel].attackLevel = val; }
		{1} { ~channels[~currentChannel].sustainLevel = val; };
		~channels[~currentChannel].updateEnvelope.value();
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
		var activeNode = ~channels[~currentChannel].activeEnvelopeNode;
		if(~throttleXChange != 0) { // Don't do anything unless there is any change
			switch(activeNode)
			{0} { // TODO: Change the if statements so that the max or min value is chosen if the change would go past that
				if( ~channels[~currentChannel].sustainTimeRatio - ~throttleXChange > 0 &&
					(~channels[~currentChannel].attackTimeRatio + ~throttleXChange > 0), {
						~channels[~currentChannel].attackTimeRatio = ~channels[~currentChannel].attackTimeRatio + ~throttleXChange;
						~channels[~currentChannel].sustainTimeRatio = ~channels[~currentChannel].sustainTimeRatio - ~throttleXChange;
				});
			}
			{1} {
				if( ~channels[~currentChannel].sustainTimeRatio + ~channels[~currentChannel].attackTimeRatio + ~throttleXChange < 1 &&
					(~channels[~currentChannel].sustainTimeRatio + ~throttleXChange > 0), {
						~channels[~currentChannel].sustainTimeRatio = ~channels[~currentChannel].sustainTimeRatio + ~throttleXChange;
				});
			};
			~channels[~currentChannel].updateEnvelope.value(); // Sets the decayTimeRatio and updates the envelope synth
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