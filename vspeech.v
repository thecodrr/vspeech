module vspeech

// NOTE: must call `export LD_LIBRARY_PATH=$PWD/lib/` before using this. 
#flag -L $PWD/lib/
#flag -I $PWD/lib/
#flag -ldeepspeech
#include <deepspeech.h>

struct C.ModelState
struct C.StreamingState

// MetadataItem stores each individual character, along with its timing information
struct C.MetadataItem {
	pub:
	character byteptr		// The character generated for transcription
	timestep int			// Position of the character in units of 20ms
	start_time f32			// Position of the character in seconds
}

// Metadata stores the entire CTC output as an array of character metadata objects
struct C.Metadata{
	pub:
	items &MetadataItem		// List of items
	num_items int			// Size of the list of items
	/* Approximated confidence value for this transcription. This is roughly the
   	* sum of the acoustic model logit values for each timestep/character that
   	* contributed to the creation of this transcription.
	*/
	confidence f64 
}

// primary
fn C.DS_CreateModel() int
fn C.DS_EnableDecoderWithLM() int
fn C.DS_GetModelSampleRate() int
fn C.DS_SpeechToText() byteptr
fn C.DS_SpeechToTextWithMetadata() &Metadata

// streaming
fn C.DS_CreateStream() int
fn C.DS_FeedAudioContent()
fn C.DS_IntermediateDecode() byteptr
fn C.DS_FinishStream() byteptr
fn C.DS_FinishStreamWithMetadata() &Metadata

// all functions related to freeing resources
fn C.DS_FreeModel()
fn C.DS_FreeMetadata()
fn C.DS_FreeString()
fn C.DS_FreeStream()

// Model represents a DeepSpeech model
struct Model {
	beam_width          int
	model_path          string
	model_state			&ModelState
	pub:
	streaming_state		&StreamingState
}

// new_model creates a new Model
//
// model_path          The path to the frozen model graph.
// beam_width          The beam width used by the decoder. A larger beam width generates better results at the cost of decoding time.
pub fn new(model_path string, beam_width int) &Model {
	mut model := &Model{
		beam_width:         beam_width
		model_path:         model_path
		model_state: 		C.NULL
		streaming_state: 	C.NULL
	}
	ret := DS_CreateModel(model_path.str, beam_width, &model.model_state)
	if ret > 0 {
		panic("Failed to create Model. Error code: ${ret.str()}")
	}
	return model
}

// free frees the model
pub fn (m &Model) free(){
	C.DS_FreeModel(m.model_state)
}

// free_string frees the speech-to-text string
// 
// text 	the speech-to-text string gotten from DeepSpeech.
pub fn (m &Model) free_string(text string){
	C.DS_FreeString(text.str)
}

// enable_decoder_with_lm enables decoding using beam scoring with a KenLM language model.
//
// lm_path 	        		The path to the language model binary file.
// trie_path 	        	The path to the trie file build from the same vocabulary as the language model binary.
// lm_weight 	        	The weight to give to language model results when scoring.
// valid_word_count_weight 	The weight (bonus) to give to beams when adding a new valid word to the decoding.
pub fn (m mut Model) enable_decoder_with_lm(lm_path, trie_path string, lm_weight, valid_word_count_weight f64) {
	m.lm_enabled = true
	result := DS_EnableDecoderWithLM(m.model_state, lm_path.str, trie_path.str, lm_weight, valid_word_count_weight)
	if result > 0 {
		panic("Failed to enable decoder with language model. Error code: ${result.str()}")
	}
}

// get_model_sample_rate reads the sample rate that was used to produce the model file.
pub fn (m &Model) get_model_sample_rate() int {
	return DS_GetModelSampleRate(m.model_state)
}

// speech_to_text uses the DeepSpeech model to perform Speech-To-Text.
// buffer     A 16-bit, mono raw audio signal at the appropriate sample rate.
// bufferSize The number of samples in the audio signal.
pub fn (m &Model) speech_to_text(buffer byteptr, buffer_size int) string {
	str := C.DS_SpeechToText(m.model_state, buffer, buffer_size)
	if str == C.NULL {
		panic("speech_to_text: error converting audio to text.")
	}
	return string(str)
}

// speech_to_text_with_metadata uses the DeepSpeech model to perform Speech-To-Text and output metadata about the results.
//
// buffer     A 16-bit, mono raw audio signal at the appropriate sample rate.
// buffer_size The number of samples in the audio signal.
pub fn (m &Model) speech_to_text_with_metadata(buffer byteptr, buffer_size int) &Metadata {
	metadata := C.DS_SpeechToTextWithMetadata(m.model_state, buffer, buffer_size)
	if metadata == C.NULL {
		panic("speech_to_text_with_metadata: error converting audio to text.")
	}
	return metadata
}

// create_stream creates a new streaming inference state. The streaming state returned
// by this function can then be passed to feed_audio_content()
// and finish_stream().
pub fn (m &Model) create_stream() {
	ret := C.DS_CreateStream(m.model_state, &m.streaming_state)
	if ret > 0 {
		panic("create_stream: error creating stream.")
	}
}

// feed_audio_content feeds audio samples to an ongoing streaming inference.
// 
// buffer     A 16-bit, mono raw audio signal at the appropriate sample rate.
// buffer_size The number of samples in the audio signal.
pub fn (s &StreamingState) feed_audio_content(buffer byteptr, buffer_size int) {
	C.DS_FeedAudioContent(s, buffer, buffer_size)
}

// intermediate_decode computes the intermediate decoding of an ongoing streaming inference.
// This is an expensive process as the decoder implementation isn't
// currently capable of streaming, so it always starts from the beginning
// of the audio.
pub fn (s &StreamingState) intermediate_decode() string {
	str := C.DS_IntermediateDecode(s)
	if str == C.NULL {
		panic("intermediate_decode: error computing the text from the stream.")
	}
	return string(str)
}

// finish_stream signals the end of an audio signal to an ongoing streaming
// inference, returns the STT result over the whole audio signal.
pub fn (s &StreamingState) finish_stream() string {
	str := C.DS_FinishStream(s)
	if str == C.NULL {
		panic("finish_stream: error finishing the stream.")
	}
	return string(str)
}

// finish_stream_with_metadata signals the end of an audio signal to an ongoing streaming
// inference, returns per-letter metadata.
pub fn (s &StreamingState) finish_stream_with_metadata() &Metadata {
	metadata := C.DS_FinishStreamWithMetadata(s)
	if metadata == C.NULL {
		panic("finish_stream_with_metadata: error finishing the stream.")
	}
	return metadata
}

// free frees the stream.
pub fn (s &StreamingState) free() {
	C.DS_FreeStream(s)
}

// get_items converts the C MetadataItem array to V MetadataItem array
pub fn (m &Metadata) get_items() []MetadataItem {
	mut arr := []MetadataItem
	for i in 0..m.num_items {
		arr << m.items[i]
	}
	return arr
}

// get_text joins all the characters in the Metadata into one string
pub fn (m &Metadata) get_text() string {
	mut str := [`0`].repeat(m.num_items)
	for i in 0..m.num_items {
		str[i] = *m.items[i].character
	}
	return string(byteptr(str.data))
}

// free frees the Metadata
pub fn (m &Metadata) free() {
	C.DS_FreeMetadata(m)
}

// str returns the string representation of the MetadataItem
pub fn (m &MetadataItem) str() string {
	return 'Character: ${m.character}\nTimestep: ${m.timestep}\nStart time: ${m.start_time}\n'
}