%{
Author: Harrison Finkbeiner
Python Code authors: Dr. Philip Wenig, John H. Hartman
Date: 04-18-2024
Purpose: Decode Thermo Element ICP Mass Spectrometer dat files.
Saves data into csv file with the same name as the dat file.
%}

% Constants in Hexadecimal
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

newFileName = "";

% Important note: All dat files need to be in same directory.
% Opens dat files and reads the headers

[datFiles,path] = uigetfile('*.dat','MultiSelect', 'on');
if ~iscell(datFiles)
    datFiles = {datFiles};
end

for i = 1:numel(datFiles)

    curFile = datFiles{i}; 

    fileName = fullfile(path,curFile); % Location of a dat file
    [~,name,ext] = fileparts(curFile); % Gets name of dat file without extension
    fileID = fopen(fileName,'r');
    fseek(fileID,16,'bof');
    
    
    %{ File Header %}
    result = fread(fileID, 85,'uint32');  % Read first 85 bytes
    scanIndexOffset = result(34,1); % bytes
    timestamp = result(41,1); % seconds since epoch
    scanIndexSize = result(40,1); % words
   
    header = ["Scan,Time,ACF,"];
    %{ Scan Index %}
    
    % Index values for header 
    % Time Delta from previous scan = 8 
    % Scan index = 10
    % ACF * 64  = 13
    % Time Delta of Previous scan from start of experiment (ms) = 19? 
    % Time Delta of Current scan from start of experiment (ms) = 20? 
    % Time = 22
    % EDAC / 1000 = 32
    % FCF * 256 = 36
    
    curScanOffset = scanIndexOffset + 4;

    if i ~= 1
        output = cell(1,scanIndexSize-1);
    else
        output = cell(1,scanIndexSize);
    end
    

    for ScanIndex = 1:scanIndexSize
    
        % Get to correct offset for each scan.
        fseek(fileID,curScanOffset,'bof');
        curScan = fread(fileID,1,'uint32');
        fseek(fileID,curScan,'bof');
        curScanHeader = fread(fileID,47,'uint32');
        
        % Read information from scan header
        scanNumber = curScanHeader(10,1); % bytes
        time = curScanHeader(22,1);
        ACF = curScanHeader(13,1); 
        FCF = curScanHeader(36,1);
    
        % Loop over the masses for the current scan. Check tag of each 4 byte
        curRow = scanNumber + "," + time + "," + ACF;
        massVal = 1; % checks what mass value is being read

        while 1
            curMass = fread(fileID,1,'uint32');
            tag = bitshift(bitand(curMass,0xF0000000),-28);
            value = bitand(curMass,0x0FFFFFFF);
    
            if tag == TAG_EOS
                curScanOffset = curScanOffset + 4;
                break
            elseif tag == TAG_DATA
                flag = bitshift(bitand(value,0x0F000000),-24);
                datatype = bitshift(bitand(value,0x00F00000),-20);
                exp = bitshift(bitand(value,0x000F0000),-16);
                value = bitand(value,0x0000FFFF);
                value = bitshift(value,exp);
    
                if datatype == ANALOG_DATA
                    %value = ACF * value;
                    curRow = curRow + "," + value + ",";
                    if scanNumber == 1
                         if massVal < 10
                            header = header + "Mass0" + massVal+ "a,,";
                         else
                             header = header + "Mass" + massVal+ "a,,";
                         end
                     end
                elseif datatype == PULSE_DATA
                     curRow = curRow + "," + value ;
                     if scanNumber == 1
                         if massVal < 10
                            header = header + "Mass0" + massVal+ "p,";
                         else
                             header = header + "Mass" + massVal+ "p,";
                         end
                     end
                elseif datatype == FARADAY_DATA
                    %value = FCF * value;
                end
            elseif tag == TAG_EOM
                massVal = massVal + 1;
            end
    
        end
        
        newRow = strip(curRow,'right',',');
        if i == 1
            output{ScanIndex+1} = newRow;
        else
            output{ScanIndex} = newRow;
        end

        % Calculations if needed. 
        % Analog = ACF * DATA * 2^Exponent
        % Faraday = FCF * DATA * 2^Exponent
        % Pulse = DATA * 2^Exponent
    
    
    end
     if i == 1
        output{1} = header;
     end

    output = reshape(output,[],1);
    if i == 1
        name = name + "combined ML.csv";
        newFileName = path+name;
        writecell(output,newFileName,"QuoteStrings","none");
    else
        writecell(output,newFileName,"QuoteStrings","none",'WriteMode','append');
    end
end
disp("Finished writing csv file"); 

fclose all;
