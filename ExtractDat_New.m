% Notes:
% Use swapByte function to swap byte order if needed

% untSMPABC001.dat


% Constants
TAG_DATA = 0x1; % Intensity Data
TAG_MASS = 0x2; % Magnet Mass
TAG_TIME = 0x3; % Channel time
TAG_VOLT = 0x4; % Accelerating voltage
TAG_EOM = 0x8; % End of Mass
TAG_B = 0xB; % ??
TAG_BSCAN = 0xC; % B scan
TAG_EOS = 0xF; % End of scan

ANALOG_DATA = 0x0; % Analog data type
PULSE_DATA = 0x1; % Pulse data type
FARADAY_DATA = 0x8; % Faraday data type


[file,path] = uigetfile('*.dat');
[path,name,ext] = fileparts(file); % Gets name of dat file without extension
fileName = fullfile(path,file);
fileID = fopen(fileName,'r');
fseek(fileID,16,'bof');
% Have to skip first 4 bytes to match with how python code works and then
% only need 85 words
result = fread(fileID, 85,'uint32');  
test = dec2bin(result);
test2 = dec2hex(result);
%{ File Header %}
% Use the result(row,col) to set the variables to be used later
Index_Len = dec2hex(result(40,1),8); % Just for testing
TIMESTAMP = dec2hex(result(41,1),8); % Just for testing
OFFSET = dec2hex(result(34,1),8); % Just for testing

scanIndexOffset = result(34,1); % bytes
timestamp = result(41,1); % seconds since epoch
scanIndexSize = result(40,1); % words

%{ Scan Index %}
header = ["Scan,Time,ACF,Mass01p,Mass01a,,Mass02p,Mass02a,,Mass03p,Mass03a,,Mass04p,Mass04a,,Mass05p,Mass05a,,Mass06p,Mass06a,,Mass07p,Mass07a"];
% Create a string for headers and seperate by name
% Create an array of strings for each line of data
%fseek(fileID,scanIndexOffset+4,'bof'); % Might need to add 4 to skip the unsed first 4 bytes
%{ Use as example to build strings 
% testData = "1,1699207891,4616,2247,0,,226,32,,197,0,,26,0,,201,0,,403,0,,40,0";
% [header;testData]
%}

% Scan index is at 10 in the variable. 
% Time Delta from previous scan is at 8 
% Scan index = 10
% ACF * 64  = 13
% Time Delta of Previous scan from start of experiment (ms) = 19? 
% Time Delta of Current scan from start of experiment (ms) = 20? 
% EDAC / 1000 = 32
% FCF * 256 = 36


% Verified data from example scans
% Scan = 10
% Time = 22
% ACF = 13
% FCF = 36 ??

%TODO REMOVE
% Loops over all the scans 
%{
firstScan = fread(fileID, 1,'uint32');  % Add 4 to current scanIndexOffset after each loop
fseek(fileID,firstScan,'bof');
scanHeader = fread(fileID, 47,'uint32');  % Add 4 to current scanIndexOffset after each loop
disp(header);

fseek(fileID,scanIndexOffset+8,'bof'); % Might need to add 4 to skip the unsed first 4 bytes
secondScan = fread(fileID, 1,'uint32');  % Add 4 to current scanIndexOffset after each loop
fseek(fileID,secondScan,'bof');
scantwoHeader = fread(fileID, 47,'uint32');  % Add 4 to current scanIndexOffset after each loop

fseek(fileID,scanIndexOffset+12,'bof'); % Might need to add 4 to skip the unsed first 4 bytes
thirdScan = fread(fileID, 1,'uint32');  % Add 4 to current scanIndexOffset after each loop
fseek(fileID,thirdScan,'bof');
scanthreeHeader = fread(fileID, 47,'uint32');  % Add 4 to current scanIndexOffset after each loop

%}
curScanOffset = scanIndexOffset + 4;
output = {}; % alloc memory for array
output{end+1} = header;
for ScanIndex = 1:scanIndexSize
    % Get to correct offset for each scan.
    fseek(fileID,curScanOffset,'bof');
    curScan = fread(fileID,1,'uint32');
    fseek(fileID,curScan,'bof');
    curScanHeader = fread(fileID,47,'uint32');
    fprintf("Current Scan Index is %d\n", ScanIndex);
    % Read information from scan header
    scanNumber = curScanHeader(10,1); % bytes
    time = curScanHeader(22,1);
    ACF = curScanHeader(13,1); 
    FCF = curScanHeader(36,1);

    % Loop over the masses for the current scan. Check tag of each 4 byte
    curRow = scanNumber + "," + time + "," + ACF;
    while 1
        curMass = fread(fileID,1,'uint32');
        tag = bitsra(bitand(curMass,0xF0000000),28);
        value = bitand(curMass,0x0FFFFFFF);
        if tag == TAG_EOS
            curScanOffset = curScanOffset + 4;
            break
        elseif tag == TAG_DATA
            flag = bitsra(bitand(value,0x0F000000),24);
            datatype = bitsra(bitand(value,0x00F00000),20);
            exp = bitsra(bitand(value,0x000F0000),16);
            value = bitand(value,0x0000FFFF);
            
            value = bitshift(value,exp);
            if datatype == ANALOG_DATA
                %value = ACF * value;
             %   fprintf("Analog");
              %  disp(value);
                curRow = curRow + "," + value + ",";
            elseif datatype == PULSE_DATA
                %    fprintf("Pulse");
                 %  disp(value);
                 curRow = curRow + "," + value ;
            elseif datatype == FARADAY_DATA
                %value = FCF * value;
                disp
            end
            %curRow = curRow + ",";

        end

    end
    disp(curRow);
    newRow = strip(curRow,'right',',');
    output{end+1} = newRow;
    % Analog = ACF * DATA * 2^Exponent
    % Faraday = FCF * DATA * 2^Exponent
    % Pulse = DATA * 2^Exponent


    %fprintf("Reading scanIndex %d\n",scanIndex);

end
output = reshape(output,[],1);
name = name + ".csv";
writecell(output,name,"QuoteStrings","none");


fclose all;
