function [epoch, yArr, epochTime, epochY, deltaYy, epochDeltaYy, baseDia, avgChange] = alignEpochs(x,y,ROINum,offTime1,onTime,offTime2)
%alignEpochs.m

%Align velocity, diameter, or fluorescence intensity data of all
%epochs together

%modification history
%12/20/14 - calculate baseline diameter and average %change, too
%2/19/15 - stimulation paradigm from user input
%3/10/15 - calculating median instead of mean traces

%% stimulation paradigm

% offTime1 = 1; %s
% onTime = 2; %s
% offTime2 = 10; %s
epoch = offTime1+onTime+offTime2; %in s

%% put data in convenient form

timeStep = min(diff(x)); %theoretically, this should give the same result as header.TimeStamps.AvgStep;
% fps = 1/header.TimeStamps.AvgStep; %Hz. This is technically line/s for linescanning data, but unused in this analysis
epochTime = 0:timeStep:epoch;% This isn't used when analyzing framescanning data
yArr = nan(floor(max(x)/epoch), numel(epochTime)); %each row is 1 epoch. each column = velocity, diameter, or fluorescence

% create x (time) array for the purpose of matching data points
xArr = nan(size(yArr));

for i = 1:floor(max(x)/epoch)
    xArr(i,:) = 0+epoch*(i-1):timeStep:epoch+epoch*(i-1);
end

% round the values to the appropriate digit place
timeStepStr = num2str(timeStep,'%1.0e'); %velocity=0.0#, LDF = 0.000#, dia and neural = 0.#
digit = 10^str2num(timeStepStr(end));

xArr = round(xArr*digit)/digit;
x = round(x*digit)/digit;
    
    % match y data based on time stamps
    [match, index] = ismember(xArr,x);
    
    for i = 1:floor(max(x)/epoch)%do this for each epoch
        tempIndex = index(i,:); %grab just 1 row to work on
        tempIndex(tempIndex == 0) = []; %delete where there's no match aka index = 0
        yArr(i,match(i,:)) = y(tempIndex,ROINum);
    end
    
    
    %% results
    
    %1. average all epoch together
    epochY = nanmean(yArr);
    
    %2. find change/baseline--did not subtract background; background = mean of 5% lowest pixel values
    y0 = nan(size(yArr,1),1); %vector to hold F0 of each epoch
    
    for i = 1:length(y0)
        y0(i) = nanmean(yArr(i,find(epochTime<offTime1))); %using off time to find F0
    end
    
    y0 = repmat(y0,1,length(yArr));
    deltaYy = (yArr-y0)./y0*100;
    epochDeltaYy = nanmean(deltaYy);
    
    baseDia = nanmean(epochY(epochTime<offTime1));
    avgChange = nanmean(epochDeltaYy(epochTime>=offTime1 & epochTime<(offTime1+onTime)));
    
end