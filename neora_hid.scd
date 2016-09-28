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
	{\delay}  {
		if(~trigg == true) {
			~channels[~currentChannel].delayTime = ~specs.delayTime.map(value);
			~channels[~currentChannel].updateDelay;
		};
	}
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
	{\resonant} {
		if(~trigg) {
			~channels[~currentChannel].resrq = ~specs.resonantRQ.map(~joyX);
			~channels[~currentChannel].updateResonant();
		};
	}
	{\filter} { if(~trigg) {
		~channels[~currentChannel].combLPFFreq = ~specs.combLPFFreq.map(~joyX);
		~channels[~currentChannel].updateComb();
	};
	}
	{\envelope} {
		if(~trigg) { ~channels[~currentChannel].updateEnvelopeXY(~joyX, 1 - ~joyY) };
	};
};

//Y axis // The joystick y axis is inverted compared to the GUI one
~joystick.elements.at(17).action = { |value|
	~joyY = value;
	switch(~globalParams.activeView)
	{\delay} {
		if(~trigg == true) {
			~channels[~currentChannel].delayFeedback = ~specs.delayFeedback.map(1 - value);
			~channels[~currentChannel].updateDelay;
		};
	}
	{\playback} { {
		//~instrWin.playbackSliderXY.y = 1 - value;
		if(~trigg == true) { ~instrWin.playbackSliderXY.action.value(); };
	}.defer; }
	{\wave} { {}.defer }
	{\filter} {
		if(~trigg) {
			~channels[~currentChannel].combFeedback = ~specs.combFeedback.map(~joyY);
			~channels[~currentChannel].updateComb();
		};
	}
	{\resonant} {
		if(~trigg) {
			~channels[~currentChannel].resdb = ~specs.resonantDB.map(1 - ~joyY); // Change the "polarity" to make more sense
			~channels[~currentChannel].updateResonant();
		};
	}
	{\envelope} {
		if(~trigg) { ~channels[~currentChannel].updateEnvelopeXY(~joyX, 1 - ~joyY) };
	};
};
//Z axis
~joystick.elements.at(20).action = { |value|
	~joyZ = value;
	switch(~globalParams.activeView)
	{\filter} {
		if(~trigg == true) {
			~channels[~currentChannel].combMix = ~specs.mix.map(~joyZ);
			~channels[~currentChannel].updateComb();
		};
	}
	{\resonant} {
		if(~trigg == true) {
			~channels[~currentChannel].resMix = ~specs.mix.map(~joyZ);
			~channels[~currentChannel].updateResonantMix();
		};
	}
	{\delay} {
		if(~trigg == true) {
			~channels[~currentChannel].delayMix = ~specs.halfmix.map(value);
			~channels[~currentChannel].updateDelay;
		};
	}
	{\envelope} {
		if(~trigg == true) { ~channels[~currentChannel].updateSustainTime(~joyZ); };
	};
};



// Throttle
~joystick.elements.at(19).action = { | value |
	var val = 1 - value.round(0.01);
	switch(~globalParams.activeView)
	{\wave} { {}.defer }
	{\dist} {
		~channels[~currentChannel].distortionMix = ~specs.mix.map(val);
		~channels[~currentChannel].updateDistortion;
	}
	{\delay} {
	~channels[~currentChannel].reverbMix = val;
	~channels[~currentChannel].updateReverb;
	}
	{\playback} { {
		~instrWin.playbackSlider2.valueAction = val;
	}.defer; }
	{\filter} {
		~channels[~currentChannel].combLFODepth = ~specs.combLFODepth.map(val);
		~channels[~currentChannel].updateComb();
	}
	{\resonant} {
		var maxPartials = 20,
		cell = (val * maxPartials).trunc(1) + 1; // 1 is the lowest number of partials possible
		if (cell == maxPartials) { cell = maxPartials -1};
		cell = cell.asInteger;
		if(~channels[~currentChannel].numPartials != cell) {
			~channels[~currentChannel].numPartials = cell;
			~channels[~currentChannel].resFade = 0.05;
			~channels[~currentChannel].createEQ();
		};
	}
	{\envelope} {
		~channels[~currentChannel].decayLevel = val;
		~channels[~currentChannel].sustainLevel = val; // decayLevel == sustainLevel for now

		~channels[~currentChannel].updateEnvelope();
	}
};

