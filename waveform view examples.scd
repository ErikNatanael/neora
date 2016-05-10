
s = Server.local.boot;
///           SOUNDFILEVIEW
///
( // make a simple SoundFileView
y = Window.screenBounds.height - 120;
w = Window.new("soundfile test", Rect(200, y, 740, 100)).alwaysOnTop_(true);
w.front;
a = SoundFileView.new(w, Rect(20,20, 700, 60));

f = SoundFile.new;
f.openRead(Platform.resourceDir +/+ "sounds/a11wlk01.wav");
// f.inspect;

a.soundfile = f;            // set soundfile
a.read(0, f.numFrames);     // read in the entire file.
a.refresh;                  // refresh to display the file.
)

// In Qt GUI:
// To zoom in/out: Shift + right-click + mouse-up/down
// To scroll: right-click + mouse-left/right

// reading file
a.read(0, f.numFrames / 2).refresh; // read first half
a.read.refresh;                     // read entire file by default
a.read(f.numFrames / 2).refresh;    // read second half
a.read(0, -1).refresh;              // -1 also reads entire file, like buffer.

// In Qt GUI, the resolution of the view is always infinite;
// you can always zoom in until you see a single sample.

// In other GUI kits, 'block' sets the resolution of the view (default is 64).
// i.e. the view keeps peak values for each block of e.g. 64 samples
// rather than the entire waveform.
a.read(0, -1, block: 32).refresh;
a.read(0, -1, block: 24).refresh;
a.read(0, -1, block: 16).refresh;

// for longer files, you can use:
a.readWithTask;

// zoom is relative
a.zoom(0.2).refresh;
a.zoom(2).refresh;
a.zoom(0.9).refresh;
a.zoomToFrac(0.5); // zoom to half file size
a.zoomAllOut;

a.gridOn = true;            // time grid, 1 second by default,
a.gridOn = false;
a.gridResolution = 0.2;     // or set resolution in seconds
a.gridColor = Color.cyan;   // color is changeable.
a.gridOffset_(2.5);         // not sure if this is working?

a.timeCursorOn = true;          // a settable cursor
a.timeCursorPosition = 2050;    // position is in frames.
a.timeCursorColor = Color.red;

// toggle drawing on/off
a.drawsWaveForm = false;
a.drawsWaveForm = true;

// these methods should return view properties:
a.gridOn
a.gridResolution
a.gridColor
a.timeCursorOn
a.timeCursorPosition
a.timeCursorColor

// Selections: multiple selections are supported.
// e.g. use selection 0:
a.setSelectionColor(0, Color.red);  // set...( index, value )
a.selectionStart(0);                // at index
a.setSelectionStart(0, 12345);
a.setSelectionSize(0, 12345);

a.setSelectionStart(0, 1234);
a.selectionStart(0);

// now selection 1
a.setSelectionColor(1, Color.white);
a.setSelectionStart(1, 1234).setSelectionSize(1, 1234 * 2);
a.selectionStart(1);
a.setSelectionStart(0, 12345);

// the current selection gets changed when click/dragging in view.
a.currentSelection;     // index of current selection;
a.currentSelection_(1); // switch current selection - try click/drag white now.
a.currentSelection;

a.selections.size;      // 64 selections
a.selections[0];
a.selections[1];
a.selections;

// setSelection (index, selection);
a.setSelection(0, [234, 2345]);
a.selection(1); // returns [start, size].


a.elasticMode = true;   // not sure if this is working yet?

(       // mouseUpAction
a.mouseUpAction = {
    ("mouseUp, current selection is now:"
        + a.selections[a.currentSelection]).postln;
};
)
// lock selection 0:
a.currentSelection_(0);
a.setEditableSelectionStart(0, false);
a.setEditableSelectionSize(0, false);


// unlock selection 0:
a.setEditableSelectionStart(0, true);
a.setEditableSelectionSize(0, true);

a.selectionStartTime(0);
a.selectionDuration(0);


a.setSelectionStart(0, 12345);
a.setSelectionSize(0, 12345);
a.readSelection.refresh;
a.readSelection(16).refresh;    // in higher resolution
a.read.refresh;                 // go back to entire file.


a.dataNumSamples;   // visual data have this many points
a.data.plot;
a.setData(a.data.reverse);


