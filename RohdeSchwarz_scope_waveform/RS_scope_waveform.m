% This script reads all available waveform data from an osciloscope and displays them in the chart.
% 
% I developed the script for Rohde & Schwarz RTB2000 oscilloscope, but it will probably work (possibly with minor changes)
% with other R&S osciloscopes, too.
% 
% The script doesn't do any setup of signal capture. You do that manually using the scope's controls before starting the script.  
% The script switches the scope to single capture mode and then downloads data of captured waveforms and renders data in the chart. 
% 
% The script is able to handle a lot of waveform samples. On my RTB2004, up to 20 million samples per channel can be loaded for one capture.
% 
% You set the following parameters at the beginning of the script:
% 
%   - visaResource is the instrument's VISA resource string. Modify it as necessary.
%
%   - channelsToRead by default contains a list of all four scope's channels. The script will read data from active channels only.
%     Change the value of channelsToRead if you don't want to load data from some active channel(s).
%
%   - If you define the movingAverageWindowSize variable, the script will apply a moving average filter to smooth the acquired waveform data.
% 
% The script requires the Instrument Control Toolbox.
%
% Copyright (c) 2025 Viktor Nikolov

clear; % Clear the workspace

%%%%%%%%%% Parameters %%%%%%%%%%
visaResource = 'TCPIP::192.168.44.30::INSTR';   % The instrument resource string; modify as necessary
channelsToRead = [ 1 2 3 4 ]; % Oscilloscope channels from which to read data. Only data from active channels will be read.

% Uncomment the next line to apply moving average smoothing to the waveform data:
%movingAverageWindowSize = 20;

%%%%%%%%%%

% Create VISA Connection to the instrument
scp = visadev(visaResource);

% Check capabilities of the instrument
writeline(scp, '*IDN?'); % Get basic identification of the instrument
response = readline(scp);
if ~contains(response, "RTB2002"|"RTB2004")
    warning("This script was tested on a Rohde & Schwarz RTB2000 oscilloscope. It may need changes to run with other instruments.");
end

% Check active channels and remove inactive ones from channelsToRead
chtr = channelsToRead;
channelsToRead = [];
for ch = chtr
    writeline(scp, sprintf('CHANnel%d:STATe?', ch) );  % Get channel status
    status = str2double( readline(scp) );              % Read the result
    if status == 1
        channelsToRead(end+1) = ch;
    end
end

writeline(scp, 'FORM REAL');             % Set real (binary) data format
writeline(scp, 'FORM:BORD LSBF');        % Set little endian byte order

writeline(scp, 'STOP');                  % Stop acquisition because the next command must be executed in stop mode
writeline(scp, 'CHAN:DATA:POINts MAX');  % Set the maximum possible amount of samples to be returned
writeline(scp, 'SING;*WAI');             % Start single acquisition and wait for the command to complete

writeline(scp, 'CHAN:DATA:HEADer?');     % Read header
header = readline(scp);                  % Header data: XStart in s, Xstop in s, record length in samples, 
                                         % number of values per sample interval (usually 1).
% Parse the received header
header = split(header, ',');
startTime   = str2double(header{1});
stopTime    = str2double(header{2});
noOfSamples = str2double(header{3});

data = zeros( length(channelsToRead), noOfSamples ); % Pre-allocate data matrix
for i = 1:length(channelsToRead)
    fprintf( "Transfering data from channel %d\n", channelsToRead(i) );
    writeline(scp, sprintf('CHAN%d:DATA?', channelsToRead(i)) );  % Ask for channel data
    data(i, :) = readbinblock(scp,"single");                      % Read the data
end
disp('Data transfer done');

clear scp;                % Close connection to the instrument

% Smooth the data using a moving average (if requested):
if exist( 'movingAverageWindowSize', 'var' )
    for i = 1:length(channelsToRead)
        data(i,:) = movmean( data(i,:), movingAverageWindowSize );
    end
end

%%%%% Plot the waveforms %%%%%

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
end

% Set time axis units based on scope's horizontal setup
timeDelta = stopTime - startTime;
if timeDelta < 2.5E-6
    timeUnit='ns';
    stopTime  = stopTime*1E9;
    startTime = startTime*1E9;
elseif timeDelta < 2.5E-3
    timeUnit='µs';
    stopTime  = stopTime*1E6;
    startTime = startTime*1E6;
elseif timeDelta < 2.5
    timeUnit='ms';
    stopTime  = stopTime*1E3;
    startTime = startTime*1E3;
else
    timeUnit='s';
end

timeAxis = linspace(startTime,stopTime,noOfSamples);

fig = figure('Position', [580, 340, 1150, 700], 'Name', 'Scope trace'); % Open the figure with fixed size and position
plot( timeAxis, data, '.' );

% Set the chart title
titleStr = sprintf( 'Trace from scope (captured at %s)     %s  samples', string(datetime('now'), 'HH:mm:ss'), spaceSeparator(noOfSamples) );
if exist( 'movingAverageWindowSize', 'var' )
    titleStr = strcat( titleStr, sprintf( '     moving average %d samples', movingAverageWindowSize ) ); 
end
title(titleStr);

xlabel( [ 'Time [' timeUnit ']'] );
ylabel('Measured Voltage [V]');
xlim([startTime, stopTime]);

% Generate and set the legend
legends = strings( 1, length(channelsToRead) );
for i = 1:length(channelsToRead)
    legends(i) = sprintf( 'channel %d', channelsToRead(i) );
end
legend( legends );
