'''
This script starts a TCP/IP server (default listening port 65432) and waits for an array of ADC binary data to
be sent from a client.
The script then converts data to voltage and displays them in a chart.

The data are expected to contain uint16 values from a 12-bit ADC. Samples from two ADCs may be
present in the data. If the most significant bit is set in the sample, it's considered to come
from the second ADC (ADC1).

****** IMPORTANT: ******
Set the value of the constant ADCVREF (at the beginning of the script) according to the reference voltage
of the ADC in your circuit.
uint16 ADC sample of value zero is translated to 0 Volts, and a sample of value 0xFFF is translated to ADCVREF Volts.

This script was created for use with the Zynq-7000 FPGA project utilizing AD7476A ADC (Digilent Pmod AD1).

Copyright (c) 2025 Viktor Nikolov

Dependencies:
    numpy
    matplotlib
'''

import socket
import numpy as np
import matplotlib.pyplot as plt
import datetime
import signal
from select import select

ADCVREF = 3.3 # The ADC reference voltage, adjust this based on the voltage in your circuit.
              # uint16 ADC sample of value zero is translated to 0 Volts, and a sample
              # of value 0xFFF is translated to ADCVREF Volts.

def signal_handler(signum, frame):
    # Handler for Ctlr+C signal
    print("\nExecution interrupted by the user. Exiting...")
    exit(1)

def space_separator(num):
    # Format integer with spaces as a thousand separator
    return '{:,}'.format(num).replace(',', ' ')


def process_data(data_bytes, ADCVREF):
    # Process and plot the received ADC data
    data = np.frombuffer(data_bytes, dtype='<u2') # Interpreting received bytes as little-endian uint16
    mask = 0x8000 # The mask of the MSB

    # Separate ADC0 (MSB=0) and ADC1 (MSB=1) and clear MSB for ADC1
    data0 = data[(data & mask) == 0]
    data1 = data[data & mask == mask]
    data1 = data1 & 0x7FFF  # Then clear the MSB. The original 12-bit value from the ADC is left.

    # Convert raw ADC codes (12-bit, 0..0xFFF) to voltages
    data0 = ADCVREF * data0.astype(np.float64) / 0xFFF
    data1 = ADCVREF * data1.astype(np.float64) / 0xFFF

    # Plot
    fig, ax = plt.subplots(figsize=(11.5, 7))
    times0 = np.arange(data0.size) * 0.001  # Time axis is in ms (we assume a 1 Msps sampling)
    ax.plot(times0, data0, marker='.', markersize=2, linestyle='None', label='ADC0')
    if data1.size > 0:
        times1 = np.arange(data1.size) * 0.001
        ax.plot(times1, data1, marker='.', markersize=2, linestyle='None', label='ADC1')

    ax.set_xlabel('time [ms]')
    ax.set_ylabel('voltage [V]')

    # Plot a line of ADC0 data mean value
    mean0 = data0.mean() if data0.size else 0
    ax.axhline(mean0, linestyle='--', label='mean(ADC0)')
    ax.legend(loc='upper right')

    # Title with timestamp and sample count
    nowstr = datetime.datetime.now().strftime('%H:%M:%S')
    samples_str = space_separator(data0.size)
    ax.set_title(f'Trace from ADC (captured at {nowstr})     {samples_str} samples')

    # Print statistics to the console
    print(f"Mean Value ADC0: {mean0:.5f} V")
    print(f"Max  Value ADC0: {data0.max():.5f} V")
    print(f"Min  Value ADC0: {data0.min():.5f} V")
    if data1.size > 0:
        mean1 = data1.mean()
        print(f"Mean Value ADC1: {mean1:.5f} V")
        print(f"Max  Value ADC1: {data1.max():.5f} V")
        print(f"Min  Value ADC1: {data1.min():.5f} V")

    plt.show()


def main():
    HOST = '0.0.0.0' # Binding IP address, 0.0.0.0 means all available interfaces
    PORT = 65432     # Listening port

    signal.signal(signal.SIGINT, signal_handler)  # Set handling of Ctrl+C

    # Create a TCP / IP server socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        # Set the IP socket server
        # Setting SO_REUSEADDR allows us to reuse the same port number immediately after closing the socket
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen(1) # Put the socket into listening mode
        print(f"Listening for data at {HOST}:{PORT}")
        print("Press Ctrl+C to exit")

        while True:  # The outer cycle is for each socket connection, i.e., for each incoming ADC data set
            while True: # This cycle waits for an incoming connection and accepts it
                # We are using "select" because if we called s.accept() directly, it wouldn't be terminated by Ctrl+C
                ready, _, _ = select([s], [], [], 1)  # Check if we have an incoming connection; timeout set to 1 sec
                if ready:
                    conn, addr = s.accept()  # Connection object is returned
                    break  # We have a connection, let's handle incoming data

            print(f"\nGot connection from {addr[0]}:{addr[1]}")
            data_bytes = b'' # Initialize an empty bytes object
            while True:  # Reading data sent by the client via the socket
                try:
                    chunk = conn.recv(4096) # Read data from the connection
                    if chunk:
                        data_bytes += chunk
                    if not chunk:  # Empty data means that the client has disconnected
                        break
                except ConnectionResetError:
                    break
            print(f"    Received data samples: {space_separator( int( len(data_bytes)/2 ) )}")

            if data_bytes:
                process_data(data_bytes, ADCVREF)


if __name__ == '__main__':
    main()
