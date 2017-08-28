%% Resetting environment
clc;
clear all;
close all;

%% Global constant configuration
FILENAME = './USPSTAT/17Aug270311PM_Analog.dat';

DATA_START = 11586;%12628;%10544;%
DATA_STOP = DATA_START + 385;

ENDCUT = 12;
CODE_CURRENTZERO = 64;

%% Reading data
dataRaw = csvread(FILENAME);

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
FitPoints = [18:80,189,190];
FitX = Esw(FitPoints-ENDCUT)';
FitY = swvFiltDiff(FitPoints);

PGuess = polyfit(FitX,FitY,2);
BaseGuess = polyval(PGuess,Esw);

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
plot(Esw,BaseGuess);
title('SWV - Current Difference')
xlabel('Voltage vs. Ag/AgCl (mV)')
ylabel('Current (nA)')
