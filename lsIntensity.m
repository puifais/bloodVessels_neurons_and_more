% lsIntensity.m
% measure change in intensity from linescan

% % % % % % % okay...what the hell is this code suppose to be for...

% create by Puifai on 6/27/2014
% modification history:

close all, clear all
%% user selects a tiff linescan to work on

[fname pname] = uigetfile({'*.tif';'*.TIF';'*.tiff';'*.TIFF'},'select the linescan tiff file');
cd(pname)
openFile = [pname fname];
[fname2 pname2] = uigetfile({'*.lsm'},'select the associated lsm file');
infoFile = [pname2 fname2];
info = lsminfo(infoFile);
imData = double(imread(openFile));

figure(100)
subplot(1,2,1)
imagesc(imData(20*info.DimensionX+1:21*info.DimensionX,1:info.DimensionX))% only show the 20th square lines
colormap('Gray')
title('raw image')
xlim([0 info.DimensionX])
ylim([0 info.DimensionX])
axis image

%% user select ROIs

% process image to help user selection
binTime = 0.1; %in s. 0.05 s is ~the minimum that makes sense. default is 0.1 s
binLine = ceil(binTime/info.DimensionX*info.ScanInfo.PIXEL_TIME{1}*10^6);%PIXEL_TIME in µs/pixel

imAvg = NaN(size(imData));
for i = 1:info.DimensionX
    imAvg(:,i) = smooth(imData(:,i),binLine);
end

figure(100)
subplot(1,2,2)
imagesc(imAvg(20*info.DimensionX+1:21*info.DimensionX,1:info.DimensionX))% only show the 20th square lines
colormap('Gray')
title('vertically smoothed image')
xlim([0 info.DimensionX])
ylim([0 info.DimensionX])
axis image

% user selection
fignum = gcf;
done = 0;
currentFrameNum = 1;
numROI = 0;

fprintf('\npress n to begin ROI selection using the mouse...\n  ')

while not(done)
    waitforbuttonpress
    pressed = get(fignum, 'CurrentCharacter');
    
    if pressed == ' ' % space for done w all ROIs
        done = 1;
        
    elseif pressed == 'n'
        numROI = numROI+1;
        fprintf('\nselect an ROI using the mouse:  ')
        ROI = round(getrect);
        fprintf('good job. got it\n')
        allROI(numROI,:) = ROI;
        
        %draw selection on figure
        subplot(1,2,1)
        rectangle('Position',ROI,'EdgeColor','m');
        text(ROI(1)-7,ROI(2)-7,['\color{magenta}' num2str(numROI)])
        subplot(1,2,2)
    else
        beep
        display ('not a valid key')
    end
end

%% measure intensity

ROIF = nan(length(imAvg),size(allROI,1));
time = info.TimeStamps.TimeStamps; % in s

for i = 1:size(allROI,1)
    % display each ROI intensity profile
    imROI = imAvg(:,allROI(i,1):allROI(i,1)+allROI(i,3)-1);
    figure(i)
    subplot(3,2,1)
    imagesc(imROI(20*info.DimensionX+1:21*info.DimensionX,:))% only show the 20th square lines
    colormap('Gray')
    title(['ROI ' num2str(i)])
    ylim([0 info.DimensionX])
    
    avgProfile = mean(imROI);
    figure(i)
    subplot(3,2,2)
    plot(avgProfile)
    title('avg intensity profile')
    
    %measure total intensity of each line
    for j = 1:length(imROI)
        %not sure if sum or mean is better
        %         ROIF(j,i) = mean(imROI(j,:)); %wipes off more small variations
        %         compared to sum
        ROIF(j,i) = sum(imROI(j,:));
    end
    
    %plot
    figure(i)
    subplot(3,1,2)
    plot(time,ROIF(:,i),'.k')
    title('total intensity')
    ylabel('intensity (a.u.)')
    
    figure(i)
    subplot(3,1,3)
    plot(time,smooth(ROIF(:,i),round(0.05*length(ROIF))),'-b') % 5% smoothing
    title('smoothed')
    xlabel('time (s)')
    ylabel('intensity (a.u.)')
    
end

%% save

save('raw intensity.mat')