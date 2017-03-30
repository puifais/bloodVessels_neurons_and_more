% freehandIntensity.m

% measure fluorescence intensity from a freehand drawn area
% This program is unlikely to be used a lot since it can handle 1 ROI at a
% time. But it may be necessary for area of low SNR

% create by Puifai on 10/8/2014
% modification history:  
% none

warning('off','all')
close all, clear all
%% user selects a tiff linescan to work on

[fname pname] = uigetfile({'*.tif';'*.TIF';'*.tiff';'*.TIFF'},'select the still video tiff file');
cd(pname)
openFile = [pname fname];
[fname2 pname2] = uigetfile({'*.lsm'},'select the associated lsm file');
infoFile = [pname2 fname2];
info = lsminfo(infoFile);
imData = imread(openFile);

numFrames = info.DimensionTime;
%% z-project the stack using average value then select ROI

info2 = imfinfo(openFile);

if info2(1,1).BitDepth == 16
    zproject = zeros(info2(1,1).Width,info2(1,1).Height,'uint16');
    imData = zeros(info2(1,1).Width,info2(1,1).Height,numFrames,'uint16');
elseif info2(1,1).BitDepth == 8
    zproject = zeros(info2(1,1).Width,info2(1,1).Height,'uint8');
    imData = zeros(info2(1,1).Width,info2(1,1).Height,numFrames,'uint8');
end

fprintf('projecting:  %s \n', fname)

for i = 1:numFrames
    imData(:,:,i) = imread(openFile,i);
end

zproject = mean(imData,3);

figure(1)
subplot(1,2,1)
imagesc(zproject)
% colormap gray
title('average z-projection')
xlim([0 info.DimensionX])
ylim([0 info.DimensionY])
axis image
hold on

fprintf('select the ROI using the mouse. double click when done:  ')
[freeMask freeX freeY] = roipoly;
fprintf('done\n')
drawPolygon([freeX freeY],'lineWidth', 1,'Color','m')

%% calculate fluorescence intensity for each frame

maxTime = 300; %in s. Because recording 10 epochs of 30 s each.
maxFrame = floor(maxTime/info.TimeStamps.AvgStep);
if length(imData) < maxFrame
    maxFrame = length(imData);
end

ROIF = nan(maxFrame,1);

for i=1:maxFrame
    
    fprintf('analyzing:  %s frame %3.0f\n', fname,i)
    imFrame = imData(:,:,i);
        
    % show each frame
    figure(1)
    subplot(1,2,2)
    colormap('default')
    set(gcf,'Name',[' frame ' num2str(i) ' of ' num2str(numFrames)])
    imagesc(imData(:,:,i))
    title('raw image')
    axis image
    
    % store ROIF of each frame
    ROIF(i) = mean(imFrame(freeMask));
end

time = info.TimeStamps.TimeStamps; % in s
%% save

save('raw cellIntensity.mat')

%% plot

%check in case unequal length
    if length(time)>length(ROIF)
        time = time(1:length(ROIF));
    else
        ROIF = ROIF(1:length(time),:);
    end

figure(2)
plot(time,ROIF,'k.',time,smooth(ROIF),'b-')
xlabel('time (s)')
ylabel('fluorescence intensity (a.u.)')
title([num2str(fname) ' (' num2str(numFrames) ' frames)'])

print(figure(1),'-dpdf','ROI')
print(figure(2),'-dpdf','raw freehandIntensity')