a.zoom(0.25);       // scrolling is normalized
a.scrollTo(0.5);    //
a.scrollTo(0.6);    //
a.scroll(0.1);       // scroll is in viewFrames.

a.zoom(4);

w.close;

////// BUFFER SLICING CODE
https://github.com/DarienBrito/NLC-System-/blob/master/BufferUtilities/NLC_BufDivide.sc



/// MORE SOUNDFILEVIEW

(
    var fPlay, fStop, synth, cursorRout, ggPlay, ggStop;

    f = nil;
    w = Window( "Soundfile View", Rect( 300, 300, 770, 270 ));

    fStop = {
        synth.free; synth = nil;
        cursorRout.stop; cursorRout = nil;
        ggPlay.states = [[ "Play" ]];
    };

    fPlay = {
            var buf, f0, startPos;
            fStop.value;
                startPos = a.timeCursorPosition ? 0;
            fork {
                    f0 = f;
                    if( f0.notNil && s.serverRunning, {
                        buf = Buffer.cueSoundFile( s, f0.path, startPos, f0.numChannels );
                        s.sync;
                        synth = { arg bus, buf;
                               Out.ar( bus, VDiskIn.ar( f.numChannels, buf, BufRateScale.kr( buf ), loop: 1 ));
                        }.play( args: [ \bus, 0, \buf, buf.bufnum ]);
                    cursorRout = fork { inf.do({ arg i;
                                    { a.timeCursorPosition = (((i * 0.03) * f0.sampleRate).asInteger + startPos) % f0.numFrames }.defer;
                                        0.03.wait;
                        })};
                        { ggPlay.states = [[ "Play", Color.white, Color.blue ]]}.defer;
                    });
            };
    };

    ggPlay = Button( w, Rect( 20, 10, 40, 20 ))
        .states_([[ "Play" ]])
        .canFocus_( false )
        .action_( fPlay );

    ggStop = Button( w, Rect( 64, 10, 40, 20 ))
        .states_([[ "Stop" ]])
        .canFocus_( false )
        .action_( fStop );

    StaticText( w, Rect( 120, 10, 40, 20 ))
        .align_( \right )
        .string_( "Path:" );
    x = DragSink( w, Rect( 170, 10, 550, 20 ))
        .resize_( 2 )
        .action_({ arg b;
            if( f.notNil, { f.close; f = nil; });
            f = SoundFile.new;
            f.openRead( b.object );
//            GUI.useID( \swing, { f.inspect });
            a.soundfile         = f;
            a.gridOn            = false;
            y.lo                = 0;
            y.hi                = 1;
            a.readWithTask( 0, f.numFrames, doneAction: { arg b;
                a.gridResolution = (b.soundfile.numFrames / (b.soundfile.sampleRate * 16)).max( 0.1 );
                a.gridOn        = true;
            });
        // a.read( 0, f.numFrames ); // warning...
        });
    Button( w, Rect( 730, 10, 20, 20 ))
        .resize_( 3 )
        .states_([[ "..." ]])
        .action_({ arg b;
            Dialog.openPanel({ arg path;
                { x.object = path;
                  x.doAction }.defer;
            });
        });

    a = SoundFileView( w, Rect( 20, 40, 700, 180 ))
        .resize_( 5 );

    a.elasticMode       = 1;

    a.timeCursorOn      = true;
    a.timeCursorColor   = Color.red;
// a.timeCursorPosition = 2500;

    y = RangeSlider( w, Rect( 20, 230, 700, 20 ))
        .resize_( 8 )
        .action_({ arg b;
            a.zoomToFrac( b.range.max( a.bounds.width / a.numFrames.max( 1 )));
            if( b.range < 1, { a.scrollTo( b.lo / (1 - b.range) )}); // stupid scrollTo definition
        });

    Slider( w, Rect( 730, 40, 20, 180 ))
        .resize_( 6 )
        .value_( 0.5 )
        .action_({ arg b;
            a.yZoom = b.value.linexp( 0, 1, 0.02, 50.0 );
        });

    w.onClose = fStop;
    w.front;
)