// Throttle X axis
~joystick.elements.at(21).action = { | value |
	var val = value.round(0.01);
	//if(~globalParams.activeView == \envelope || (~globalParams.activeView == \filter) || (~globalParams.activeView == \resonant)) {
	if((val - 0.5).abs > 0.1, {
		var change = val - 0.5;
		if(change > 0, { // change is positive, move forwards
			change = change.linexp(0, 0.5, 0.001, 0.1); // maps the range to an exponential one 1-20000
		}, {
			//change is negative, move backwards
			change = (change.abs.linexp(0, 0.5, 0.001, 0.1)).neg;
		});
		~throttleXChange = change;
	}, {
		~throttleXChange = 0;
	});
	//}
};

// Joystick selector (four way round thingy)
~joystick.elements.at(25).action = { | value | // Left
	var newView;
	if(value == 1) { //Push down
		if(~globalParams.activeView != \load_sample && (~globalParams.activeView != \move_pitch)
		&& (~globalParams.activeView != \change_scale)) {
			if(~but3 == true, {
				newView = \playback;
			}, {
				newView = \pitch; //pitch
			});
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);
		};

		if(~globalParams.activeView == \load_sample) {
			//Load sample
			~selectedSample[0] = ~selectedSample[0] - 1;
			if(~selectedSample[0] < 0) { ~selectedSample[0] = 0 };
		};
		if(~globalParams.activeView == \move_pitch) {
			// Move the selected pitches
			~channels[~currentChannel].selectedPitches = ~channels[~currentChannel].selectedPitches.collect { | pair |
				// every pair consists of [row, column]
				pair[1] = pair[1] - 1;
				if( pair[1] < 0) { pair[1] = ~channels[~currentChannel].scale.degrees.size -1; };
				pair;
			};
		};
		if(~globalParams.activeView == \change_scale) {
			~selectedScale[0] = ~selectedScale[0] - 1;
			if(~selectedScale[0] < 0) { ~selectedScale[0] = 11 }
		};
	};
};
~joystick.elements.at(24).action = { | value | // Right
	var currentIndex, newView;
	if(value == 1) { //Push down
		if(~globalParams.activeView != \load_sample && (~globalParams.activeView != \move_pitch)
		&& (~globalParams.activeView != \change_scale)) {			if(~but3 == true, {
				newView = \envelope; //effects
			}, {
				newView = \dist;
			});
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);
		};
		if(~globalParams.activeView == \load_sample) {
			//Load sample
			~selectedSample[0] = ~selectedSample[0] + 1;
			if(~selectedSample[0] >= ~globalParams.sampleFolders.size) { ~selectedSample[0] = ~globalParams.sampleFolders.size - 1 };
		};
		if(~globalParams.activeView == \move_pitch) {
			~channels[~currentChannel].selectedPitches = ~channels[~currentChannel].selectedPitches.collect { | pair |
				// every pair consists of [row, column]
				pair[1] = pair[1] + 1;
				if( pair[1] >= ~channels[~currentChannel].scale.degrees.size) { pair[1] = 0; };
				pair;
			};
		};
		if(~globalParams.activeView == \change_scale) {
			~selectedScale[0] = ~selectedScale[0] + 1;
			if(~selectedScale[0] > 11) { ~selectedScale[0] = 0 }
		};
	};
};
~joystick.elements.at(26).action = { | value | // Up
	var currentIndex, newView;
	if(value == 1) { //Push down
		if(~globalParams.activeView != \load_sample && (~globalParams.activeView != \move_pitch)
		&& (~globalParams.activeView != \change_scale)) {
			if(~but3 == true, {
				newView = \sequencer;
			}, {
				newView = \wave;
			});
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);
		};
		if(~globalParams.activeView == \load_sample) {
			//Load sample
			~selectedSample[1] = ~selectedSample[1] - 1;
			if(~selectedSample[1] < 0) { ~selectedSample[1] = 0 };
		};
		if(~globalParams.activeView == \move_pitch) {
			// Move the selected pitches
			~channels[~currentChannel].selectedPitches = ~channels[~currentChannel].selectedPitches.collect { | pair |
				// every pair consists of [row, column]
				pair[0] = pair[0] - 1;
				if( pair[0] < 0) { pair[0] = ~channels[~currentChannel].numRows -1; };
				pair; // last element is returned
			};
		};
		if(~globalParams.activeView == \change_scale) {
			~selectedScale[1] = ~selectedScale[1] - 1;
			if(~selectedScale[1] < 0) { ~selectedScale[1] = ~globalParams.scales.size - 1 }
		};
	};
};
~joystick.elements.at(27).action = { | value | // Down
	var currentIndex, newView;
	if(value == 1) { //Push down
		if(~globalParams.activeView != \load_sample && (~globalParams.activeView != \move_pitch)
		&& (~globalParams.activeView != \change_scale)) {
			if(~but3 == true, {
				newView = \delay; //room
			}, {
				newView = \filter;
			});
			~globalParams.activeView = newView;
			~changeViewJoystick.value(newView);
		};
		if(~globalParams.activeView == \load_sample) {
			//Load sample
			~selectedSample[1] = ~selectedSample[1] + 1;
			if(~selectedSample[1] >= ~globalParams.samples[~selectedSample[0]].size) { ~selectedSample[1] = ~globalParams.samples[~selectedSample[0]].size -1 };
		};
		if(~globalParams.activeView == \move_pitch) {
			// Move the selected pitches
			~channels[~currentChannel].selectedPitches = ~channels[~currentChannel].selectedPitches.collect { | pair |
				// every pair consists of [row, column]
				pair[0] = pair[0] + 1;
				if( pair[0] >= ~channels[~currentChannel].numRows) { pair[0] = 0 };
				pair.postln;
				pair;
			};
		};
		if(~globalParams.activeView == \change_scale) {
			~selectedScale[1] = ~selectedScale[1] + 1;
			if(~selectedScale[1] >= ~globalParams.scales.size) { ~selectedScale[1] = 0 }
		};
	};
};

