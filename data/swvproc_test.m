%% Resetting environment
clc;
clear all;
close all;

%% Global constant configuration
FILENAME = './USPSTAT/17Aug280234PM_Analog.dat';

% Data display switch
DATADISP = 0;

% Data 08/28, 2:34 PM
DATA_START = 6372; % QRE / Clean signal
% Data 08/28, 2:27 PM
%DATA_START = 6968;
% Data 08/27, 3:11 PM
%DATA_START = 11586;%12628;%10544;%
% Data 08/27, 3:03 PM
%DATA_START = 11788;
% Data 08/27, 2:59 PM
%DATA_START = 8861;%4693;

DATA_STOP = DATA_START + 385;

ENDCUT = 12;
CODE_CURRENTZERO = 64;

% Polyfit switch
POLYFIT = 1;

%% Reading data
dataRaw = csvread(FILENAME);

% Break switch
if DATADISP
    plot(dataRaw);
    return
end

dataSWV = - (dataRaw(DATA_START:DATA_STOP)  - CODE_CURRENTZERO)*0.08;
swvForwards = dataSWV(1:2:end);
swvBackwards = dataSWV(2:2:end);

swvDiff = swvForwards - swvBackwards;

%% Filter (LPF)
[coeffB, coeffA] = butter(2,0.1,'low');

swvFiltForwards = filter(coeffB, coeffA, swvForwards(end:-1:1));
swvFiltBackwards = filter(coeffB, coeffA, swvBackwards(end:-1:1));
swvFiltDiff = filter(coeffB, coeffA, swvDiff(end:-1:1));

%% Esw generation
Esw = (-175:3.125:425) - 25;
Esw = Esw(ENDCUT:end);

%% Baseline recovery
if POLYFIT
    FitPoints = [18:30,175:190];
    FitX = Esw(FitPoints-ENDCUT)';
    FitY = swvFiltDiff(FitPoints);

    PGuess = polyfit(FitX,FitY,2);
    BaseGuess = polyval(PGuess,Esw);
end

%% Plotting Data, although they are shitty
figHandle = figure;
set(figHandle, 'Position', [100,100,600,900])
subplot(3,1,1)
plot(Esw,swvForwards(end-ENDCUT+1:-1:1));
hold on;
plot(Esw,swvFiltForwards(ENDCUT:end));
title('SWV - Forward current')
xlabel('Voltage vs. Ag/AgCl (mV)')
ylabel('Current (nA)')
subplot(3,1,2)
plot(Esw,swvBackwards(end-ENDCUT+1:-1:1));
hold on;
plot(Esw,swvFiltBackwards(ENDCUT:end));
title('SWV - Backward current')
xlabel('Voltage vs. Ag/AgCl (mV)')
ylabel('Current (nA)')
subplot(3,1,3)
plot(Esw,swvDiff(end-ENDCUT+1:-1:1));
hold on;
plot(Esw,swvFiltDiff(ENDCUT:end));
if POLYFIT
    plot(Esw,BaseGuess);
end
title('SWV - Current Difference')
xlabel('Voltage vs. Ag/AgCl (mV)')
ylabel('Current (nA)')
