% stimAnalysis.m
% analyze velocity, diameter, Doppler, neural activity over many epochs

% created by Puifai on 10/7/14
% modification history:  
% 10/21/14 - able to take laser doppler signal .mat file manually saved
% from Acq38 program, or from batch conversion using acq2mat.m function
% 12/6/14 - change smoothing for display to 20% of data instead of 10%
% 12/6/14 - use filtered diameter instead of raw
% 2/19/15 - ask user to input stimulation paradigm

close all
clear all

%% user selects .mat file to analyze

[fname1 pname1] = uigetfile({'*.mat'},'select .mat data');
cd(pname1)
openFile1 = [pname1 fname1];
load(openFile1)

if exist('ROIF','var')
    x = time;
    y = ROIF;
    header = info;
    dataType = 'GCaMP fluorescence';
    unit = '(a.u.)';
elseif exist('filtDia','var')
    x = time;
    y = filtDia;
%%%% stop analyzing when motion gets bad
% x = time(1:1425);
% y = dia(1:1425,:);
%%%%
    header = info;
    dataType = 'diameter';
    unit = '(µm)';
elseif exist('velFiltered','var')
    x = timeFiltered;
    y = velFiltered;
    header = info;
    dataType = 'velocity'; %notice it's not speed
    unit = '(mm/s)';
else %this is LDF data
    if exist('acq','var')
        x = 0:acq.hdr.graph.sample_time/1000:length(acq.data)*acq.hdr.graph.sample_time/1000-acq.hdr.graph.sample_time/1000;
        y = acq.data(:,2);
    else
        y = data(:,2);
        x = 0:isi/1000:length(y)*isi/1000-isi/1000;
    end
    dataType = 'Doppler';
    unit = '(a.u.)';
end

%% user inputs stimulation paradigm

prompt = {'Enter offtime1:','Enter ontime:','Enter offtime2:'};
dlg_title = 'Stimulation Paradigm';
num_lines = 1;
def = {'10','10','10'};
stimParadigm = inputdlg(prompt,dlg_title,num_lines,def);
offTime1 = str2double(stimParadigm{1});
onTime = str2double(stimParadigm{2});
offTime2 = str2double(stimParadigm{3});

%% analysis

for j = 1:size(y,2) %run this for each ROI
    ROINum = j;
    
    [epoch, yArr, epochTime, epochY, deltaYy, epochDeltaYy, baseDia, avgChange] = alignEpochs(x,y,ROINum,offTime1,onTime,offTime2);
    %% plot results
    
    figNum = ceil(j/12);
    
    %plot actual value
    minDisplay = min(nanmin(epochY));
    maxDisplay = max(nanmax(epochY));
    
    figure(figNum)
    subplot(3,8,2*j-1-24*(figNum-1))
    plot(epochTime,yArr)
    axis([0 epoch minDisplay maxDisplay])
    set(gca,'XTick', [offTime1,offTime1+onTime,offTime1+onTime+offTime2])

    subplot(3,8,2*j-24*(figNum-1))
    plot(epochTime,epochY,'-g', epochTime,smooth(epochY,round(0.2*numel(epochY))),'b-')%smooth with 20% of data
    axis([0 epoch minDisplay maxDisplay])
    title(['ROI' num2str(j) ' baseline = ' num2str(baseDia,'%0.1f')])
    set(gca,'XTick', [offTime1,offTime1+onTime,offTime1+onTime+offTime2])
    
    %plot change over baseline (i.e. delta y/y)
    minDisplay = min(nanmin(epochDeltaYy));
    maxDisplay = max(nanmax(epochDeltaYy));
    
    figure(figNum*100)
    subplot(3,8,2*j-1-24*(figNum-1))
    plot(epochTime,deltaYy)
    axis([0 epoch minDisplay maxDisplay])
    set(gca,'XTick', [offTime1,offTime1+onTime,offTime1+onTime+offTime2])
    
    subplot(3,8,2*j-24*(figNum-1))
    plot(epochTime,epochDeltaYy,'-g',epochTime,smooth(epochDeltaYy,round(0.2*numel(epochDeltaYy))),'b-')%smooth with 20% of data
    axis([0 epoch minDisplay maxDisplay])
    set(gca,'XTick', [offTime1,offTime1+onTime,offTime1+onTime+offTime2])
    title(['ROI' num2str(j) ' avg %change = ' num2str(avgChange,'%0.1f') '%'])
    
end

%% print results

for i = 1:figNum
    figure(i)
    set(gcf,'name',[dataType ' of each epoch'])
    subplot(3,8,1), ylabel([dataType ' ' unit])
    subplot(3,8,9), ylabel([dataType ' ' unit])
    subplot(3,8,17), ylabel([dataType ' ' unit])
    subplot(3,8,17), xlabel('time (s)')
    subplot(3,8,18), xlabel('time (s)')
    subplot(3,8,19), xlabel('time (s)')
    subplot(3,8,20), xlabel('time (s)')
    subplot(3,8,21), xlabel('time (s)')
    subplot(3,8,22), xlabel('time (s)')
    subplot(3,8,23), xlabel('time (s)')
    subplot(3,8,24), xlabel('time (s)')
    set(gcf,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
    print(gcf,'-dpdf',[dataType num2str(i)])
    
    figure(i*100)
    set(gcf,'name',[dataType ' change/baseline of each epoch'])
    subplot(3,8,1), ylabel([dataType ' % change'])
    subplot(3,8,9), ylabel([dataType ' % change'])
    subplot(3,8,17), ylabel([dataType ' % change'])
    subplot(3,8,17), xlabel('time (s)')
    subplot(3,8,18), xlabel('time (s)')
    subplot(3,8,19), xlabel('time (s)')
    subplot(3,8,20), xlabel('time (s)')
    subplot(3,8,21), xlabel('time (s)')
    subplot(3,8,22), xlabel('time (s)')
    subplot(3,8,23), xlabel('time (s)')
    subplot(3,8,24), xlabel('time (s)')
    set(gcf,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
    print(gcf,'-dpdf',[dataType ' change' num2str(i)])
end

%% save .mat

% save('stimAnalysis.mat')