//////////////////////////////////////////////////////// Buttons!!! \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// Every button sends two different element messages
// Trigger button
~joystick.elements.at(0).action = { | value |
	if(value == 1, {
		~trigg = true;
		switch(~globalParams.activeView)
		{\delay} {
			~channels[~currentChannel].delayTime = ~specs.delayTime.map(~joyX);
			~channels[~currentChannel].delayFeedback = ~specs.delayFeedback.map(1 - ~joyY);
			~channels[~currentChannel].delayMix = ~specs.halfmix.map(~joyZ);
			~channels[~currentChannel].updateDelay;
		}
		{\envelope} {
			~channels[~currentChannel].updateEnvelopeXY(~joyX, 1 - ~joyY);
		}
		{\wave}  {
			~moveWaveCursor.stop();
			~changeWaveSelection.reset().play(AppClock);
		}
		{\pitch}  {
			~channels[~currentChannel].updatePitches;
		}
		{\load_sample}  {
			// Start a task to load a new sample into the selected channel
			Task({ // Needs to be a Task to sync after buffer allocation
				var
				sf = SoundFile.new,
				filename = ~globalParams.samples[~selectedSample[0]][~selectedSample[1]];
				if(sf.openRead(filename)) { var newBuf;
					~channels[~currentChannel].stopChan();
					~channels[~currentChannel].soundFile = sf;
					newBuf = Buffer.read(s, filename);
					s.sync();
					~channels[~currentChannel].buffer = newBuf;
					~channels[~currentChannel].startPos = 0;
					~channels[~currentChannel].endPos = ~channels[~currentChannel].buffer.numFrames;
					~channels[~currentChannel].selLength = ~channels[~currentChannel].buffer.numFrames;
					~changeChannel.value();
				};

			}).play;
		}
		{\filter} {
			~channels[~currentChannel].combFeedback = ~specs.combFeedback.map(~joyY);
			~channels[~currentChannel].combLPFFreq = ~specs.combLPFFreq.map(~joyX);
			~channels[~currentChannel].combMix = ~specs.mix.map(~joyZ);
			~channels[~currentChannel].updateComb();
		}
		{\sequencer} {
			var size = ~globalParams.xySliderSize,
			nx = ~joyX * size,
			ny = ~joyY * size;

			if(ny < (size/7)) {
				"Tab change".postln;
				if(nx <= (size/4)) {
					~channels[~currentChannel].seqTab = \dur;
				};
				if(nx > (size/4) && (nx <= (size/4*2))) {
					~channels[~currentChannel].seqTab = \speed;
				};
				if(nx > (size/4*2) && (nx <= (size/4*3))) {
					~channels[~currentChannel].seqTab = \amp;
				};
				if(nx > (size/4*3) && (nx <= size)) {
					~channels[~currentChannel].seqTab = \speed;
				};
			};
			switch(~channels[~currentChannel].seqTab)
			{\dur} {
				if(ny > (size/7) && (ny < (size/7*2))) {
					if(nx <= (size/4)) {
						~channels[~currentChannel].durPattern = \pseq;
						~channels[~currentChannel].updatePdef();

					};
					if(nx > (size/4) && (nx <= (size/4*2))) {
						~channels[~currentChannel].durPattern = \prand;
						~channels[~currentChannel].updatePdef();
					};
					if(nx > (size/4*2) && (nx <= (size/4*3))) {
						~channels[~currentChannel].durPattern = \pxrand;
						~channels[~currentChannel].updatePdef();
					};
					if(nx > (size/4*3) && (nx <= (size))) {
						~channels[~currentChannel].durPattern = \pwrand;
						~channels[~currentChannel].updatePdef();
					};
					("Pattern change to" + ~channels[~currentChannel].durPattern.asString).postln;

				};
				if(ny > (size/7*5) && (ny <= (size/7*6))) { var column;
					// dur list
					"Dur change".postln;
					~staticJoyX = ~joyX;
					~staticJoyY = ~joyY;
					column = (~joyX * ~channels[~currentChannel].durList.size).trunc(1);
					~channels[~currentChannel].selectedDur = column;
					~tempDurIndex = ~channels[~currentChannel].durNoteValues.indexOf(~channels[~currentChannel].durList[column]);
					("tempDurIndex: " + ~tempDurIndex.asString).postln;
					~changeSeqDur.reset.play();
				};
				if(ny > (size/7*6) && (ny <= (size))) { var column;
					// weight list if pwrand or dur list if pseq
					switch(~channels[~currentChannel].durPattern)
					{\pseq} {
						"Dur change".postln;
						~staticJoyX = ~joyX;
						~staticJoyY = ~joyY;
						column = (~joyX * ~channels[~currentChannel].durList.size).trunc(1);
						~channels[~currentChannel].selectedDur = column + 8;
						~tempDurIndex = ~channels[~currentChannel].durNoteValues.indexOf(~channels[~currentChannel].durList2[column]);
						("tempDurIndex: " + ~tempDurIndex.asString).postln;
						~changeSeqDur.reset.play();
					}
					{\pwrand} {
						"Weight change".postln;
						~staticJoyX = ~joyX;
						~staticJoyY = ~joyY;
						column = (~joyX * ~channels[~currentChannel].durWeights.size).trunc(1);
						~channels[~currentChannel].selectedWeight = column;
						~changeSeqWeight.reset.play();
					}
				};
			}
			{\amp} {
				if(ny > (size/7) && (ny < (size/7*2))) {
					if(nx <= (size/4)) {
						~channels[~currentChannel].ampPattern = \pwhite;
						~channels[~currentChannel].updatePdef();
					};
					if(nx > (size/4) && (nx <= (size/4*2))) {
						~channels[~currentChannel].ampPattern = \pseq;
						~channels[~currentChannel].updatePdef();
					};
					if(nx > (size/4*2) && (nx <= (size/4*3))) {
						~channels[~currentChannel].ampPattern = \prand;
						~channels[~currentChannel].updatePdef();
					};
					if(nx > (size/4*3) && (nx <= (size))) {
						~channels[~currentChannel].ampPattern = \pgauss;
						~channels[~currentChannel].updatePdef();
					};
					("Pattern change to" + ~channels[~currentChannel].ampPattern.asString).postln;
				};
				switch(~channels[~currentChannel].ampPattern)
				{\pwhite} {
					if(ny > (size/7*5) && (ny < (size/7*6))) {
						~staticJoyX = ~joyX;
						~staticJoyY = ~joyY;

						if(nx <= (size/4)) {
							~channels[~currentChannel].selectedAmp = 0;
							~changeSeqAmpWhite.reset.play();
						};
						if(nx > (size/4*2) && (nx <= (size/4*3))) {
							~channels[~currentChannel].selectedAmp = 1;
							~changeSeqAmpWhite.reset.play();
						};
					}
				}
				{\pseq} {
					~staticJoyX = ~joyX;
					~staticJoyY = ~joyY;
					if(ny > (size/7*5) && (ny <= (size/7*6))) { var column;
						column = (~joyX * ~channels[~currentChannel].ampList.size).trunc(1);
						~channels[~currentChannel].selectedAmp = column;
					};
					if(ny > (size/7*6) && (ny <= (size))) { var column;
						column = (~joyX * ~channels[~currentChannel].ampList2.size).trunc(1);
						~channels[~currentChannel].selectedAmp = column + 8;
					};
					~changeSeqAmpPseq.reset.play();
				}
			}
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
		}
		{\sequencer} {
			if(~channels[~currentChannel].selectedDur != -1) {
				~channels[~currentChannel].selectedDur = -1;
				~changeSeqDur.stop();
			};
			if(~channels[~currentChannel].selectedWeight != -1) {
				~channels[~currentChannel].selectedWeight = -1;
				~changeSeqWeight.stop();
			};
			if(~channels[~currentChannel].selectedAmp != -1) {
				~channels[~currentChannel].selectedAmp = -1;
				~changeSeqAmpWhite.stop();
			};
		};
	});
};

