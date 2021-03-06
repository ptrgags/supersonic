/*
 * Simple Synth
 *
 * A work-in progress synthesizer with
 * the basic controls used in most synthesizers.
 * There is a GUI to control the synth parameters
 * and eventually MIDI input
 */

s.boot;

//Use this for determining which MIDI input source to use
MIDIClient.init;

//Connect to a MIDI device. Adjust this as needed for your
//input devices.
MIDIIn.connect(0, MIDIClient.sources[0]); //for me this is MIDI Yoke 1
MIDIIn.connect(0, MIDIClient.sources[8]); //for me this is my USB keyboard

(
//Synth parameters
var synth_params = (amp: 0.5, cutoff: 440, bend: 0.0, wave: 0);

//GUI Window
var window;
//Saw frequency control
var freq_knob, freq_control;
//Low pass filter cutoff control
var cutoff_knob, cutoff_control;
//Waveform select
var wave_knob, wave_control;
//Pulse width knob
var pulse_knob;
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
    //Saw Frequency and amplitude, cutoff frequency, envelope gate, pitch bend [-1, 1], waveform index, pulse width
    arg freq=440, amp=0.5, cutoff=440, gate=1, bend=0.0, wave=0;

    //Saw oscillator and low pass filter
    var osc, filter, env, env_gen;
    //pitch calculated from note freq + bend amount
    var pitch = freq + (bend * 100);

    var osc_list = [
        Saw.ar(pitch),
        SinOsc.ar(pitch),
        Pulse.ar(pitch, width: 0.5),
        Pulse.ar(pitch, width: 0.9)];

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
cutoff_knob.mode = \vert;

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

//Make a knob for selecting the wave form
wave_knob = Knob(window, Rect(10, 10, 40, 40));
wave_control = ControlSpec(0, 3, step: 1, default: 0);
wave_knob.action = {
    synth_params.wave = wave_control.map(wave_knob.value);
    for(0, 127, {|i|
        if (active_notes[i].notNil) {
            active_notes[i].set(\wave, synth_params.wave);
        }
    });
};
wave_knob.mode = \vert;

window.front;

//On key press, create a new synth for that note
MIDIIn.noteOn = {
    arg src,chan, midinote, velocity;
    active_notes[midinote] = Synth(\saw_filter,[
        \freq, midinote.midicps,
        \amp, synth_params.amp,
        \cutoff, synth_params.cutoff,
        \bend, synth_params.bend,
        \wave, synth_params.wave]);
};

//On key release, release the synth for that note
MIDIIn.noteOff = {|src, chan, midinote, velocity|
    release_func.value(midinote);
};

//On Pitch bend event, adjust the frequency
MIDIIn.bend = {
    arg src, chan, bend;
    synth_params.bend = bend / 8192 - 1; //Map to -1.0 to 1.0
    for(0, 127, {|i|
        if (active_notes[i].notNil) {
            active_notes[i].set(\bend, synth_params.bend)
        }
    });
};

MIDIIn.control = {
    arg src, chan, num, val;
    switch(num,
        1, {
            synth_params.cutoff = val.linexp(0, 127, 20, 20000);
            for(0, 127, {|i|
                if (active_notes[i].notNil) {
                    active_notes[i].set(\cutoff, synth_params.cutoff);
                }
            });
        },
        7, {
            synth_params.amp = val / 127 * 1.5;
            for(0, 127, {|i|
                if (active_notes[i].notNil) {
                    active_notes[i].set(\amp, synth_params.amp);
                }
            });
        }
    );
};

)

(
//These are useful for visualizing the sound
s.scope;
s.freqscope;
)