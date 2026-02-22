// AudioWorklet processor for capturing PCM16 audio at 24kHz
// This runs in a separate thread and processes audio in real-time

class PCM16Processor extends AudioWorkletProcessor {
  constructor() {
    super();
    // Target sample rate for OpenAI Realtime API
    this._targetRate = 24000;
    // Accumulation buffer for resampling
    this._buffer = [];
  }

  process(inputs, outputs, parameters) {
    const input = inputs[0];
    if (!input || input.length === 0) return true;

    const channelData = input[0]; // mono channel
    if (!channelData || channelData.length === 0) return true;

    // AudioWorklet runs at the context's sample rate (usually 44100 or 48000)
    // We need to downsample to 24000Hz
    const sourceRate = sampleRate; // global in AudioWorklet scope
    const ratio = sourceRate / this._targetRate;

    // Simple linear interpolation downsampling + float32 to int16 conversion
    for (let i = 0; i < channelData.length; i++) {
      this._buffer.push(channelData[i]);
    }

    // Calculate how many target samples we can produce
    const targetSamples = Math.floor(this._buffer.length / ratio);
    if (targetSamples > 0) {
      const pcm16 = new Int16Array(targetSamples);
      for (let i = 0; i < targetSamples; i++) {
        const srcIdx = i * ratio;
        const idx = Math.floor(srcIdx);
        const frac = srcIdx - idx;

        let sample;
        if (idx + 1 < this._buffer.length) {
          // Linear interpolation
          sample = this._buffer[idx] * (1 - frac) + this._buffer[idx + 1] * frac;
        } else {
          sample = this._buffer[idx] || 0;
        }

        // Clamp to [-1, 1] and convert to int16
        sample = Math.max(-1, Math.min(1, sample));
        pcm16[i] = sample < 0 ? sample * 0x8000 : sample * 0x7FFF;
      }

      // Remove consumed samples from buffer
      const consumed = Math.floor(targetSamples * ratio);
      this._buffer = this._buffer.slice(consumed);

      // Send PCM16 data back to main thread
      this.port.postMessage(pcm16.buffer, [pcm16.buffer]);
    }

    return true;
  }
}

registerProcessor('pcm16-processor', PCM16Processor);
