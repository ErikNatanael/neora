/* OSC responders for the joystick sampler project */
/* Requires the following variables:
~localRecBuffer - A buffer for recording data
~chan1Buffer    - This is where the buffer data for the first buffer is stored

*/

OSCdef.new(\recResponder,
	{ |msg, time, addr, recvPort|
		var length, newBuf, timeLostStart, timeLostEnd;
		msg.postln;
		//msg is in format [path, synthNode, id, time] where time is the message
		switch(msg[2], //switch based on the id sent
			1, { //normal buffer with grain
				length = msg[3].postln;
				newBuf = Buffer.alloc(s, s.sampleRate * length, 1);
				Task( {
					s.sync(); //wait for buffer allocation
					~localRecBuffer.copyData(newBuf, numSamples: s.sampleRate * length);
					"Copying buffer data".postln;
					s.sync(); //wait for data copying
					//Add the buffer and the synths playing it to the array for freeing later
					~channel1.buffer = newBuf;
					~channel1.end = newBuf.numFrames;
					// Write the whole buffer to disk for opening by a SoundFile
					~channel1.buffer.write(~recParams.saveFilePath ++ "A.wav", "WAV", "int16", numFrames: -1);
					s.sync();
					f = SoundFile.new;
					f.openRead(~recParams.saveFilePath ++ "A.wav");
					~setGUISoundFile.value(f);
					~channel1.soundFile = f;
					{{PlayBuf.ar(1, f.asBuffer)*0.5}!2}.play;
					"Synths started".postln;
				}).play;
			}
		);
}, path: "/tr");

//"recorded/A.wav".resolveRelative
//~recParams.saveFilePath ++ "A.wav"