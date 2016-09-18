/////////////// GUI component functions for the Neora sampler instrument \\\\\\\\\\\\\\\\\\\\\\


// Create view functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\

~createEnvelopeView = { | parent, x, y, width, height |
	var vi = UserView(parent, Rect(x, y, width, height));
	vi.background_(Color.green(0.2))
	.frameRate_(20)
	.animate_(true)
	.clearOnRefresh_(true)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var nodes = List[],
		ovalSize = width/40,
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

~createPlaybackSliderXY = { | parent, x, y |
	var viewSize = ~globalParams.xySliderSize;
	UserView(parent, Rect(x, y, viewSize, viewSize))
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

~createPlaybackMiniSliderXY = { | parent, x, y|
	var viewSize = ~globalParams.xySliderSize/~globalParams.miniatureRatio;
	UserView(parent, Rect(x, y, viewSize, viewSize))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var size = ~globalParams.xySliderSize/~globalParams.miniatureRatio,
		numRows = ~globalParams.rateRatios.size,
		crosshairSize = size/20/~globalParams.miniatureRatio,
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
};

//// Comb Filter View \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
~createCombXY = { | parent, x, y, size, text = true |
	UserView(parent, Rect(x, y, size, size))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var crosshairSize = size/20,
		smallCrosshairSize = size/30,
		realX = ~joyX*size,
		realY = ~joyY*size,
		markerX = ~specs.combLPFFreq.unmap(~channels[~currentChannel].combLPFFreq)*size,
		markerY = ~specs.combFeedback.unmap(~channels[~currentChannel].combFeedback)*size;

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, size, size));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw rows
		2.do {|i| Pen.addRect(Rect(0, size/2*i, size, size/2)) };
		Pen.stroke;

		// Draw strings
		if(text == true) {
			Pen.stringAtPoint("Positive feedback", (size/2 - 40) @ (size/4));
			Pen.stringAtPoint("Negative feedback", (size/2 - 40) @ (size/4*3));
			Pen.stringAtPoint("LPF Frequency: " + ~channels[~currentChannel].combLPFFreq.round.asString,
				(20) @ (size-20));
			Pen.stringAtPoint("Feedback: " + ~channels[~currentChannel].combFeedback.round(0.1).asString,
				(180) @ (size-20));
			Pen.stringAtPoint("Mix: " + ~channels[~currentChannel].combMix.round(0.01).asString,
				(260) @ (size-20));

			Pen.stroke;
		};

		// Draw X/Y
		Pen.color = Color.cyan;
		Pen.line((realX - (crosshairSize/2))@realY, (realX + (crosshairSize/2))@realY);
		Pen.line(realX@(realY - (crosshairSize/2)), realX@(realY + (crosshairSize/2)));
		Pen.addArc(realX@realY, crosshairSize/2, pi, 2*pi);
		Pen.addArc(realX@realY, crosshairSize/4, pi, 2*pi);
		Pen.stroke;

		// Draw marker for current value
		Pen.color = Color.red;
		Pen.line((markerX - (smallCrosshairSize/2))@markerY, (markerX + (smallCrosshairSize/2))@markerY);
		Pen.line(markerX@(markerY - (smallCrosshairSize/2)), markerX@(markerY + (smallCrosshairSize/2)));
		Pen.addArc(markerX@markerY, smallCrosshairSize/2, pi, 2*pi);
		Pen.addArc(markerX@markerY, smallCrosshairSize/4, pi, 2*pi);
		Pen.stroke;


	})
	.action_({ var x, y, row, column;
		x = ~joyX;
		y = ~joyY;
		//~changeCombFilter.value(x, y);
	})
	.mouseDownAction_( { | view, x, y |
		var relX = x/~globalParams.xySliderSize,
		relY = y/~globalParams.xySliderSize;
		//~changePlaybackRate.value(relX, relY);
		~joyX = relX;
		~joyY = relY;
	});
};