////////////////////////////////////////////////////
(
s.options.memSize_(65536 * 2);
s.reboot;

Spec.add(\t60, [0.1, 60, \exp]);
Spec.add(\damp, [0, 1]);
Spec.add(\size, [0.5, 3]);
Spec.add(\earlydiff, [0, 1]);
Spec.add(\mdepth, [0, 50]);
Spec.add(\mfreq, [0, 10]);
Spec.add(\lowx, [0, 1]);
Spec.add(\midx, [0, 1]);
Spec.add(\highx, [0, 1]);
Spec.add(\lowband, [100, 6000, \exp]);
Spec.add(\highband, [1000, 10000, \exp]);
)


Ndef(\src).clear
(
Ndef(\src, {
    //SoundIn.ar([0, 1])
    Splay.ar(Impulse.ar([1, 3, 5, 7, 9]).scramble);
});

Ndef(\reverb, {
    var src = Ndef(\src).ar * \amp.kr(1);
    src = JPverb.ar(
        src,
        \t60.kr(1,           0.05),
        \damp.kr(0,          0.05),
        \size.kr(1,          0.05),
        \earlydiff.kr(0.707, 0.05),
        \mdepth.kr(5,        0.05),
        \mfreq.kr(2,         0.05),
        \lowx.kr(1,          0.05),
        \midx.kr(1,          0.05),
        \highx.kr(1,         0.05),
        \lowband.kr(500,     0.05),
        \highband.kr(2000,   0.05)
    );
});
)
{Saw.ar(440, 0.5)}.play;
(
Ndef(\src, {
	Splay.ar(Saw.ar([435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445].scramble, 0.05)*
		EnvGen.kr(Env([0, 0, 1, 0], [0.0001, 0.1, 0.5], loopNode:1), Impulse.ar(0.5)));
});
)
(
Ndef(\src, {
	Splay.ar(Saw.ar([435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445].scramble*TRand.kr(0.8, 1.4, Impulse.kr(0.5)), 0.05)*
		EnvGen.kr(Env.perc, Impulse.kr(0.5)));
});
)


Ndef(\reverb).fadeTime = 1;
Ndef(\reverb).play
Ndef(\src).play


Ndef('reverb').set('lowx', 0.84375, 'amp', 0.66015625, 'damp', 0.671875, 'size', 0.94921875, 'highband', 4450.794062356, 't60', 16, 'mdepth', 17.96875, 'mfreq', 0.0, 'highx', 0.0, 'lowband', 2450.0822520097, 'earlydiff', 0.421875, 'midx', 0.5546875);

// Dreamverb
Ndef('reverb').set('wet', 0.9921875, 'lowx', 0.84375, 'amp', 0.66015625, 'damp', 0.31443298969072, 'size', 2.7938144329897, 'highband', 1024.0219794048, 't60', 60, 'mdepth', 4.639175257732, 'highx', 0.0, 'mfreq', 0.10309278350515, 'lowband', 2450.0822520097, 'fadeTime', 1, 'earlydiff', 0.421875, 'midx', 0.70618556701031);


Ndef('reverb').set('lowx', 0.84375, 'amp', 0.66015625, 'damp', 0.671875, 'size', 0.94921875, 'highband', 4450.794062356, 't60', 60, 'mdepth', 17.96875, 'mfreq', 0.0, 'highx', 0.0, 'lowband', 2450.0822520097, 'earlydiff', 0.421875, 'midx', 0.5546875);

Ndef('reverb').set('lowx', 0.609375, 'amp', 0.38092041015625, 'damp', 0.2890625, 'size', 0.6171875, 'highband', 7233.9416273667, 't60', 4.0375572334984, 'mdepth', 0.0, 'mfreq', 2.03125, 'highx', 0.2265625, 'lowband', 681.56675509913, 'fadeTime', 1, 'earlydiff', 0.765625, 'midx', 0.515625);

Ndef('reverb').set('lowx', 0.84375, 'amp', 0.66015625, 'damp', 0.875, 'size', 0.5, 'highband', 5829.4153471361, 't60', 0.16483258382257, 'mdepth', 17.96875, 'mfreq', 0.0, 'highx', 0.0, 'lowband', 100.0, 'fadeTime', 1, 'earlydiff', 0.703125, 'midx', 0.5546875);


Ndef(\src).edit
Ndef(\reverb).edit;