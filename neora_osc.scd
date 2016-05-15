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
			1, { // But the recorded data in the masterChannel buffer
				length = msg[3].postln;
				newBuf = Buffer.alloc(s, s.sampleRate * length, 1);
				Task( {
					s.sync(); //wait for buffer allocation
					~localRecBuffer.copyData(newBuf, numSamples: s.sampleRate * length);
					"Copying buffer data".postln;
					s.sync(); //wait for data copying
					//Add the buffer and the synths playing it to the array for freeing later
					~masterChannel.buffer = newBuf;
					~masterChannel.startPos = 0; // Reset to select the whole file per default
					~masterChannel.endPos = newBuf.numFrames;
					// Write the whole buffer to disk for opening by a SoundFile
					~masterChannel.buffer.write(~recParams.saveFilePath ++ "master" ++ ".wav", "WAV", "int16", numFrames: -1);
					s.sync();
					~masterChannel.soundFile = SoundFile.new;
					~masterChannel.soundFile.openRead(~recParams.saveFilePath ++ "master" ++ ".wav");
					{~masterChannelChanged.value();}.defer;
					// {{PlayBuf.ar(1, ~masterChannel.buffer)*0.5}!2}.play;

				}).play;
			}
		);
}, path: "/tr");

//"recorded/A.wav".resolveRelative
//~recParams.saveFilePath ++ "A.wav"
/*
newBuf = Buffer.alloc(s, s.sampleRate * length, 1);
				Task( {
					s.sync(); //wait for buffer allocation
					~localRecBuffer.copyData(newBuf, numSamples: s.sampleRate * length);
					"Copying buffer data".postln;
					s.sync(); //wait for data copying
					//Add the buffer and the synths playing it to the array for freeing later
					~channels[~currentChannel].buffer = newBuf;
					~channels[~currentChannel].endPos = newBuf.numFrames;
					// Write the whole buffer to disk for opening by a SoundFile
					~channels[~currentChannel].buffer.write(~recParams.saveFilePath ++ ~currentChannel ++ ".wav", "WAV", "int16", numFrames: -1);
					s.sync();
					~channels[~currentChannel].soundFile = SoundFile.new;
					~channels[~currentChannel].soundFile.openRead(~recParams.saveFilePath ++ ~currentChannel ++ ".wav");
					{~changeChannel.value()}.defer;
					{{PlayBuf.ar(1, ~channels[~currentChannel].buffer)*0.5}!2}.play;
					"Synths started".postln;
				}).play;*/