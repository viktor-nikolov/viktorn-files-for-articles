# Aim-TTi TGF4162/TGF4242 arbitrary waveform upload

The script uploads an arbitrary waveform to the Aim-TTi signal generator.  
It is compatible with Aim-TTi TGF4162 and TGF4242 [signal generators](https://www.aimtti.com/product-category/function-generators/aim-tgf4000), which are capable of storing 8192 samples (16-bit wide) of an arbitrary waveform.

In the parameter's section at the beginning of the script, you must set the VISA resource string and specify which of the four available arbitrary waveform slots you want the waveform to be uploaded to.

Then, at the beginning of the script, utilize MATLAB's capabilities to construct the desired waveform and store it in the array `waveForm` (an array of 8192 int16 elements).  
The code in the script then transforms data in the `waveForm` to the format supported by the instrument and uploads the waveform to the instrument.

The script only stores the waveform in the instrument's memory. Use the instrument's manual controls to select the uploaded arbitrary waveform for signal generation and specify the signal frequency, amplitude, and offset.

The script requires the Instrument Control Toolbox.

