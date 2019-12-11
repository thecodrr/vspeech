<div align="center">
<h1>📣 vSpeech 📜</h1>
<p align="center">
V bindings for <a href="">Mozilla's DeepSpeech</a> <a href="">TensorFlow</a> based library for Speech-to-Text.
</p>
</div>

## Installation:

Install using `vpkg`

```bash
vpkg get https://github.com/thecodrr/vspeech
```

Install using `V`'s builtin `vpm` (you will need to import the module with: `import thecodrr.vspeech` with this method of installation):

```shell
v install thecodrr.vspeech
```

Install using `git`:

```bash
cd path/to/your/project
git clone https://github.com/thecodrr/vspeech
```

You can use [thecodrr.vave](https://github.com/thecodrr/vave) for reading WAV files.

Then in the wherever you want to use it:

```v
import thecodrr.vspeech //OR simply vave depending on how you installed
// Optional
import thecodrr.vave
```

### Manual:

**Perform the following steps:**

1. Download the latest `native_client.<your system>.tar.xz` matching your system from [DeepSpeech's Releases](https://github.com/mozilla/DeepSpeech/releases/tag/v0.6.0).

2. Extract the `.tar.xz` into your project directory in `libs` folder. **It MUST be in the libs folder. If you don't have one, create it and extract into it.**

3. Download `pre-trained` model from [DeepSpeech's Releases](https://github.com/mozilla/DeepSpeech/releases/tag/v0.6.0) (the file named `deepspeech-0.6.0-models.tar.gz`). It's pretty big (1.1G) so make sure you have the space.

4. Extract the model anywhere you like on your system.

5. **Extra:** If you don't have any audio files for testing etc. you can download the samples from [DeepSpeech's Releases](https://github.com/mozilla/DeepSpeech/releases/tag/v0.6.0) (the file named `audio-0.6.0.tar.gz`)

6. When you are done, run this command in your project directory:

   ```
   export LD_LIBRARY_PATH=$PWD/lib/
   ```

And done!

### Automatic:

_// TODO_

I will add a `bash` script for automating this process including the downloading and extracting etc. PRs welcome.

## Usage

```rust
import thecodrr.vspeech
// specify values for use later
const (
    beam_width            = 300
    lm_weight             = 0.75
    valid_word_count_weight = 1.85
)
// create a new model
mut model := vspeech.new("/path/to/the/model.pbmm", 1)

lm := "/path/to/the/lm/file" //its in the models archive
trie := "/path/to/the/trie/file" //its in the models archive
// enable the decoder with language model (this must be called)
model.enable_decoder_with_lm(lm, trie, lm_weight, valid_word_count_weight)

data := byteptr(0)//raw audio samples (use thecodrr.vave module for this)
data_len := 0 //the total length of the buffer
// convert the audio to text
text := model.speech_to_text(data, data_len)
println(text)

// make sure to free everything
unsafe {
    model.free()
    model.free_string(text)
}
```

## API

#### `vspeech.new(model_path, beam_size)`

Creates a new `Model` with the specified `model_path` and `beam_size`.

`beam_size` decides the balance between accuracy and cost. The larger the `beam_size` the more accurate the decoding will be but at the cost of time and resources.

`model_path` is the path to the model file. It is the file with `.pb` extension but it is better to use `.pbmm` file as it is mmapped and is lighter on the RAM.

### Model `struct`

The main `struct` represents the interface to the underlying model. It has the following methods:

#### 1. `enable_decoder_with_lm(lm_path, trie_path, lm_weight, valid_word_count_weight)`

This **must** be called **before any other other method**. Basically it loads the Language Model and enables the decoder to use it. Read the method comments to know what each `param` does.

#### 2. `get_model_sample_rate()`

Use this to get the sample rate expected by the model. The audio samples you need converted **MUST** match this sample rate.

#### 3. `speech_to_text(buffer, buffer_size)`

This is the method that you are looking for. It's where all the magic happens (and also all the bugs).

`buffer` is the audio data that needs to be decoded. Currently DeepSpeech supports 16-bit RAW PCM audio stream at the appropriate sample rate. You can use [thecodrr.vave](https://github.com/thecodrr/vave) to read audio samples from a WAV file.

`buffer_size` is the total number of bytes in the buffer

#### 4. `speech_to_text_with_metadata(buffer, buffer_size)`

Same as `speech_to_text` except this returns a `Metadata` struct that you can use for output analysis etc.

#### 5. `create_stream()`

Create a stream for streaming audio data (from a microphone for example) into the decoder. This, however, isn't an actual stream i.e. there's no seek etc. This will initialize the streaming_state`in your`Model` instance which you can use as mentioned below.

#### 6. `free()`

Free the `Model`

#### 7. `free_string(text)`

Free the `string` the decoder outputted in `speech_to_text`.

### StreamingState

The streaming state is used to handle pseudo-streaming of audio content into the decoder. It exposes the following methods:

#### 1. `feed_audio_content(buffer, buffer_size)`

Use this for feeding multiple chunks of data into the stream continuously.

#### 2. `intermediate_decode()`

You can use this to get the output of the current data in the stream. However, this is quite expensive due to no streaming capabilities in the decoder. Use this only when necessary.

#### 3. `finish_stream()`

Call this when streaming is finished and you want the final output of the whole stream.

#### 4. `finish_stream_with_metadata()`

Same as `finish_stream` but returns a `Metadata` struct which you can use to analyze the output.

#### 5. `free()`

Call this when done to free the captured StreamingState.

### Metadata

**Fields:**

`items` An array of `MetadataItem`s

`num_items` Total number of items in the items array.

`confidence` Approximated confidence value for this transcription

**Methods:**

`get_items()` - Converts the C pointer `MetadataItem` array into V array which you can iterate over normally.

`get_text()` - Helper method to get the combined text from all the `MetadataItem`s outputting the result in one `string`.

`free()` - Free the `Metadata` instance

### MetadataItem

**Fields:**

`character` - The character generated for transcription

`timestep` - Position of the character in units of 20ms

`start_time` - Position of the character in seconds

**Methods:**

`str()` - Combine and output all the data in the `MetadataItem` nicely into a `string`.

### Find this library useful? :heart:

Support it by joining **[stargazers](https://github.com/thecodrr/vspeech/stargazers)** for this repository. :star:or [buy me a cup of coffee](https://ko-fi.com/thecodrr)
And **[follow](https://github.com/thecodrr)** me for my next creations! 🤩

# License

```xml
MIT License

Copyright (c) 2019 Abdullah Atta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
