**THIS IS UNDER CONSTRUCTION**

# Vintage Teardown: Metra Blansko PU 500

The [EEVblog Forum](https://www.eevblog.com/forum/index.php) is full of high-precision sophisticated devices. But what about a low-end analog multimeter made in communist Czechoslovakia? Was it any good?

I recently found the PU 500 multimeter in the basement. My father gave it to me sometime in the mid-80s, but I didn't really use it. I wasn't into electronics as a teenager.

<img src="https://raw.githubusercontent.com/viktor-nikolov/viktorn-files-for-articles/refs/heads/main/vintage_teardown_metra_blansko_pu_500/front.jpg"  width="200">

I couldn't find any historical information online. My guess is that the design is from the late 70s or early 80s. It was produced by [Metra Blansko](https://www.metra.cz/en/) (based in the city of [Blansko](https://www.google.com/maps/place/METRA+BLANSKO+Ltd./@49.3718684,16.6425585,17z/data=!4m6!3m5!1s0x47128ebc6196a643:0x7ed6da70ecb49804!8m2!3d49.3715615!4d16.6449085!16s%2Fg%2F1tk4pwr3?entry=ttu&g_ep=EgoyMDI0MTIxMS4wIKXMDSoASAFQAw%3D%3D)), which had, at that time, a monopoly on manufacturing measurement devices in Czechoslovakia. The company still exists, and they [produce analog meters](https://www.metra.cz/en/products/digital-panel-and-switchboard-instruments/) to this day. 

The device was exported to the capitalist West. I know because I found an Anglo-German user guide for PU 500 on [ElektroTanya](https://elektrotanya.com/). I re-uploaded it [here](https://github.com/viktor-nikolov/viktorn-files-for-articles/blob/main/vintage_teardown_metra_blansko_pu_500/metrablansko_pu500_qu500_multimeter_manual.pdf). I guess the production ended in the early 90s (the communist rule in Czechoslovakia ended in November 1989).

I started having electronics as a hobby about six years ago so  I'm used to modern equipment. Therefore, I find the following quirks of this device amusing:

- You have to fiddle with it almost before every use.
  Before turning it on, you zero the needle mechanically by a screw on the movement.
  After you turn it on, you must zero the needle electrically by turning the nob labeled ←0→ (it's the R41, which is connected to the offset voltage null pins of the OpAmp). When resistance measurement is selected, you must short the inputs to be able to do this adjustment.
  Last but not least, before you can start measuring a resistance, you must disconnect the meter to open-circuit and use the nob labeled ←Ω→ to adjust the needle to the ∞ symbol on the scale (it's the R45, which you adjust because the battery's voltage changes over time and there is no voltage regulator on the power rail).
- Every voltage measurement range comes with a different internal resistance. I'm used to multimeters having 10 MΩ impedance, so having just 1 MΩ in the 10 V range seems pretty low to me. You need to think about what resistors are in your circuit before you attach a meter of just 1 MΩ.
  The 100 V range has higher internal resistance (10 MΩ) than the 600 V range (6 MΩ). Apparently, they couldn't go higher than 10 MΩ and needed a resistor value divisible by 6.  
  
  <img src="https://raw.githubusercontent.com/viktor-nikolov/viktorn-files-for-articles/refs/heads/main/vintage_teardown_metra_blansko_pu_500/internal_resistance.png"  width="400">
  
- You connect everything to the two terminals, including lower current measurements. Only 1 A and 10 A ranges have a separate terminal.
  This was a trap for me during testing because I didn't expect I needed to connect the current to the same terminal used for voltage, so my initial "test result" was that 100 mA range measurement doesn't work.
- The only protection is 1 A glass fuse on the main input terminal (you are supposed to connect max 100 mA there).
  There is no protection whatsoever on the 1 A/10 A input terminal! I measured the internal resistance on this input as 37 mΩ so if you by mistake connect the leads to the mains socket, you better have good mains circuit breakers.
  The input pin of the OpAmp is protected against overvoltage by two diodes (D2, D3).
- The scale for resistance measurement is logarithmic, so it covers a pretty big range, but you can't get precise readings on the high end of the range.
- The user guide contains schematics and detailed BOM but doesn't describe the calibration procedure (and there are a lot of trimming pots). 

Here is the schematics that came with my specimen. It slightly differs from the schematics of the [export variant](https://github.com/viktor-nikolov/viktorn-files-for-articles/blob/main/vintage_teardown_metra_blansko_pu_500/metrablansko_pu500_qu500_multimeter_manual.pdf). My variant uses two transistors to generate positive and negative power rails. The export variant uses an OpAmp for that.

<img src="https://raw.githubusercontent.com/viktor-nikolov/viktorn-files-for-articles/refs/heads/main/vintage_teardown_metra_blansko_pu_500/Metra_Blansko_PU_500_schematics.png"  width="310">

  

I guess the circuit design was motivated by the usage of the least number of semiconductors possible.

The heart of the device is a single OpAmp (Tesla MAA 725K), which seems to be a communist copy of Fairchild µA725.
Then there are four diodes, two transistors (for generating ± power rails), and five capacitors (all ceramic). And then there are a lot of resistors.

My understanding is that the principle of the operation is to generate an appropriate amount of current in the coil of the movement. The coil is part of the resistor network connecting the OpAmp output and the inverting input. The rotating knob connects different impedances into this circuit to set five different amplification gains (for AC high ranges, AC low ranges, DC high ranges, DC low ranges, and resistance ranges).
The difference between AC and DC measurements is that for AC, the OpAmp output is rectified by a diode, and a different gain is used. The mechanical inertia of the movement does the "averaging". This is absolutely not true-RMS. The circuit is calibrated for a 50 Hz sine wave.

Declared precision is ±2.5% of the scale.
The device draws 2 mA from the 9 V battery.

I'm not a vintage equipment collector.
**I offer this device for sale (or a donation to a museum).** It needs to be calibrated, but otherwise, it's in very good condition and fully functional (see photos [1](https://raw.githubusercontent.com/viktor-nikolov/viktorn-files-for-articles/refs/heads/main/vintage_teardown_metra_blansko_pu_500/measurement_mains.jpg), [2](https://raw.githubusercontent.com/viktor-nikolov/viktorn-files-for-articles/refs/heads/main/vintage_teardown_metra_blansko_pu_500/measurement_resistance.jpg), [3](https://raw.githubusercontent.com/viktor-nikolov/viktorn-files-for-articles/refs/heads/main/vintage_teardown_metra_blansko_pu_500/measurement_current.jpg)).



TODO: OpAmp can be still bought