~createCombLFODepthView = { | parent, x, y, width, height, text = true |
	UserView(parent, Rect(x, y, width, height))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var lfoDepth = ~channels[~currentChannel].combLFODepth,

		lfoDepthMarker = lfoDepth/0.2; //Divide by the maximum value to map it to the 0-1 range

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, width, height));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw boundaries
		Pen.addRect(Rect(0, 0, width, height));
		Pen.stroke;

		// Draw depth marker
		Pen.color = Color.cyan;
		Pen.addRect(Rect(0, height-(lfoDepthMarker*height)-10, width, 10));
		Pen.fill;

		// Draw strings
		if(text == true) {
		Pen.color = Color.green(0.8);
		Pen.stringAtPoint("Depth: ", 0 @ 5);
		Pen.stringAtPoint(lfoDepth.asString, 5 @ 25);
		Pen.stroke;
		}

	})
	.action_({ var x, y, row, column;

	})
	.mouseDownAction_( { | view, x, y |

	});
};

~createCombLFOFreqView = { | parent, x, y, width, height, text = true |
	UserView(parent, Rect(x, y, width, height))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var lfoFreq= ~channels[~currentChannel].combLFOFreq,
		maxLFOFreq = ~globalParams.maxLFOFreq;

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, width, height));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw boundaries
		Pen.addRect(Rect(0, 0, width, height));
		Pen.stroke;

		// Draw depth marker
		Pen.color = Color.cyan;
		Pen.addRect(Rect((lfoFreq/maxLFOFreq)*width, 0, 10, height));
		Pen.fill;

		// Draw strings
		if(text == true) {
		Pen.color = Color.green(0.8);
		Pen.stringAtPoint("Frequency: " + lfoFreq.asString, 3 @ 5);
		Pen.stroke;
		};

	})
	.action_({ var x, y, row, column;

	})
	.mouseDownAction_( { | view, x, y |

	});
};

~createCombMini = { | parent |
	~createCombLFODepthView.value(parent, 0, 0, 40/~globalParams.miniatureRatio, ~globalParams.xySliderSize/~globalParams.miniatureRatio, false);
	~createCombLFOFreqView.value(parent, 40/~globalParams.miniatureRatio, ~globalParams.xySliderSize/~globalParams.miniatureRatio, ~globalParams.xySliderSize/~globalParams.miniatureRatio, 40/~globalParams.miniatureRatio, false);
	~createCombXY.value(parent, 40/~globalParams.miniatureRatio, 0, ~globalParams.xySliderSize/~globalParams.miniatureRatio, 40/~globalParams.miniatureRatio);
};

