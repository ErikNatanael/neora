/////////////// GUI component functions for the Neora sampler instrument \\\\\\\\\\\\\\\\\\\\\\

// Create view functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\

~createEnvelopeView = { | parent, width, height |
	var vi = UserView(parent, Rect(0, 0, width, height));
	vi.background_(Color.green(0.2))
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