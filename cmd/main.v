module main

import (
	thecodrr.vave
	thecodrr.vspeech
	os
	flag
)

const (
	beam_width            = 300
	lm_weight             = 0.75
	valid_word_count_weight = 1.85
)

fn main(){
	mut fp := flag.new_flag_parser(os.args)
	fp.application('vspeech')
	fp.version('v0.0.1')
	fp.description('A simple tool for converting speech to text using DeepSpeech.')
	fp.skip_executable()

	model := fp.string('model', '', "The path to the trained model file.")
	lm := fp.string('lm', '',"The path to the language model binary.")
	trie := fp.string('trie', '',"The path to the trie file.")
	audio := fp.string('audio', '',"The path to the audio file.")
	
	if os.args.len < 5 {
		println(fp.usage())
		return
	}

	mut w := vave.open(audio, "r")
	defer {w.close()}

	data := w.read_raw()
	
	mut m := vspeech.new(model, beam_width)

	m.enable_decoder_with_lm(lm, trie, lm_weight, valid_word_count_weight)

	output := m.speech_to_text_with_metadata(data, w.data_len())
	
	println(output.get_text())

	//free everything
	unsafe {
		free(data)
		m.free()
		output.free()
	}
}