// Resonant filter bank view \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
~createResonantXY = { | parent, x, y, size, text = true |
	UserView(parent, Rect(x, y, size, size))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var crosshairSize = size/20,
		smallCrosshairSize = size/30,
		realX = ~joyX*size,
		realY = ~joyY*size,
		markerX = ~specs.combLPFFreq.unmap(~channels[~currentChannel].combLPFFreq)*size,
		markerY = ~specs.combFeedback.unmap(~channels[~currentChannel].combFeedback)*size,
		freqSpec = ControlSpec(20, 20000, \exponential);

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, size, size));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw rows
		2.do {|i| Pen.addRect(Rect(0, size/2*i, size, size/2)) };
		Pen.stroke;

		// Draw frequency lines
		~channels[~currentChannel].pitches.do { |freq, i|
			var mainx = freqSpec.unmap(freq)*size, // frequency position
			mainy = ~specs.resonantDB.unmap(~channels[~currentChannel].resdbs[i])*size;
			Pen.color = Color.green(0.8);
			Pen.line(mainx@(size-mainy), mainx@size);
			Pen.stroke;
			//("mainx: " + mainx.asString + " mainy: " + mainy.asString).postln;
			// Paint the partial lines red (numPartials includes the fundamental)
			((~channels[~currentChannel].numPartials) - 1).do { |j |
				var partX, partY, db;
				partX = freqSpec.unmap(freq * (j+2))*size;
				db = ~channels[~currentChannel].resdbs[i]*(~channels[~currentChannel].resPartialRatio.pow(j+1));
				partY = ~specs.resonantDB.unmap(db)*size;
				Pen.color = Color.red(0.8);
				Pen.line(partX@(size-partY), partX@size);
				Pen.stroke;
			};
		};

			// Draw strings
		if(text == true) {
			Pen.stringAtPoint("Amplitude: " + ~channels[~currentChannel].resdb.round(0.1).asString,
				(20) @ (size-20));
			Pen.stringAtPoint("Rq: " + ~channels[~currentChannel].resrq.round(0.00001).asString,
				(180) @ (size-20));
			Pen.stringAtPoint("Tilt: " + ~channels[~currentChannel].resdbTilt.round(0.01).asString,
				(260) @ (size-20));

			Pen.stroke;
		};

		// Draw X/Y
		Pen.color = Color.cyan;
		Pen.line((realX - (crosshairSize/2))@realY, (realX + (crosshairSize/2))@realY);
		Pen.line(realX@(realY - (crosshairSize/2)), realX@(realY + (crosshairSize/2)));
		Pen.addArc(realX@realY, crosshairSize/2, pi, 2*pi);
		Pen.addArc(realX@realY, crosshairSize/4, pi, 2*pi);
		Pen.stroke;

		// Draw marker for current value
		Pen.color = Color.red;
		Pen.line((markerX - (smallCrosshairSize/2))@markerY, (markerX + (smallCrosshairSize/2))@markerY);
		Pen.line(markerX@(markerY - (smallCrosshairSize/2)), markerX@(markerY + (smallCrosshairSize/2)));
		Pen.addArc(markerX@markerY, smallCrosshairSize/2, pi, 2*pi);
		Pen.addArc(markerX@markerY, smallCrosshairSize/4, pi, 2*pi);
		Pen.stroke;


	})
	.action_({ var x, y, row, column;
		x = ~joyX;
		y = ~joyY;
		//~changeCombFilter.value(x, y);
	})
	.mouseDownAction_( { | view, x, y |
		var relX = x/~globalParams.xySliderSize,
		relY = y/~globalParams.xySliderSize;
		//~changePlaybackRate.value(relX, relY);
		~joyX = relX;
		~joyY = relY;
	});
};

// Pitch selector view \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\+
~createPitchView = { | parent, x, y, width, height, text = true |
	UserView(parent, Rect(x, y, width, height))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var size = width,
		matrix = ~channels[~currentChannel].pitchMatrix,
		numRows = matrix.size,
		numColumns = ~channels[~currentChannel].scale.degrees.size,
		degrees = ~channels[~currentChannel].scale.degrees,
		root = ~channels[~currentChannel].rootNote,
		octave = ~channels[~currentChannel].octave,
		crosshairSize = size/20,
		realX = ~joyX*size,
		realY = ~joyY*size,
		selectedPitches = ~channels[~currentChannel].selectedPitches;

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, size, size));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw rows
		numRows.do {|i| Pen.addRect(Rect(0, size/numRows*i, size, size/numRows*(i+1))) };
		Pen.stroke;

		//TODO: Draw the selected pitches in another color

		// Draw boxes
		numRows.do { |i|
			numColumns.do { |j|
				var rect = Rect(size/numColumns*j, size/numRows*i, size/numColumns, size/numRows),
				name = "N", position, octaveNumber = 0;
				Pen.color = Color.green(0.8);
				Pen.addRect(rect);
				Pen.stroke;

				if(selectedPitches.includes([i, j])) {
					Pen.color = Color.red(0.8);
					Pen.alpha = 0.5;
					Pen.fillRect(rect);
					Pen.alpha = 1;
				};

				position = matrix[i][j][0];
				name = ~globalParams.rootNoteNames[((degrees[position] + root) % 12).asSymbol];
				octaveNumber = matrix[i][j][1];

				if(text == true) {
					Pen.color = Color.green(0.8);
					Pen.stringAtPoint(name,
						(size/numColumns*j + (size/numColumns/2 - (4*(name.size)))) @ (size/numRows*i + (size/numRows/2.8)));
					Pen.stringAtPoint(octaveNumber.asString,
						(size/numColumns*j + ((size/numColumns/2) - 4)) @ (size/numRows*i + (size/numRows/1.8)));
				};
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
		//~changePlaybackRate.value(x, y);
	})
	.mouseDownAction_( { | view, x, y |
		var relX = x/~globalParams.xySliderSize,
		relY = y/~globalParams.xySliderSize;
		//~changePlaybackRate.value(relX, relY);
		~joyX = relX;
		~joyY = relY;
	});
};

