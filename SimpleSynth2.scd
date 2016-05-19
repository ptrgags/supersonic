s.boot;
s.scope;
s.freqscope;

//Define the synth on the server
(
//Osc -> LPF -> Env (ADSR)
SynthDef(\simple_synth, {
    //Gate, Osc Frequency and amplitude, cutoff frequency,
    //envelope gate, pitch bend [-1, 1], waveform index {0:Saw, 1:sin
    arg gate=1, freq=440, amp=0.5, cutoff=440, bend=0.0, wave=0;

    //Saw oscillator and low pass filter
    var osc, filter, env, env_gen;
    //pitch calculated from note freq + bend amount
    var pitch = freq + (bend * 100);

    var osc_list = [
        Saw.ar(pitch),
        SinOsc.ar(pitch),
        Pulse.ar(pitch, width: 0.5),
        Pulse.ar(pitch, width: 0.9)
    ];

    //Generate the Saw tone, adjusting amp and frequency
    osc = amp * Select.ar(wave, osc_list);

    //Pass the saw tone through a low pass filter
    filter = LPF.ar(osc, cutoff);

    //ADSR Envelope
    //TODO: Customize this envelope eventually
    env = Env.adsr(0.01, 0.3, 0.5, 0.3);

    env_gen = EnvGen.kr(env, gate, doneAction: 2);

    //Output the sound in stereo
    Out.ar(0, Pan2.ar(filter * env_gen, 0));
}).add;
)

(
var default_settings = (
    freq: 440,
    amp: 0.5,
    cutoff: 440,
    bend: 0.0,
    wave: 0
);
t = SynthTable.new;
t.init(default_settings, \simple_synth);
)

//Run this to set up MIDI input and see what devices are available
MIDIClient.init;

//Connect to a device.
MIDIIn.connect(0, MIDIClient.sources[0]); //for me this is loopMIDI
MIDIIn.connect(0, MIDIClient.sources[1]); //for me this is my USB keyboard

//Run this to set up MIDI callbacks
(
//On key press, create a new synth for that note
MIDIIn.noteOn = {|src, chan, midinote, velocity|
    t.play_note(midinote);
};

MIDIIn.noteOff = {|src, chan, midinote, velocity|
    t.release_note(midinote);
};

//On Pitch bend event, adjust the frequency
MIDIIn.bend = {
    arg src, chan, bend;
    bend.postln;
    t.settings.bend = bend.linlin(-8192, 8191, -1.0, 1.0);
    t.update;
};

MIDIIn.control = {
    arg src, chan, num, val;
    switch(num,
        1, {
            t.settings.cutoff = val.linexp(0, 127, 20, 20000);
            t.update;
        },
        7, {
            t.settings.amp = val.linlin(0, 127, 0, 1.5);
            t.update;
        }
    );
};
)

(
var window;
var wave_menu;

var cutoff_knob, cutoff_control;
var vol_slider, vol_control;

//Make the GUI window
window = Window("SimpleSynth", Rect(100, 100, 640, 480));

//Wave form selected
wave_menu = PopUpMenu(window, Rect(10, 10, 90, 20));
wave_menu.items = ["Saw", "Sine", "Square", "Thin Pulse"];
wave_menu.action = {|menu|
    t.settings.wave = menu.value;
    t.settings.postln;
    t.update;
};

//Make a knob for the filter cutoff frequency
cutoff_knob = Knob(window, Rect(180, 10, 40, 40));
cutoff_control = ControlSpec(20, 20000, \exponential, 10, 440);
cutoff_knob.action = {
    t.settings.cutoff = cutoff_control.map(cutoff_knob.value);
    t.update;
};
cutoff_knob.mode = \vert;

//Make a slider for controling the volume of the synth
vol_slider = Slider(window, Rect(10, 60, 100, 40));
vol_control = ControlSpec(0, 1);
vol_slider.action = {
    t.settings.amp = vol_control.map(vol_slider.value);
    t.update;
};

window.front;
)