// Button 2
~joystick.elements.at(1).action = { | value |
	if(value == 1) { //Push down
		~channels[~currentChannel].playOnce.value();
		("~globalParams.activeView: " + ~globalParams.activeView.asString).postln;
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
// Button 4
~joystick.elements.at(3).action = { | value |
	if(value == 1) { //Push down
		switch(~globalParams.activeView)
		{\pitch} { // Select pitches
			var numRows = ~channels[~currentChannel].pitchMatrix.size,
			row = (~joyY * numRows).trunc(1),
			column = (~joyX * ~channels[~currentChannel].scale.degrees.size).trunc(1);
			if(row == numRows) { row = numRows-1}; // Right at the edge the row can get larger than max
			if(column == ~channels[~currentChannel].scale.degrees.size) { column = ~channels[~currentChannel].scale.degrees.size -1 };
			~channels[~currentChannel].selectPitch([row, column]);
			[row, column].postln;
		}
		{\sequencer} {
			~channels[~currentChannel].updatePdef();
		}
	};
};
// Button 5
~joystick.elements.at(4).action = { | value |
	if(value == 1) { //Push down
		switch(~globalParams.activeView)
		{\playback} {
		{ ~instrWin.playLoopBut.valueAction = 1 }.defer;
		}
		{\filter} {
		{ ~instrWin.combResBut.valueAction = 1 }.defer;
			~globalParams.activeView = \resonant;
			~changeViewJoystick.value(~globalParams.activeView);
		}
		{\resonant} {
		{ ~instrWin.resCombBut.valueAction = 1 }.defer;
			~globalParams.activeView = \filter;
			~changeViewJoystick.value(~globalParams.activeView);
		}
		{\pitch} { var root = ~channels[~currentChannel].rootNote,
			scale = ~globalParams.scales.indexOf(~channels[~currentChannel].scale);
			// Set selection to 0, 0
			~selectedScale = [root, scale];
			// Show sample loading library
			{ ~instrWin.changeScaleGUI.visible_(true); }.defer;
			~lastView = ~globalParams.activeView; // Store the active view for later retrieval
			~globalParams.activeView = \change_scale; // Set the view
		}
	} { // Release
		switch(~globalParams.activeView)
		{\change_scale} {
			// Restore view setting
			~globalParams.activeView = ~lastView;
			// Hide the selection view
			{ ~instrWin.changeScaleGUI.visible_(false); }.defer;
			// Set the new scale
			~channels[~currentChannel].scale = ~globalParams.scales[~selectedScale[1]];
			~channels[~currentChannel].rootNote = ~selectedScale[0];
		}
	};
};
// Button 6
~joystick.elements.at(5).action = { | value |
	if(value == 1) { //Push down
		{ ~instrWin.playSeqBut.valueAction = 1 }.defer;
	};
};
// Button 7
~joystick.elements.at(6).action = { | value |
	if(value == 1) { //Push down
		{ ~instrWin.playJumpBut.valueAction = 1 }.defer;
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
		{\envelope} {
			if(~channels[~currentChannel].activeEnvelopeNode != 0, {
				~channels[~currentChannel].activeEnvelopeNode = ~channels[~currentChannel].activeEnvelopeNode - 1;
			});
		}
	} {
	};

};
// Button 10
~joystick.elements.at(9).action = { | value |
	if(value == 1) { //Push down
		switch(~globalParams.activeView)
		{\pitch} {
			// Toggle movement of the selected pitches using four way thingy
			~lastView = ~globalParams.activeView; // Store the active view for later retrieval
			~globalParams.activeView = \move_pitch; // Set the view
		}
	} { // Release
		switch(~globalParams.activeView)
		{\move_pitch} {
			// Restore view setting
			~globalParams.activeView = ~lastView;
		}
	};
};
// Button SE
~joystick.elements.at(10).action = { | value |
	if(value == 1) { //Push down
		// Set selection to 0, 0
		~selectedSample = [0, 0];
		// Show sample loading library
		{ ~instrWin.loadSampleGUI.visible_(true); }.defer;
		~lastView = ~globalParams.activeView; // Store the active view for later retrieval
		~globalParams.activeView = \load_sample; // Set the view
	} {
		//Release
		// Restore view setting
		~globalParams.activeView = ~lastView;
		// Hide the selection view
		{ ~instrWin.loadSampleGUI.visible_(false); }.defer;
	};
};


~changeViewJoystick = { arg newView;
	~moveWaveCursor.stop();
	~changeWaveSelection.stop();
	~moveEnvelopeNode.stop();
	~changeCombLFOFreq.stop();
	~changeResPartialRatio.stop();
	~changePitchOctave.stop();
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
	{\filter} { {~instrWin.combBut.action.value(); }.defer;
		~changeCombLFOFreq.reset.play();
	}
	{\sequencer} { {~instrWin.seqBut.action.value(); }.defer;
	}
	{\resonant} {
		~changeResPartialRatio.reset.play();
	}
	{\pitch} {
		{~instrWin.pitchBut.action.value(); }.defer;
		~temp_octave = ~channels[~currentChannel].octave;
		~changePitchOctave.reset.play();
	}
};

// Must be played on the AppClock
~moveWaveCursor = Routine({
	loop {
		var pos = ~instrWin.soundFileView.timeCursorPosition;
		~instrWin.soundFileView.timeCursorPosition = pos + ~cursorChange;
		if(~instrWin.soundFileView.timeCursorPosition < 0, {
			~instrWin.soundFileView.timeCursorPosition = 0;
			~instrWin.soundFileMiniView.timeCursorPosition = 0;

		});
		if(~instrWin.soundFileView.timeCursorPosition > ~instrWin.soundFileView.numFrames, {
			~instrWin.soundFileView.timeCursorPosition = ~instrWin.soundFileView.numFrames;
			~instrWin.soundFileMiniView.timeCursorPosition = ~instrWin.soundFileMiniView.numFrames;
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

~changeCombLFOFreq = Routine({
	loop {
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			~channels[~currentChannel].combLFOFreq = ~channels[~currentChannel].combLFOFreq + ~throttleXChange;
			if(~channels[~currentChannel].combLFOFreq < 0.001) {
				~channels[~currentChannel].combLFOFreq = 0.001;
			};
			if(~channels[~currentChannel].combLFOFreq > 20) {
				~channels[~currentChannel].combLFOFreq = 20;
			};
			~channels[~currentChannel].updateComb();
		};
		~globalParams.updateRate.wait;
	}
});

~changePitchOctave = Routine({
	loop {
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			~temp_octave = ~temp_octave + ~throttleXChange;
			if( ~temp_octave < 1) { ~temp_octave = 1 };
			if( ~temp_octave > 7) { ~temp_octave = 10 };

			if( ~channels[~currentChannel].octave != ~temp_octave.round(1)) {
				~channels[~currentChannel].octave = ~temp_octave.round(1);
				~channels[~currentChannel].updateScaleMatrix();
			};
		};
		~globalParams.updateRate.wait;
	}
});

~changeSeqDur = Routine({
	loop {
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			var newDur;
			~tempDurIndex = ~tempDurIndex + ~throttleXChange;
			if(~tempDurIndex < 0) { ~tempDurIndex = 0 };
			if(~tempDurIndex > (~channels[~currentChannel].durNoteValues.size -1)) { ~tempDurIndex = ~channels[~currentChannel].durNoteValues.size - 1 };
			newDur = ~channels[~currentChannel].durNoteValues[~tempDurIndex.round(1)];
			if(~channels[~currentChannel].selectedDur < 8) {
				~channels[~currentChannel].durList[~channels[~currentChannel].selectedDur] = newDur;
			} {
				~channels[~currentChannel].durList2[~channels[~currentChannel].selectedDur-8] = newDur;

			};
		};
		~globalParams.updateRate.wait;
	}
});
~changeSeqWeight = Routine({
	loop {
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			var weight = ~channels[~currentChannel].durWeights[~channels[~currentChannel].selectedWeight];
			weight = weight + (~throttleXChange*0.1);
			if(weight < 0) { weight = 0 };
			if(weight > 1) { weight = 1 };
			~channels[~currentChannel].durWeights[~channels[~currentChannel].selectedWeight] = weight;
		};
		~globalParams.updateRate.wait;
	}
});
~changeSeqAmpPseq = Routine({
	loop {
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			var amp;
			if(~channels[~currentChannel].selectedAmp >= 8) {
				amp = ~channels[~currentChannel].ampList2[~channels[~currentChannel].selectedAmp-8];
			} {
				amp = ~channels[~currentChannel].ampList[~channels[~currentChannel].selectedAmp];
			};
			amp = amp + (~throttleXChange*0.1);
			if(amp < 0) { amp = 0 };
			if(amp > 1) { amp = 1 };
			if(~channels[~currentChannel].selectedAmp >= 8) {
				~channels[~currentChannel].ampList2[~channels[~currentChannel].selectedAmp-8] = amp
			} {
				~channels[~currentChannel].ampList[~channels[~currentChannel].selectedAmp] = amp
			};
		};
		~globalParams.updateRate.wait;
	}
});
~changeSeqAmpWhite = Routine({
	loop {
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			var amp;
			if(~channels[~currentChannel].selectedAmp == 0) {
				amp = ~channels[~currentChannel].ampLow
			} {
				amp = ~channels[~currentChannel].ampHigh
			};
			amp = amp + (~throttleXChange*0.3);
			if(amp < 0) { amp = 0 };
			if(amp > 1) { amp = 1 };
			if(~channels[~currentChannel].selectedAmp == 0) {
				~channels[~currentChannel].ampLow = amp
			} {
				~channels[~currentChannel].ampHigh = amp
			};
		};
		~globalParams.updateRate.wait;
	}
});

~changeResPartialRatio = Routine({
	loop {
		if(~throttleXChange != 0) { // Don't do anything unless there is change
			~channels[~currentChannel].resPartialRatio = ~channels[~currentChannel].resPartialRatio + (~throttleXChange*0.1);
			if(~channels[~currentChannel].resPartialRatio < 0.01) {
				~channels[~currentChannel].resPartialRatio = 0.01;
			};
			if(~channels[~currentChannel].resPartialRatio > 1) {
				~channels[~currentChannel].resPartialRatio = 1;
			};
			~channels[~currentChannel].resPartialRatio.postln;
			~channels[~currentChannel].updateResonant();
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
	~instrWin.soundFileMiniView.setSelectionStart(0, pos);
	~instrWin.soundFileMiniView.setSelectionSize(0, 0);
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
		~instrWin.soundFileMiniView.setSelectionSize(0, size);

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