//// Reverb/delay View \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
~createRevdelXY = { | parent, x, y, size, text = true |
	UserView(parent, Rect(x, y, size, size))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var crosshairSize = size/20,
		smallCrosshairSize = size/30,
		realX = ~joyX*size,
		realY = ~joyY*size,
		markerX = ~specs.delayTime.unmap(~channels[~currentChannel].delayTime)*size,
		markerY = (1 -~specs.delayFeedback.unmap(~channels[~currentChannel].delayFeedback) ) * size;

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, size, size));
		Pen.alpha = 1;

		// Draw strings
		if(text == true) {
			Pen.color = Color.green(0.8);
			Pen.stringAtPoint("Delay time: " + ~channels[~currentChannel].delayTime.round(0.001).asString,
				(20) @ (size-20));
			Pen.stringAtPoint("Feedback: " + ~channels[~currentChannel].delayFeedback.round(0.001).asString,
				(120) @ (size-20));
			Pen.stringAtPoint("Mix: " + ~channels[~currentChannel].delayMix.round(0.01).asString,
				(260) @ (size-20));

			Pen.stroke;
		};

		// Draw X/Y
		Pen.color = Color.cyan;
		Pen.line((realX - (crosshairSize/2))@realY, (realX + (crosshairSize/2))@realY);
		Pen.line(realX@(realY - (crosshairSize/2)), realX@(realY + (crosshairSize/2)));
		Pen.addArc(realX@realY, crosshairSize/2, pi, 2*pi);
		Pen.addArc(realX@realY, crosshairSize/4, pi, 2*pi);
		Pen.stroke;

		// Draw marker for current value
		Pen.color = Color.red;
		Pen.line((markerX - (smallCrosshairSize/2))@markerY, (markerX + (smallCrosshairSize/2))@markerY);
		Pen.line(markerX@(markerY - (smallCrosshairSize/2)), markerX@(markerY + (smallCrosshairSize/2)));
		Pen.addArc(markerX@markerY, smallCrosshairSize/2, pi, 2*pi);
		Pen.addArc(markerX@markerY, smallCrosshairSize/4, pi, 2*pi);
		Pen.stroke;


	})
	.action_({ var x, y, row, column;
		x = ~joyX;
		y = ~joyY;
	})
	.mouseDownAction_( { | view, x, y |
		var relX = x/~globalParams.xySliderSize,
		relY = y/~globalParams.xySliderSize;
		~joyX = relX;
		~joyY = relY;
	});
};

~createRevMixView = { | parent, x, y, width, height, text = true |
	UserView(parent, Rect(x, y, width, height))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var revMix = ~channels[~currentChannel].reverbMix,

		revMixMarker = revMix/1; //Divide by the maximum value to map it to the 0-1 range

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, width, height));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw boundaries
		Pen.addRect(Rect(0, 0, width, height));
		Pen.stroke;

		// Draw depth marker
		Pen.color = Color.cyan;
		Pen.addRect(Rect(0, height-(revMixMarker*height)-10, width, 10));
		Pen.fill;

		// Draw strings
		if(text == true) {
		Pen.color = Color.green(0.8);
		Pen.stringAtPoint("Mix: ", 0 @ 5);
		Pen.stringAtPoint(revMix.asString, 5 @ 25);
		Pen.stroke;
		}

	});
};


~createRevdelMini = { | parent |
	~createRevMixView.value(parent, 0, 0, 40/~globalParams.miniatureRatio, ~globalParams.xySliderSize/~globalParams.miniatureRatio, false);
	~createRevdelXY.value(parent, 40/~globalParams.miniatureRatio, 0, ~globalParams.xySliderSize/~globalParams.miniatureRatio, 40/~globalParams.miniatureRatio);
};

