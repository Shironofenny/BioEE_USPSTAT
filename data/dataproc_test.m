%% dataproc_test
% Temporary data processing script to analyze data recorded from USPSTAT V2.718

% Reset environment
clc; 
clear all; 
close all;

%% Global variables
G_FILENAME = './USPSTAT/17Aug230149PM_Data.dat';
DATA_START = 90000;
VM = 0.25;
BIT_MAX_LENGTH = 12;
BIT_HALF_LENGTH = 4;
BIT_FULL_LENGTH = 8;
FRAME_MAX_NBIT = 15;

%% Reading data
dataAcq = csvread(G_FILENAME);

%dataUsed = dataAcq(DATA_START:95000);
dataUsed = dataAcq(DATA_START:end);
dataProc = zeros(size(dataUsed));

dataProc(dataUsed > VM) = 1;
dataProc(dataUsed < VM) = 0;

length = size(dataProc,1);

%% Semi-realtime processing
% For! Yes, for! This is a test playgroud like script for real time
% analysis. So for is in fact better, since the ultimate script won't be in
% Matlab.

% Initialization of states
% This is basically a state machine
procState = 1;
index = 2;
timeRegistered = 0;

protocolCount = 0;

frameTimeGuess = 0;
frameTime = [];

bitGuess = zeros(1,9);

analogOut = [];
% States and their meanings:
% 1   : Initialization, stay in this state until the first negative edge is
%       reached 
% 2,3 : Wait until reaching a confident guess of a frame starting (four
%       consequent 1's)
% 4   : The part getting processed is supposed to be a full framed data
while index <= length
    switch procState
        case 1,
            if (dataProc(index) < dataProc(index-1))
                timeRegistered = index;
                frameTimeGuess = index;
                procState = 2;
            end
        case 2,
            if (dataProc(index) == 1)
                protocolCount = protocolCount + 1;
                if (protocolCount == 4)
                    procState = 4;
                    protocolCount = 0;
                    %timeRegistered = index;
                else
                    procState = 3;
                end
            end
        case 3,
            if (dataProc(index) == 0)
                timeDiff = index - timeRegistered;
                if (timeDiff < BIT_MAX_LENGTH)
                    procState = 2;
                    timeRegistered = index;
                else
                    protocolCount = 0;
                    procState = 2;
                    timeRegistered = index;
                    frameTimeGuess = index;
                end
            end
        case 4,
            if (dataProc(index) == 0)
                timeDiff = index - timeRegistered;
                nHalfBits = round(double(timeDiff) / BIT_HALF_LENGTH);
                if (mod(nHalfBits, 2) == 1)
                    disp(['Possibly bad frame at ', num2str(frameTimeGuess)]);
                    nBits = (nHalfBits - 1) / 2;
                else
                    nBits = nHalfBits / 2;
                end
                bitGuess(nBits) = 1;
                procState = 5;
            end
            if ((index - frameTimeGuess) > BIT_FULL_LENGTH * FRAME_MAX_NBIT)
                procState = 1;
                if (mod(sum(bitGuess), 2) ~= 0)
                    disp(['Parity check failed at ', num2str(frameTimeGuess)]);
                end
                analogOut = [analogOut; bi2de(bitGuess(1:8), 'left-msb')];
                frameTime = [frameTime; frameTimeGuess];
                bitGuess = zeros(1,9);
            end
        case 5,
            if (dataProc(index) == 1)
                procState = 4;
            end
        otherwise,
    end
    index = index + 1;  
end

%plot(dataProc);