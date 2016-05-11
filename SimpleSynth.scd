/*
 * Simple Synth
 *
 * A work-in progress synthesizer with
 * the basic controls used in most synthesizers.
 * There is a GUI to control the synth parameters
 * and eventually MIDI input
 */


(
SynthDef(\saw_filter, {
    arg freq=440, cutoff=440, amp=0.5;
    var osc, filter;
    osc = amp * Saw.ar(freq);
    filter = LPF.ar(osc,cutoff);
    Out.ar(0, Pan2.ar(filter, 0));
}).add;
)

s.boot;

s.scope;

a = Synth(\saw_filter);

(
var window;
var freq_knob, freq_control;
var cutoff_knob, cutoff_control;
var vol_slider, vol_control;

//Make the window
w = Window("Saw + LP Filter", Rect(100, 100, 640, 480));

//Make a knob for the oscillator frequency
freq_knob = Knob(w, Rect(10, 10, 40, 40));
freq_control = ControlSpec(100, 1000);
freq_knob.action = {
    a.set(\freq, freq_control.map(freq_knob.value));
};

//Make a knob for the filter cutoff frequency
cutoff_knob = Knob(w, Rect(60, 10, 40, 40));
cutoff_control = ControlSpec(20, 20000, \exponential, 10, 440);
cutoff_knob.action = {
    a.set(\cutoff, cutoff_control.map(cutoff_knob.value));
};

//Make a slider for controling the volume of the synth
vol_slider = Slider(w, Rect(10, 60, 100, 40));
vol_control = ControlSpec(0, 1);
vol_slider.action = {
    a.set(\amp, vol_control.map(vol_slider.value));
};

w.front;
)