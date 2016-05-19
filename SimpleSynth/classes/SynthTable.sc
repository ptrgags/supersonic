SynthTable {
    var note_table, <>settings, <>synth;

    init {|default_settings, synth_name|
        note_table = nil!128;
        settings = default_settings;
        synth = synth_name
    }

    update {
        for(0, 127, {|i|
            if (note_table[i].notNil) {
                settings.keysValuesDo{|key, value|
                    note_table[i].set(key, value);
                };
            }
        });
    }

    play_note {|index|
        //Make sure the old UGen is disposed if there is one
        this.release_note(index);
        note_table[index] = Synth(synth, settings.asKeyValuePairs);
        note_table[index].set(\freq, index.midicps);
    }

    release_note {|index|
        //Delete a UGen if it exists for this note
        if (note_table[index].notNil) {
            note_table[index].release;
            note_table[index] = nil;
        }
    }
}