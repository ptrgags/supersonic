/*
 * Simple Synth
 *
 * A work-in progress synthesizer with
 * the basic controls used in most synthesizers.
 * There is a GUI to control the synth parameters
 * and eventually MIDI input
 */

s.boot;
s.scope;

//Use this for determining which MIDI input source to use
MIDIClient.init;

//Connect to a MIDI device. Adjust this as needed for your
//input devices.
MIDIIn.connect(0, MIDIClient.sources[0]); //for me this is MIDI Yoke 1
MIDIIn.connect(0, MIDIClient.sources[8]); //for me this is my USB keyboard

(
//Synth parameters
var synth_params = (amp: 0.5, cutoff: 440);

//GUI Window
var window;
//Saw frequency control
var freq_knob, freq_control;
//Low pass filter cutoff control
var cutoff_knob, cutoff_control;
//Master Volume control
var vol_slider, vol_control;
var env_view;

//Active notes array
var active_notes = nil!128;

//Function for releasing MIDI notes
var release_func = {|index|
    if (active_notes[index].notNil) {
        active_notes[index].release;
        active_notes[index] = nil;
    }
};

//Saw -> LPF -> Env (ADSR)
SynthDef(\saw_filter, {
    //Saw Frequency and amplitude, cutoff frequency, envelope gate
    arg freq=440, amp=0.5, cutoff=440, gate=1;

    //Saw oscillator and low pass filter
    var osc, filter, env, env_gen;

    //Generate the Saw tone, adjusting amp and frequency
    osc = amp * Saw.ar(freq);

    //Pass the saw tone through a low pass filter
    filter = LPF.ar(osc, cutoff);

    //ADSR Envelope
    //TODO: Customize this envelope eventually
    env = Env.adsr(0.01, 0.3, 0.5, 0.3);

    env_gen = EnvGen.kr(env, gate, doneAction: 2);

    //Output the sound in stereo
    Out.ar(0, Pan2.ar(filter * env_gen, 0));
}).add;


//Make the GUI window
window = Window("SimpleSynth", Rect(100, 100, 640, 480));

//Make a knob for the filter cutoff frequency
cutoff_knob = Knob(window, Rect(60, 10, 40, 40));
cutoff_control = ControlSpec(20, 20000, \exponential, 10, 440);
cutoff_knob.action = {
    synth_params.cutoff = cutoff_control.map(cutoff_knob.value);
    for(0, 127, {|i|
        if (active_notes[i].notNil) {
            active_notes[i].set(\cutoff, synth_params.cutoff);
        }
    });
};

//Make a slider for controling the volume of the synth
vol_slider = Slider(window, Rect(10, 60, 100, 40));
vol_control = ControlSpec(0, 1);
vol_slider.action = {
    synth_params.amp = vol_control.map(vol_slider.value);
    for(0, 127, {|i|
        if (active_notes[i].notNil) {
            active_notes[i].set(\amp, synth_params.amp);
        }
    });


};

window.front;

//On key press, create a new synth for that note
MIDIIn.noteOn = {
    arg src,chan, midinote, velocity;
    active_notes[midinote] = Synth(\saw_filter,[
        \freq, midinote.midicps,
        \amp, synth_params.amp,
        \cutoff, synth_params.cutoff]);
};

//On key release, release the synth for that note
MIDIIn.noteOff = {|src, chan, midinote, velocity|
    release_func.value(midinote);
};

)

(
//These are useful for visualizing the sound
s.scope;
s.freqscope;
)