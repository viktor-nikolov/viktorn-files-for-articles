# Keysight 34465A and 34470A DMM fast digitization

This script reads a specified amount of samples from Keysight [34465A](https://www.keysight.com/us/en/product/34465A/digital-multimeter-6-5-digit-truevolt-dmm.html) or [34470A](https://www.keysight.com/us/en/product/34470A/digital-multimeter-7-5-digit-truevolt-dmm.html) DMM at the maximum sampling speed of 50 ksps and displays the data in a chart.  
It provides the same results as the Keysight PathWave BenchVue Digital Multimeter app but works much faster and loads data directly into the MATLAB.

You must set the number of samples, desired DC voltage range and VISA resource string in the parameter's section at the beginning of the script. 

The script requires the Instrument Control Toolbox.

In principle, the script may also work on cheaper instruments from the [344xxA family](https://www.keysight.com/us/en/products/digital-multimeters-dmm/truevolt-series-multimeters.html), but the commands setting aperture duration and sampling speed must be modified to match the performance of these slower instruments.