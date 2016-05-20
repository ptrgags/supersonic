/*
 * Convenience class for making four sliders to control
 * an ADSR envelope.
 */
ADSRSliders {
    var sliders, labels;

    init { |window, x, y, padding, synth_table|
        var label_names = ['A', 'D', 'S', 'R'];
        var slider_names = [\attack, \decay, \sustain, \release];
        var slider_width = 20;
        var slider_height = 100;
        var text_height = 20;

        //Create the four sliders
        sliders = Array.fill(4, {|i|
            Slider(window, Rect(i * (padding + slider_width) + x, y, slider_width, slider_height));
        });
        sliders.do({|slider, i|
            var setting = slider_names[i];
            slider.value = synth_table.settings[setting];
            slider.action = {
                synth_table.settings[setting] = slider.value;
                synth_table.update;
            };
        });

        //Create the labels
        labels = Array.fill(4, {|i|
            StaticText(window, Rect(
                i * (padding + slider_width) + x, y + slider_height, slider_width, text_height));
        });
        labels.do({|label, i|
            label.align = \center;
            label.string = label_names[i];
        });
    }
}