/*
This module is tailored for Digilent PmodAD1 and any other circuit using one or two AD7476A ADCs.
https://digilent.com/shop/pmod-ad1-two-12-bit-a-d-inputs/
https://www.analog.com/en/products/ad7476a.html

The module reads data at the maximum supported sampling rate of 1 Msps from one or two AD7476A ADCs connected
in tandem. It means that the CS and SCLK signals are connected to both ADCs (see Digilent PmodAD1 schematics).

The module outputs the data as a continuous AXI-Stream. It doesn't generate AXI-Stream tlast signal.
If required, you need to add the tlast signal downstream.

The input signal second_adc_enabled controls whether data from the second ADC (connected to sdata1 input signal)
are provided in the AXI-Stream.
When second_adc_enabled is asserted, the module first outputs on the AXI-Stream interface data sample read from ADC 0,
then waits for three clock cycles and outputs the data sample from ADC 1.
On data samples from ADC 1, the module sets the most significant bit to 1. This allows a consumer of the AXI-Stream
to distinguish between ADC 0 and ADC 1 data. The AD7476A provides 12-bit values. So, the ADC does not use the MSB.

You must specify two module's parameters:
   - CLK_FREQ is the input clk frequency in Hz. We prefer a frequency that is an even multiple of 20 MHz
     (this allows for a symmetrical SPI SCLK generation).

   - SPI_CLK_DELAY_CYCLES sets a number of clk clock cycles between SPI CS going down and SPI SCLK starting.
     Set the number appropriately to fulfill the AD7476A requirement for a minimum 10 ns CS to SCLK setup time.

BSD 2-Clause License:

Copyright (c) 2025 Viktor Nikolov

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
`timescale 1ns / 1ps

module adc_spi_axis #(
    /* System clock frequency in Hz
       We prefer a frequency that is an even multiple of 20 MHz (this allows for a symmetrical SPI SCLK generation). */
    parameter CLK_FREQ = 120_000_000,   
    /* Number of clk clock cycles between SPI CS going down and SPI SCLK starting.
       Set the number appropriately to fulfill the AD7476A requirement for a minimum 10 ns CS to SCLK setup time. */
    parameter SPI_CLK_DELAY_CYCLES = 3 // 3 cycles at 120 MHz provide CS to SCLK setup time of 25 ns
)(
    input  wire        clk,
    input  wire        rst,         // synchronous active-low reset
    input  wire        second_adc_enabled, // set this signal to high when data from the second ADC 
                                           // shall be provided in the AXI-Stream 
    // SPI interface
    output reg         cs,          // active-low chip select
    output reg         sclk,        // SPI clock (20 MHz)
    input  wire        sdata0,      // SPI serial data input from ADC 0
    input  wire        sdata1,      // SPI serial data input from ADC 1
    // AXI-stream interface
    output reg [15:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready
);

    // Calculate timing parameters in number of clk cycles.
    localparam SAMPLE_PERIOD     = CLK_FREQ / 1_000_000;      // sample period of 1 µs for 1 Msps sampling rate
    localparam SCLK_PERIOD_CYCLES = CLK_FREQ / 20_000_000;    // for 20 MHz SPI clock
    // For an uneven number of CLK cycles in a SPI clock cycle (e.g. 5 cycles at 100MHz), distribute the half period
    localparam SCLK_HALF_UP   = (SCLK_PERIOD_CYCLES + 1) / 2;
    localparam SCLK_HALF_DOWN = SCLK_PERIOD_CYCLES / 2;

    // State machine states
    localparam STATE_IDLE          = 2'd0,
               STATE_SPI_DELAY     = 3'd1,
               STATE_TRANSFER      = 3'd2,
               STATE_OUTPUT_0      = 3'd3,
               STATE_OUTPUT_1_WAIT = 3'd4,
               STATE_OUTPUT_1      = 3'd5;

    reg [2:0] state = STATE_IDLE;

    // Counters
    reg [$clog2(SAMPLE_PERIOD):0] sample_counter = 0;
    reg [$clog2(SPI_CLK_DELAY_CYCLES):0] spi_delay_counter = 0;
    reg [4:0] bit_counter = 0;  // counts 0 to 16 (needs 5 bits)
    reg [4:0] wait_counter = 0; // waiting counter for ADC 1 data output on AXI-Stream interface

    // Shift registers for captured data.
    reg [15:0] data_reg0 = 16'd0;
    reg [15:0] data_reg1 = 16'd0;

    // Counters and flag for generating sclk
    // Use the maximum half-period width.
    localparam HALF_MAX = (SCLK_HALF_UP > SCLK_HALF_DOWN) ? SCLK_HALF_UP : SCLK_HALF_DOWN;
    reg [$clog2(HALF_MAX):0] sclk_counter  = 0;
    reg                      spi_clk_state = 0; // 0: high phase, 1: low phase

    initial begin
        // Initialize the output signals
        cs = 1;   // deassert CS (active low)
        sclk = 1; // idle state of sclk is high
        m_axis_tdata = 16'd0;
        m_axis_tvalid = 0;
    end

    // Main FSM (synchronous)
    always @(posedge clk) begin
        if (~rst) begin
            state           <= STATE_IDLE;
            sample_counter  <= 0;
            spi_delay_counter <= 0;
            bit_counter     <= 0;
            wait_counter    <= 0;
            data_reg0       <= 16'd0;
            data_reg1       <= 16'd0;
            sclk_counter    <= 0;
            spi_clk_state   <= 0;
            cs              <= 1;      // deassert CS (active low)
            sclk            <= 1;      // idle state of sclk is high
            m_axis_tvalid   <= 0;
            m_axis_tdata    <= 16'd0;
        end else begin
            // Counter for the sample period measurement is incremented on each clock cycle
            sample_counter <= sample_counter + 1; 
            
            case (state)
                STATE_IDLE: begin
                    m_axis_tvalid <= 0; // ensure AXI-stream valid is low
                    cs            <= 1; // CS inactive high
                    sclk          <= 1; // sclk idle high
                    // Count clock cycles until sample period elapsed.
                    if (sample_counter == SAMPLE_PERIOD - 1)
                    begin
                        sample_counter <= 0; // Start counting towards next acquisition
                        cs <= 0;             // start SPI transaction: deassert CS (active low)
                        spi_delay_counter <= 0;
                        state <= STATE_SPI_DELAY;
                    end
                end

                STATE_SPI_DELAY: begin
                    /* Wait for the fixed delay of CS to SCLK setup time.
                       The AD7476A requires a minimum of 10 ns. */ 
                    if (spi_delay_counter < SPI_CLK_DELAY_CYCLES - 1)
                        spi_delay_counter <= spi_delay_counter + 1;
                    else begin
                        // After delay, initialize SPI transfer parameters.
                        sclk          <= 1;  // ensure sclk starts high
                        sclk_counter  <= 0;
                        spi_clk_state <= 0;  // start with high phase
                        bit_counter   <= 0;
                        state         <= STATE_TRANSFER;
                    end
                end

                STATE_TRANSFER: begin
                    // Generate 16 SPI clock cycles. Sample sdata on each falling edge.
                    if (spi_clk_state == 0) begin
                        // High phase: wait for SCLK_HALF_UP cycles.
                        if (sclk_counter < SCLK_HALF_UP - 1)
                            sclk_counter <= sclk_counter + 1;
                        else begin
                            sclk_counter <= 0;
                            sclk <= 0; // falling edge occurs now
                            // Sample sdata from ADCs at falling edge; capture MSB first.
                            data_reg0[15 - bit_counter] <= sdata0;
                            data_reg1[15 - bit_counter] <= sdata1;
                            bit_counter <= bit_counter + 1;
                            spi_clk_state <= 1;  // switch to low phase
                        end
                    end else begin
                        // Low phase: wait for SCLK_HALF_DOWN cycles.
                        if (sclk_counter < SCLK_HALF_DOWN - 1)
                            sclk_counter <= sclk_counter + 1;
                        else begin
                            sclk_counter <= 0;
                            sclk <= 1;  // rising edge: return sclk high
                            if (bit_counter == 16)
                                state <= STATE_OUTPUT_0; // finished 16 bits
                            else
                                spi_clk_state <= 0; // next bit: back to high phase
                        end
                    end
                end

                STATE_OUTPUT_0: begin
                    // Output data from ADC 0 on the AXI-Stream interface
                    cs <= 1; // deassert CS after transfer
                    m_axis_tdata <= data_reg0;
                    m_axis_tvalid <= 1;
                    // Wait for handshake from downstream (AXI-Stream tready)
                    if (m_axis_tready) begin
                        // m_axis_tvalid will be set low next clock cycle at the beginning of the next state
                        if( second_adc_enabled )
                            state <= STATE_OUTPUT_1_WAIT;
                        else
                            state <= STATE_IDLE;
                    end
                end

                STATE_OUTPUT_1_WAIT: begin
                    // Wait three clock cycles before output of data from ADC 1 on the AXI-Stream interface
                    m_axis_tvalid <= 0;
                    if( wait_counter < 3 )
                        wait_counter <= wait_counter + 1;
                    else begin
                        wait_counter <= 0;
                        state <= STATE_OUTPUT_1;
                    end
                end

                STATE_OUTPUT_1: begin
                    // Output data from ADC 1 on the AXI-Stream interface
                    /* By setting the most significant bit we indicate that the data sample is from ADC 1.
                       The AD7476A provides 12-bit values. So the MSB is not used by the ADC. */
                    m_axis_tdata <= 16'h8000 | data_reg1;
                    m_axis_tvalid <= 1;
                    // Wait for handshake from downstream (AXI tready)
                    if (m_axis_tready) begin
                        // m_axis_tvalid will be set low next clock cycle at the beginning of the next state
                        state <= STATE_IDLE;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
