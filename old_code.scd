envelopeEditor = UserView(envelopeView, Rect(60, 40, ~globalParams.envelopeEditorWidth, ~globalParams.envelopeEditorHeight))
	.background_(Color.green(0.2))
	.frameRate_(20)
	.animate_(true)
	.clearOnRefresh_(true)
	.drawFunc_( { // Relies on ~joyX and ~joyY
		var width = ~globalParams.envelopeEditorWidth,
		height = ~globalParams.envelopeEditorHeight,
		nodes = List[],
		ovalSize = 15,
		activeNode;

		nodes = nodes.add(
			(width * ~channels[~currentChannel].attackTimeRatio) @
			(height - (height * ~channels[~currentChannel].attackLevel))
		);
		nodes = nodes.add(
			(width * (~channels[~currentChannel].sustainTimeRatio + ~channels[~currentChannel].attackTimeRatio)) @
			(height - (height * ~channels[~currentChannel].sustainLevel)) // Y = 0 is in the upper corner
		);

		// Draw lines between nodes
		Pen.color = Color.green(0.8);
		Pen.moveTo(0@height);
		nodes.do {|node| Pen.lineTo(node) };
		Pen.lineTo(width@height);
		Pen.stroke;

		// Draw nodes
		Pen.color = Color.cyan;
		nodes.do { |point| Pen.fillOval(Rect(point.x - (ovalSize/2), point.y - (ovalSize/2), ovalSize, ovalSize)); };

		// Draw the active node in a different color
		activeNode = nodes[~channels[~currentChannel].activeEnvelopeNode];
		Pen.color = Color.red;
		Pen.fillOval(Rect(activeNode.x - (ovalSize/2), activeNode.y - (ovalSize/2), ovalSize, ovalSize));

		/*// Draw semitransparent rectangle
		Pen.color = Color.green(0.2);
		Pen.alpha = 0.3;
		Pen.fillRect(Rect(0, 0, size, size));
		Pen.alpha = 1;*/
	});