// Effects views \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

~createDistMixView = { | parent, x, y, width, height, text = true |
	UserView(parent, Rect(x, y, width, height))
	.background_(Color.green(0.2))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(false)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var distMix = ~channels[~currentChannel].distortionMix,

		distMixMarker = distMix/1; //Divide by the maximum value to map it to the 0-1 range

		// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, width, height));
		Pen.alpha = 1;

		Pen.color = Color.green(0.8);
		// Draw boundaries
		Pen.addRect(Rect(0, 0, width, height));
		Pen.stroke;

		// Draw depth marker
		Pen.color = Color.cyan;
		Pen.addRect(Rect(0, height-(distMixMarker*height)-10, width, 10));
		Pen.fill;

		// Draw strings
		if(text == true) {
		Pen.color = Color.green(0.8);
		Pen.stringAtPoint("Mix: ", 0 @ 5);
		Pen.stringAtPoint(distMix.asString, 5 @ 25);
		Pen.stroke;
		}

	})
	.action_({ var x, y, row, column;

	})
	.mouseDownAction_( { | view, x, y |

	});
};

~createEffectsMini = { | parent |
	~createDistMixView.value(parent, 0, 0, 40/~globalParams.miniatureRatio, ~globalParams.xySliderSize/~globalParams.miniatureRatio, false);
};

// Load sample \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
~createLoadSampleView = { | parent, x, y, width, height, text = true |
	UserView(parent, Rect(x, y, width, height))
	.frameRate_(60)
	.animate_(true)
	.clearOnRefresh_(true)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var numFolders = ~globalParams.sampleFolders.size,
		numSamples = ~globalParams.samples.collect{ |folder| folder.size },
		rowHeight= 30;



		Pen.color = Color.red(0.8);
		// Draw boundaries
		Pen.addRect(Rect(0, 0, width, rowHeight));
		Pen.stroke;

		// Draw folders
		numFolders.do { |i|
			if(i == ~selectedSample[0]) {
					Pen.color = Color.red(0.4); // Draw the selected background with a different color
				} {
					Pen.color = Color.red(0.2);
				};
			Pen.addRect(Rect(width/numFolders*i, 0, width/numFolders, rowHeight));
			Pen.fill;
			Pen.color = Color.red(0.8);
			Pen.addRect(Rect(width/numFolders*i, 0, width/numFolders, rowHeight));
			Pen.stringAtPoint(~globalParams.sampleFolders[i].basename, width/numFolders*i + 5 @ (rowHeight/2 - 8));
			Pen.stroke;
		};

		// Draw files
		~globalParams.samples.do { | sampleList, i |
			sampleList.do { | samplePath, j |
				if(i == ~selectedSample[0] && (j == ~selectedSample[1])) {
					Pen.color = Color.red(0.5); // Draw the selected background with a different color
				} {
					Pen.color = Color.red(0.2);
				};
				Pen.addRect(Rect(width/numFolders*i, rowHeight*(j+1), width/numFolders, rowHeight));
				Pen.fill;
				Pen.color = Color.red(0.9);
				Pen.addRect(Rect(width/numFolders*i, rowHeight*(j+1), width/numFolders, rowHeight));
				Pen.stringAtPoint(samplePath.basename.splitext.at(0), width/numFolders*i + 5 @ ((rowHeight*(j+1)) + (rowHeight/2 - 8)));
				Pen.stroke;
			};
		};

	})
	.action_({ var x, y, row, column;

	})
	.mouseDownAction_( { | view, x, y |

	});
};

