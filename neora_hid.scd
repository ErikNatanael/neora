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
~viewsOrder = [\wave, \playback, \delay, \dist, \reverb];

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
	switch(~globalParams.activeView)
	{\delay}  { {
		~instrWin.delSlider.x = value;
		if(~trigg) { ~instrWin.delSlider.action.value(); }
	}.defer; }
	{\playback}  { {
		~instrWin.playbackSliderXY.x = value;
		if(~trigg) { ~instrWin.playbackSliderXY.action.value(); }
	}.defer; }
	{\wave}   { {
		var change = (value.round(0.001) - 0.5) * 5000;
		~cursorChange = change;
	}.defer; };
};

//Y axis // The joystick y axis is inverted compared to the GUI one
~joystick.elements.at(17).action = { |value|
	switch(~globalParams.activeView)
	{\delay} { {
		~instrWin.delSlider.y = 1 - value;
		if(~trigg == true) { ~instrWin.delSlider.action.value(); };
	}.defer; }
	{\playback} { {
		~instrWin.playbackSliderXY.y = 1 - value;
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
			~changeWaveSelection.reset().play();
		};
	}, {
		~trigg = false;
		switch(~globalParams.activeView)
		{\wave}  {
			~changeWaveSelection.stop();
			~moveWaveCursor.play();
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

~changeViewJoystick = { arg newView;
	~moveWaveCursor.stop();
	~changeWaveSelection.stop();
	switch(newView)
	{\wave} {
		{~instrWin.waveBut.action.value(); }.defer;
		~moveWaveCursor.reset.play();
		~cursorChange = 0;
	}
	{\delay} { {~instrWin.delBut.action.value(); }.defer }
	{\dist} { {~instrWin.distBut.action.value(); }.defer }
	{\playback} { {~instrWin.playbackBut.action.value(); }.defer }
	{\reverb} { {~instrWin.revBut.action.value(); }.defer }
};

// Must be played on the AppClock
~moveWaveCursor = Task({
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
}, AppClock);

~changeWaveSelection = Task({
	var pos = ~instrWin.soundFileView.timeCursorPosition,
	size = 0;
	//("pos: " ++ pos.asString).postln;
	~instrWin.soundFileView.setSelectionStart(0, pos);
	~instrWin.soundFileView.setSelectionSize(0, 0);
	loop {
		size = size + ~cursorChange;
		//("size: " ++ size.asString).postln;
		~instrWin.soundFileView.setSelectionSize(0, size);
		// Needs to set start point every iteration too, otherwise negative selections jump backwards
		if(size < 0, {~instrWin.soundFileView.setSelectionStart(0, pos+size) });
		~globalParams.updateRate.wait;
	}
}, AppClock);

// INIT PROGRAM PARAMETERS
~changeViewJoystick.value();

/*
~instrWin.delSlider.x = 0.5
*/