% The script uploads an arbitrary waveform to the Aim-TTi signal generator.  
% It is compatible with Aim-TTi TGF4162 and TGF4242 signal generators, which are capable of storing 8192 samples
% (16-bit wide) of an arbitrary waveform.
% https://www.aimtti.com/product-category/function-generators/aim-tgf4000
%
% In the parameter's section at the beginning of the script, you must set the VISA resource string and specify
% which of the four available arbitrary waveform slots you want the waveform to be uploaded to.
%
% Then, at the beginning of the script, utilize MATLAB's capabilities to construct the desired waveform and store 
% it in the array `waveForm` (an array of 8192 int16 elements).  
% The code in the script then transforms data in the `waveForm` to the format supported by the instrument and uploads
% the waveform to the instrument.
%
% The script only stores the waveform in the instrument's memory. Use the instrument's manual controls to select
% the uploaded arbitrary waveform for signal generation and specify the signal frequency, amplitude, and offset.
%
% The script requires the Instrument Control Toolbox.%
%
% Copyright (c) 2025 Viktor Nikolov

clear; % Clear the workspace

%%%%%%%%%% Parameters %%%%%%%%%%
visaResource = 'TCPIP::192.168.44.39::9221::SOCKET';   % The instrument resource string; modify as necessary
arbNumber = 1;         % Set to value 1..4 to select upload of ARB1, ARB2, ARB3 or ARB4
arbName = 'MATLAB';    % Set a name of the arbitrary waveform to be shown on the instrument.
                       % The four arbitrary waveforms must have unique names!

waveFormSize = 256*32; % == 8192, i.e. max. amount of arbitrary waveform samples supported by TGF4162/TGF4242 instruments

%%%%%%% Define the waveform: %%%%%%%
% The waveForm must be an int16 array waveFormSize long.
% It must contain one period of the desired function.

%%% Sample waveform based on sine function: %%%
% x = linspace(0, 2*pi, waveFormSize);
% waveForm = 32767 * ( max( min(sin(x),0.75),-0.25 )+0.05*sin(200*x) );

%%% Sample waveform of a step function: %%%
% Define the 20 step values: 10 steps up, 10 steps down
steps = [linspace(-32767,32767,10) linspace(32767,-32767,10)];
% Create an x-axis vector of 8192 points
x = 1:8192;
% Define the original x positions of 20 steps (evenly spaced along 1 to 8192)
xi = linspace(1, 8192, numel(steps));
% Use 1-D data interpolation with the 'previous' method to spread the steps horizontally
waveForm = interp1(xi, steps, x, 'previous');

%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convert the waveform from double to int16:
waveForm = int16( round(waveForm) );

% Plot the waveform:
fig = figure('Name', 'Arbitrary waveform');
plot( waveForm );
xlim([0, waveFormSize]);
ylim([-32768,32767]);
fig.CurrentAxes.YAxis.Exponent = 3;

% Create VISA Connection to the instrument
sigg = visadev(visaResource);

% Check capabilities of the instrument
writeline(sigg, '*IDN?'); % Get basic identification of the instrument
response = readline(sigg);
if ~contains(response, "TGF4162"|"TGF4242")
    warning("This script is tailored for Aim-TTi TGF4162 and TGF4242 16bit instruments. It needs changes to run with other instruments.");
end

writeline(sigg, sprintf('ARBDEF ARB%d,%s,OFF', arbNumber, arbName));     % Set waveform name, set linear interpolation to off
writeline(sigg, sprintf('ARBRESIZE ARB%d,%d', arbNumber, waveFormSize)); % Set size of the waveform

% Transform the waveform to binary data, which the instrument accepts:
waveFormForInstr = uint16(zeros(1,waveFormSize)); % Pre-allocate the array to the size
for i = 1:waveFormSize
    if waveForm(i) >= 0
        waveFormForInstr(i) = uint16(waveForm(i)); % Positive values are just copied
    else
        % We must transform negative values to two's complement uint16 representation
        v = uint16( abs(waveForm(i)) );
        waveFormForInstr(i) = bitcmp(v) + 1; % Compute two's complement
    end
end

% The instrument expects big-endian int16 but on the PC it's stored as little-endian, so we must swap the bytes
% before we send data to the instrument. Because of this, we previously converted int16 values to uint16 two's complements.
waveFormForInstr = swapbytes(waveFormForInstr);

% Construct the IEEE 488.2 header string, which specifies the lenght of binary data
waveFormSizeStr = num2str(waveFormSize*2);     % Convert the waveform data size to a string (waveFormSize * size of uint16)
N = length(waveFormSizeStr);                   % Determine the number of digits in waveFormSizeStr
ieeeHeader = ['#' num2str(N) waveFormSizeStr]; % Construct the IEEE 488.2 header string

write(sigg, 'ARB' + string(arbNumber) + ' ' + ieeeHeader,'string'); % Start the command for uploading the waveform to the instrument

% Send binary data of the waveform to the instrument in chunks of 256 values
for i = 1:(waveFormSize/256)
    write(sigg, waveFormForInstr( (256*(i-1)+1):(256*i) ), 'uint16');
    % The instrument needs 40 ms to process 256 data points. If we send next piece of data too early, the instrument will hang
    % and become unresponsive.
    pause(0.040); % Pause for 40 ms
end

writeline(sigg, 'LOCAL');  % Sets the instrument state to local mode so it can be operated manually
clear sigg;                % Close connection to the instrument
