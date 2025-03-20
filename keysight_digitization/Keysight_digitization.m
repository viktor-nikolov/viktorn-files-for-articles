% This script reads a specified amount of samples from Keysight 34465A or 34470A DMM at the
% maximum sampling speed of 50 ksps and displays the data in a chart.
% 
% You must set the number of samples, desired DC voltage range and VISA resource string in
% the parameter's section at the beginning of the script.
% 
% The script requires the Instrument Control Toolbox.
% 
% In principle, the script may also work on cheaper instruments from the 344xxA family, 
% but the commands setting aperture duration and sampling speed must be modified to match the
% performance of these slower instruments.
%
% Copyright (c) 2024 Viktor Nikolov

clear; % Clear workspace

%%%%%%%%%% Parameters %%%%%%%%%%
noOfSamples = 2000;
%%% uncomment one of the statements with the DC range %%%
%range = '100 mV';
%range = '1 V';
range = '10 V';
%range = '100 V';
%range = '1000 V';
visaResource = 'TCPIP0::192.168.44.32::hislip0::INSTR';   % Resource string; modify as necessary

% --- Step 1: Create VISA Connection ---
dmm = visadev(visaResource);

% Check capabilities of the instrument
writeline(dmm, '*IDN?'); % Get basic identification of the instruments
response = readline(dmm);
if ~contains(response, "34465A"|"34470A")
    warning("This script is tailored for Keysight 34465A and 34470A. It may need changes to run with other instruments.");
elseif noOfSamples > 50000
    % Check presense of MEM option, which allows recording of up to 2M of samples
    writeline(dmm, 'SYSTem:LICense:CATalog?'); % Get list of installed options
    response = readline(dmm);
    if ~contains(response, '"MEM"')
        clear dmm;
        error("Without the MEM option installed, digitization is limited to 50000 samples. Decrease the value of variable noOfSamples.");
    end
end

% --- Step 2: Initialize and Configure the Instrument ---
writeline(dmm, '*RST');  % Reset instrument to default settings
writeline(dmm, '*CLS');  % Clears the event registers and the error queue

writeline(dmm, 'DISP:TEXT "Digitizing..."') ;             % Show text on the display
writeline(dmm, 'DISP OFF') ;                              % Disable instrument display to speed up command execution

writeline(dmm, [ 'CONFigure:VOLTage:DC ' range ] );       % Set DC voltage range (disable the auto-range)
writeline(dmm, 'SENSe:VOLTage:DC:ZERO:AUTO OFF');         % Disable autozeroing
writeline(dmm, 'SENSe:VOLTage:DC:APERture 20E-6');        % Set the shortest aperture of 20 µs
writeline(dmm, 'SENSe:VOLTage:DC:IMPedance:AUTO ON');     % Set High-Z input to Auto, so the High-Z will be active whenever possible
writeline(dmm, 'SENSe:VOLTage:DC:NULL:STATe OFF');        % Disable null function of the meter
% Disable statistics computation, trend chart, histogram, limit testing, scaling function and smoothing filter:
writeline(dmm, ':CALCulate:AVER 0;:CALC:TCH 0;:CALC:TRAN:HIST 0;:CALC:LIM 0;:CALC:SCAL 0;:CALC:SMO 0'); 
writeline(dmm, 'TRIGger:DELay:AUTO OFF');                 % Disable automatic determination of trigger delay by the instrument
writeline(dmm, 'TRIGger:DELay 100E-3');                   % Set trigger delay to 100 ms (so we let the measurement stabilize a little before sampling)
writeline(dmm, 'TRIGger:SOURce IMMediate');               % Initiate the trigger as soon as instrument is put to the "wait-for-trigger" state
writeline(dmm, 'TRIGger:COUNt 1');                        % Set one event per trigger
writeline(dmm, 'SAMPle:SOURce TIMer');                    % Set timer mode of sampling: waits for the Trigger Delay and then samples by SAMPle:TIMer interval
writeline(dmm, 'SAMPle:TIMer 20E-6');                     % Set sampling every 20 µs (50 ksps)
writeline(dmm, sprintf('SAMPle:COUNt %d', noOfSamples));  % Set number of recorded noOfSamples
writeline(dmm, 'FORMat:BORDer SWAPped');                  % The least-significant byte (LSB) of each data point is assumed first.
writeline(dmm, 'FORMat:DATA REAL');                       % Set binary format of the data

writeline(dmm, 'INITiate:IMMediate');                     % Initiate the measurement.
writeline(dmm, 'FETCh?');                                 % Wait for the measurement to complete and get the data

% --- Step 3: Read the Data ---

read(dmm, 2, 'uint8');                    % consume characters '#0', which Keysight provides at the beginning of the data
data = read(dmm, noOfSamples, 'double');  % read the binary floats
read(dmm, 1, 'uint8');                    % consume character '\n', which Keysight provides at the end of the data

writeline(dmm, 'DISP:TEXT:CLEAR'); % Clear text from the display
writeline(dmm, 'DISP ON');         % Enable instrument display

% --- Step 4: Close the Connection ---

writeline(dmm, '*RST');          % Reset instrument to default settings
writeline(dmm, 'SYSTem:LOCal');  % Sets the instrument state to local so it can be operated manually
clear dmm;

% --- Step 5: Plot the Data ---

% Set time axis in µs or ms based on number of samples
if noOfSamples <= 100
    timeAxis = 0:20:noOfSamples*20-20;          % [µs] 50 ksps is one sample each 20 µs
    timeUnit='µs';
else
    timeAxis = 0:0.020:noOfSamples*0.020-0.020; % [ms]
    timeUnit='ms';
end

fig=figure('Position', [580, 340, 1150, 700], 'Name', 'Keysight Digitization'); % Open the figure with fixed size and position
plot(timeAxis, data, '.');
xlabel( [ 'Time [' timeUnit ']' ] );
meanValue = mean(data);
yline( mean(data), 'k--', 'mean value', 'LabelHorizontalAlignment', 'left' );
ylabel('Measured Voltage [V]');
title( 'Digitalized Data from Keysight DMM, ' + string(datetime('now'), 'HH:mm:ss') );
grid on;

% Print basic statistics to the command window
fprintf( "Mean Value: %.5f V\n", meanValue );
fprintf( "Max Value:  %.5f V\n", max(data) );
fprintf( "Min Value:  %.5f V\n", min(data) );
