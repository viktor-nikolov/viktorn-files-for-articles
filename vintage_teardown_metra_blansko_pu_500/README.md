**THIS IS UNDER CONSTRUCTION**

# Vintage Teardown: Metra Blansko PU 500

The [EEVblog Forum](https://www.eevblog.com/forum/index.php) is full of high-precision sophisticated devices. But what about a low-end analog multimeter made in communist Czechoslovakia? Was it any good?

I recently found the PU 500 multimeter in the basement. My father gave it to me sometime in the mid-80s but I didn't really use it. I wasn't into electronics then.

I couldn't find any historical information online. My guess is that the design is from the late 70s or early 80s. It was produced by [Metra Blansko](https://www.metra.cz/en/), which had at that time a monopoly on manufacturing measurement devices in Czechoslovakia. The company still exists, and they [produce analog meters](https://www.metra.cz/en/products/digital-panel-and-switchboard-instruments/) to this day. 

The device was exported to the capitalist West. I know because I found an Anglo-German user guide for PU 500 on [ElektroTanya](https://elektrotanya.com/). I re-uploaded it [here](https://github.com/viktor-nikolov/viktorn-files-for-articles/blob/main/vintage_teardown_metra_blansko_pu_500/metrablansko_pu500_qu500_multimeter_manual.pdf). I guess the production ended in the early 90s (the communist rule in Czechoslovakia ended in November 1989).

I started having electronics as a hobby about six years ago so  I'm used to modern equipment. Therefore, I find the following quirks of this device amusing:

- You have to fiddle with it almost before every use.
  Before turning it on, you zero the needle mechanically by a screw on the movement.
  After you turn it on, you must zero the needle electrically by turning the nob labeled ←0→ (it's the R41, which is connected to the offset voltage null pins of the OpAmp). When resistance measurement is selected, you must short the inputs to be able to do this adjustment.
  Last but not least, before you can start measuring the resistance, you must disconnect the meter to open-circuit and use the nob labeled ←Ω→ to adjust the needle to the ∞ symbol on the scale. **TODO**
- Every voltage measurement range comes with a different internal resistance. I'm used to multimeters having 10 MΩ impedance, so having just 1 MΩ in the 10 V range seems pretty low to me. You need to think about what resistors are in your circuit before you attach a meter with just 1 MΩ.
  The 100 V range has higher internal resistance (10 MΩ) than the 600 V range (6 MΩ) because they couldn't go higher than 10 MΩ and needed a resistor value divisible by 6.
- ![](https://raw.githubusercontent.com/viktor-nikolov/viktorn-files-for-articles/refs/heads/main/vintage_teardown_metra_blansko_pu_500/internal_resistance.png)
- The scale for resistance measurement is logarithmic, so it covers a pretty big range, but you can't get precise readings on the high end of the range.

