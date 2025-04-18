# AD7476 breakout board

I created a simple breakout board with two [AD7476](https://www.analog.com/en/products/ad7476.html) ADCs and a voltage reference. However, there is no low-pass filter or buffer op-amp. I made the board pin compatible with the Digilent [Pmod AD1](https://digilent.com/reference/pmod/pmodad1/start).

This is a special-purpose board not meant to replace Pmod AD1. The analog inputs to the ADCs are "naked" without any protection, anti-aliasing low-pass filter, or buffer op-amp.  
I needed to test the AD7476 with a test board that already has a buffer and a filter.

The [schematics](https://github.com/viktor-nikolov/viktorn-files-for-articles/blob/main/AD7476_breakout_board/AD7476_breakout_schema_Rev1.1.pdf) is very simple. I just copied it from the AD7476's data sheet and used the 3V voltage reference [REF1930](https://www.ti.com/product/REF1930) recommended there.

Powering the ADC from a voltage reference increases the accuracy. In some of my tests, the AD7476 on the board differed just 1 mV from my 6½ digit multimeter (I used averaging across a lot of samples, of course).

For use on an FPGA, I created [a Verilog module](https://github.com/viktor-nikolov/viktorn-files-for-articles/blob/main/AD7476_breakout_board/adc_spi_axis.v) (compatible with Pmod AD1, my board, or any other circuit using AD7476/AD7476A). This module reads data from the ADCs at a maximum supported sampling rate of 1 Msps and outputs an AXI-Stream.

I successfully tested my breakout board on Zybo Z7 and Arduino Uno (yes, it works with a 5V microcontroller).

I published KiCad 9.0 [design files](https://github.com/viktor-nikolov/viktorn-files-for-articles/blob/main/AD7476_breakout_board/AD7476_Pmod_Rev1.1_KiCad_archive.zip) in my repository, which are ready for manufacture (including assembly) at JLCPCB using the JLCPCB [Fabrication Toolkit](https://github.com/bennymeg/Fabrication-Toolkit) KiCad plugin.
The only reason I used AD7476 instead of [AD7476A](https://www.analog.com/en/products/ad7476a.html) (the chip Pmod AD1 uses) was that AD7476 was in stock in the JLCPCB parts library at the time. The differences between AD7476 and AD7476A are small, though.

Pmod AD1 provides the VCC on the analog input socket. I instead routed a 3V reference voltage there. You can use it to power something with very small current consumption.  
The REF1930 voltage reference can theoretically supply 20 mA, but its voltage will drop. In my measurements, it dropped 80 µV (micro volts) when I drew an additional 3 mA from it and 420 µV when I drew 14 mA from it (on top of ADC's consumption).