//// The mighty SEQUENCER view \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\+
~createSequencerView = { | parent, x, y, width, height, text = true |
	UserView(parent, Rect(x, y, width, height))
	.background_(Color.green(0.2))
	.frameRate_(30)
	.animate_(true)
	.clearOnRefresh_(true)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var size = width,
		matrix = ~channels[~currentChannel].pitchMatrix,
		numRows = matrix.size,
		numCol1 = 4,
		col1Options = ["dur", "speed", "amp", "jump f"],
		durPatterns = ["Pseq", "Prand", "Pxrand", "Pwrand"],
		noteValues = ["Normal", "Triplets", "Quintuplets", "Septuplets"],
		durList = ~channels[~currentChannel].durList,
		numColumns = ~channels[~currentChannel].scale.degrees.size,
		degrees = ~channels[~currentChannel].scale.degrees,
		root = ~channels[~currentChannel].rootNote,
		octave = ~channels[~currentChannel].octave,
		crosshairSize = size/20,
		realX = ~joyX*size,
		realY = ~joyY*size;


		Pen.color = Color.green(0.8);
		// Draw row 1
		numCol1.do {|i|
			Pen.addRect(Rect(size/numCol1*i, 0, size/numCol1*(i+1), size/7));
			if(text == true) {
				Pen.color = Color.green(0.8);
				Pen.stringAtPoint(col1Options[i],
					(size/numCol1*i) @ 5);
			}
		};
		Pen.stroke;

		// What tab are we on?
		switch(~channels[~currentChannel].seqTab)
		{\dur} {
			// Draw the next row, the pattern types
			durPatterns.do { |name, i|
				Pen.addRect(Rect(size/durPatterns.size*i, size/7, size/durPatterns.size, size/7));
				if(text == true) {
					Pen.color = Color.green(0.8);
					Pen.stringAtPoint(name,
						(size/durPatterns.size*i) @ (size/7+5));
				}
			};
			Pen.stroke;
			switch(~channels[~currentChannel].durPattern)
			{\pseq} {
				// Draw permitted note values
				if(text == true) {
					Pen.stringAtPoint("Permitted note values",
						20 @ (size/7*2+2));
				};
				noteValues.do { |name, i|
					if(~channels[~currentChannel].durValues[i] == 1) {
						Pen.color = Color.red(0.3);
						Pen.addRect(Rect(size/durPatterns.size*i, size/7*2 + (size/23), size/durPatterns.size, size/7-(size/23)));
						Pen.fill;
					};
					Pen.color = Color.green(0.8);
					Pen.addRect(Rect(size/durPatterns.size*i, size/7*2 + (size/23), size/durPatterns.size, size/7-(size/23)));
					if(text == true) {
						Pen.stringAtPoint(name,
							(size/durPatterns.size*i) @ (size/7*2+25));
					};
					Pen.stroke;
				};
				// Draw the cells
				durList.do { |dur, i|
					if(~channels[~currentChannel].selectedDur == i) {
						Pen.color = Color.red(0.3);
						Pen.addRect(Rect(size/durList.size*i, size/7*5, size/durList.size, size/7));
						Pen.fill;
					};
					Pen.color = Color.green(0.8);
					Pen.addRect(Rect(size/durList.size*i, size/7*5, size/durList.size, size/7));
					if(text == true) {
						Pen.stringAtPoint(dur.asString,
							(size/durList.size*i) @ (size/7*5+5));
					};
					Pen.stroke;
				};
			};

		};


		// TODO: if ~channels[~currentChannel].selectedDur != -1, don't move crosshair
		if(~channels[~currentChannel].selectedDur != -1) {
			realX = ~staticJoyX*size;
			realY = ~staticJoyY*size;
		};
		// Draw X/Y
		Pen.color = Color.cyan;
		Pen.line((realX - (crosshairSize/2))@realY, (realX + (crosshairSize/2))@realY);
		Pen.line(realX@(realY - (crosshairSize/2)), realX@(realY + (crosshairSize/2)));
		Pen.addArc(realX@realY, crosshairSize/2, pi, 2*pi);
		Pen.addArc(realX@realY, crosshairSize/4, pi, 2*pi);
		Pen.stroke;
	});
};
~createSequencerMini = { | parent |
	~createDistMixView.value(parent, 0, 0, 40/~globalParams.miniatureRatio, ~globalParams.xySliderSize/~globalParams.miniatureRatio, false);
};