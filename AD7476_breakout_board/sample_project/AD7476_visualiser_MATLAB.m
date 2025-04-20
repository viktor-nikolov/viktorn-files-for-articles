% This script starts a TCP/IP server and waits for an array of ADC binary data to be sent from a client.
% The script then converts data to voltage and displays them in a chart.
% The data are expected to contain uint16 values from a 12-bit ADC. Samples from two ADCs may be
% present in the data. If the most significant bit is set in the sample, it's considered to come
% from the second ADC (ADC1).
% 
% ****** IMPORTANT: ******
% Set the value of variable ADCVref (at the beginning of the script) according to the reference voltage
% of the ADC in your circuit. uint16 ADC sample of value zero is translated to 0 Volts,
% and a sample of value 0xFFF is translated to ADCVref Volts.
% 
% This script was created for use with the Zynq-7000 FPGA project utilizing AD7476A ADC.
%
% This script requires a license for the MATLAB Instrument Control Toolbox.
%
% Copyright (c) 2025 Viktor Nikolov

ADCVref = 3.3;   % The ADC reference voltage, adjust this based on the voltage in your circuit.
                 % uint16 ADC sample of value zero is translated to 0 Volts, and a sample
                 % of value 0xFFF is translated to ADCVref Volts.

port = 65432;    % The listening port for incoming socket connections

clear server; % clear the server (if it is left over from the previous run)
server = tcpserver("0.0.0.0", port); % Create a TCP/IP server that listens on all available interfaces

fprintf( "listening for data at 0.0.0.0:%d\n", port );
fprintf( "press Ctrl+C to exit\n" );

mainLoop( server, ADCVref );

%%%%%%% Definitions of functions %%%%%%%

function mainLoop( server, ADCVref )
    function cleanupFunction() % A cleanup function for when the mainLoop function terminates
        clear server; % We want to clear the server object in case the user terminates by Ctrl+C
    end

    % Create an onCleanup object that calls cleanupFunction when the function ends
    cleanupObj = onCleanup(@cleanupFunction);
    
    while true
        % Wait for data to arrive at the TCP/IP server
        while server.NumBytesAvailable == 0
            pause(0.1); % Wait 100 ms before checking again
        end
        
        fprintf( '\nreceiving data' );
        
        data = [];
        % Read the incoming data (larger incoming data size requires multiple reads)
        while server.NumBytesAvailable > 0
            data = [ data, uint16( read(server, server.NumBytesAvailable / 2, "uint16") ) ]; % Read the available data
            pause(0.015); % Wait 15 ms before checking again so the server can process incoming TCP/IP packets
        end
        
        fprintf( "\n%s data samples received in total\n", spaceSeparator(length(data)) );
        plotData( data, ADCVref );
    end
end % mainLoop()

function plotData( data, ADCVref )
    %%% Sort the data from ADC0 and ADC1 based on value of the MSB %%%
    %%% We expect data samples from ADC1 to have the most significant bit set
    mask = uint16(2^15); % Equivalent to hexadecimal 0x8000
    % Select elements with the most significant bit not set
    data0 = data(bitand(data, mask) == 0);
    % Select elements with the most significant bit set and reset the MSB so the 12-bit ADC value remains
    data1 = bitand( bitcmp(mask), data(bitand(data, mask) > 0) ); 
    
    % Convert raw measurements to voltage
    data0 = ADCVref * double(data0) / double(0xFFF); % We assume AD7476A, which is a 12-bit ADC
    data1 = ADCVref * double(data1) / double(0xFFF);
    
    figure('Position', [580, 340, 1150, 700]); % Open the figure with fixed size and position
    plot(0:.001:length(data0)/1000-.001, data0, '.', 'DisplayName', 'ADC0'); % time axis is in ms (we assume a 1 Msps sampling) 
    
    if ~isempty(data1)
        hold on;   % Keep the first plot
        plot(0:.001:length(data1)/1000-.001, data1, '.', 'DisplayName', 'ADC1'); % time axis is in ms (we assume a 1 Msps sampling) 
        hold off;  % Release the plot hold
    end
    
    ylabel('voltage [V]');
    xlabel('time [ms]');
    % Mark mean value of ADC0 measurements in the chart
    yline( mean(data0), 'k--', 'mean value ADC0', 'LabelHorizontalAlignment', 'left', 'DisplayName', 'mean(ADC0)' );
    % Set the chart title
    titleStr = sprintf( 'Trace from ADC (captured at %s)     %s  samples', string(datetime('now'), 'HH:mm:ss'), spaceSeparator(length(data0)) );
    title(titleStr);

    % Show the legend if two traces are displayed
    if ~isempty(data1)
        legend;
    end 
    
    % Print basic statistics to the command window
    fprintf( "Mean Value ADC0: %.5f V\n", mean(data0) );
    fprintf( "Max  Value ADC0: %.5f V\n", max(data0) );
    fprintf( "Min  Value ADC0: %.5f V\n", min(data0) );
    if ~isempty(data1)
        fprintf( "Mean Value ADC1: %.5f V\n", mean(data1) );
        fprintf( "Max  Value ADC1: %.5f V\n", max(data1) );
        fprintf( "Min  Value ADC1: %.5f V\n", min(data1) );
    end
end % plotData()

% Function for converting integer to string with spaces as thousands separator
function outStr = spaceSeparator(num)
    % Convert the integer to a string without decimals
    s = num2str(num, '%.0f');
    % Reverse the string
    s_rev = fliplr(s);
    % Insert a space after every group of three digits (if more digits follow)
    s_rev = regexprep(s_rev, '(\d{3})(?=\d)', '$1 ');
    % Reverse back to the original order
    outStr = fliplr(s_rev);
end % spaceSeparator()
