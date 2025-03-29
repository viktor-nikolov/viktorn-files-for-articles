# Rohde & Schwarz oscilloscope waveform

This script reads all available waveform data from an osciloscope and displays them in the chart.

I developed the script for [Rohde & Schwarz RTB2000](https://www.rohde-schwarz.com/cz/products/test-and-measurement/oscilloscopes/rs-rtb2000-oscilloscope_63493-266306.html) oscilloscope, but it will probably work (possibly with minor changes) with other R&S osciloscopes, too.

The script doesn't do any setup of signal capture. You do that manually using the scope's controls before starting the script.  
The script switches the scope to single capture mode and then downloads data of captured waveforms and renders data in the chart. 

The script is able to handle a lot of waveform samples. On my RTB2004, up to 20 million samples per channel can be loaded for one capture.

You set the following parameters at the beginning of the script:

- `visaResource` is the instrument's VISA resource string. Modify it as necessary.
- `channelsToRead` by default contains a list of all four scope's channels. The script will read data from active channels only. Change the value of `channelsToRead` if you don't want to load data from some active channel(s).
- If you define the `movingAverageWindowSize` variable, the script will apply a moving average filter to smooth the acquired waveform data.

The script requires the Instrument Control Toolbox.