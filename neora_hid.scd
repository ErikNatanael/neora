///////////////////// HID Joystick code for the Neora Sampler instrument \\\\\\\\\\\\\\\\\\\\\\\
// Remember to set hidraw permissions first on Linux. Instructions in HID permissions help file
HID.findAvailable; // Run to initialise HID before opening a device
HID.postAvailable;
~myhid = HID.open( 1103, 45320 ); // Should be cross platform compatible for this joystick Thrustmaster, T.Flight Hotas X

HID.debug = true;

~myhid.postElements
~myhid.postInputElements
~myhid.postOutputElements
~myhid.postUsages
~myhid.close;


s.boot; // boot the server

Ndef( \sinewave, { |freq=500, amp=0.1| SinOsc.ar( freq, 0, amp * 0.2 ) } );
Ndef( \sinewave ).play;

~freqRange = [500, 5000, \exponential].asSpec; // create a frequency range

HIDdef.usageID( \freq, { |value| Ndef( \sinewave ).set( \freq, ~freqRange.map( value ) ); }, 48, 1 ); // X axis
HIDdef.element( \amp, { |value| Ndef( \sinewave ).set( \amp, value ); }, 17, "T.Flight Hotas X"); // Y axis

~myhid.elements.at(15).action = { |value| Ndef( \sinewave ).set( \freq, ~freqRange.map( value ) ); }; // X axis