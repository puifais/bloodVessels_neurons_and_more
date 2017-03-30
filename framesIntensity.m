% framesIntensity.m
% measure change in fluorescence from still video or stack file

% create by Puifai on 9/12/2013
% modification history:
% 10/29/13 - autocorrect indices of the selected rectangle
% 12/13/13 - changed fluorInt to be mean value rather than sum of all
% pixels
% 04/29/14 - time is now taken from info.TimeStamps.TimeStamps, not
% calculated from pixel time--tested to be different from one another.
% Added capability to select multiple ROIs to be analyzed all at the same
% time
% 06/25/14 - changed the name of fluorInt to ROIF
% 7/10/14 - user selection on the z-projected instead of raw image
% 9/5/14 - added maxTime to end data at end of 10 epochs
% 9/26/14 - save figures as .pdf automatically
% 12/2/14 - plot each ROI in normalized form and save this as PDF
% 02/05/15 - plot each ROI in normalized form from 0 to 1

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

if strcmp(info.ScanInfo.SCAN_MODE,'Plan')
    numFrames = info.DimensionTime;
elseif strcmp(info.ScanInfo.SCAN_MODE,'Stac')
    numFrames = info.DimensionZ;
end
%% user selects ROIs

%show a z-project the stack using average value
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

% show a scrollable stack
currentFrame = imread(openFile,1);

figure(1)
subplot(1,2,2)
imagesc(currentFrame)
colormap gray
title('scrollable frames')
xlim([0 info.DimensionX])
ylim([0 info.DimensionY])
axis image
xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');

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
    elseif pressed == 'f' % forward 1 frame
        if currentFrameNum < numFrames;
            currentFrameNum = currentFrameNum+1;
            currentFrame = imread(openFile,currentFrameNum);
        else
            beep
            display ('no more frames')
        end
        subplot(1,2,2), imagesc(currentFrame);
        title({fname;['frame:', num2str(currentFrameNum),'/', num2str(numFrames)]});
        axis image
        xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
    elseif pressed == 'b' % back 1 frame
        if currentFrameNum > 1
            currentFrameNum = currentFrameNum-1;
            currentFrame = imread(openFile,currentFrameNum);
        else
            beep
            display ('no more frames')
        end
        subplot(1,2,2), imagesc(currentFrame);
        title({fname;['frame:', num2str(currentFrameNum),'/', num2str(numFrames)]});
        axis image
        xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
    elseif pressed == 's' % skip 10 frames forward
        if currentFrameNum+10 <= numFrames;
            currentFrameNum = currentFrameNum+10;
            currentFrame = imread(openFile,currentFrameNum);
        else
            beep
            display ('no more frames')
        end
        subplot(1,2,2), imagesc(currentFrame);
        title({fname;['frame:', num2str(currentFrameNum),'/', num2str(numFrames)]});
        axis image
        xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
    elseif pressed == 'n'
        numROI = numROI+1;
        fprintf('\nselect an ROI using the mouse:  ')
        subplot(1,2,1)
        ROI = round(getrect);
        
        %check if selection is good
        if ROI(1)<1
            ROI(1) = 1;
        end
        if ROI(2)<1
            ROI(2) = 1;
        end
        if ROI(1)+ROI(3)>info.DimensionX
            ROI(3) = info.DimensionX-ROI(1);
        end
        if ROI(2)+ROI(4)>info.DimensionY
            ROI(4) = info.DimensionY-ROI(2);
        end
        if ROI(1)>info.DimensionX || ROI(2)>info.DimensionY
            fprintf('you are intentionally selecting the wrong area!\n\n\nstart over...\n\n\n')
        else
            display('good job. got this ROI')
        end
        
        allROI(numROI,:) = ROI;
        
        %draw selection on figure
        subplot(1,2,1)
        rectangle('Position',ROI,'EdgeColor','m');
        text(ROI(1)-7,ROI(2)-7,['\color{magenta}' num2str(numROI)])
        subplot(1,2,2)
        rectangle('Position',ROI,'EdgeColor','m');
    else
        beep
        display ('not a valid key')
    end
end %loop while not done

%% user can paste their own allROI here if want to
% allROI = [1,1,255,255;125,152,80,82;92,60,26,27;242,75,14,25;143,102,22,22;211,28,26,19;67,190,33,29;3,1,83,89;113,8,34,30;151,3,26,26;50,208,22,16;];


%% calculate fluorescence intensity for each frame

maxTime = 300; %in s. Because recording 10 epochs of 30 s each.
maxFrame = floor(maxTime/info.TimeStamps.AvgStep);
if size(imData,3) < maxFrame
    maxFrame = size(imData,3);
end

ROIF = nan(maxFrame,numROI);

for i=1:maxFrame
    
    fprintf('analyzing:  %s frame %3.0f\n', fname,i)
    % show each frame
    figure(1)
    subplot(1,2,2)
    colormap('default')
    set(gcf,'Name',[' frame ' num2str(i) ' of ' num2str(numFrames)])
    imagesc(imData(:,:,i))
    title('raw image')
    axis image
    
    for j=1:numROI
        ROI = allROI(j,:);
        % store ROIF of each frame
        imROI = imData(round(ROI(2)):round(ROI(2)+ROI(4)),round(ROI(1)):round(ROI(1)+ROI(3)),i);
        ROIF(i,j) = mean(mean(imROI));
        % for manually deleted and inserted blank frames
        if ROIF(i,j) == 0
            ROIF(i,j) = nan;
        end
    end
end
%% plot

if strcmp(info.ScanInfo.SCAN_MODE,'Plan')
    time = info.TimeStamps.TimeStamps; % in s
elseif strcmp(info.ScanInfo.SCAN_MODE,'Stac')
    depth = (1:numFrames)*info.VoxelSizeZ*10^(6);% VoxelSizeZ in m
end

legendROI = cell(numROI,1);
for i = 1:numROI
    legendROI{i} = num2str(i);
end

figure(2)
if strcmp(info.ScanInfo.SCAN_MODE,'Plan')
    
    %check in case unequal length
    if length(time)>length(ROIF)
        time = time(1:length(ROIF));
    else
        ROIF = ROIF(1:length(time),:);
    end
    
    plot(time,ROIF)
    xlabel('time (s)')
    
elseif strcmp(info.ScanInfo.SCAN_MODE,'Stac')
    
    %check in case unequal length
    if length(depth)>length(ROIF)
        depth = depth(1:length(ROIF));
    else
        ROIF = ROIF(1:length(depth),:);
    end
    
    plot(depth,ROIF)
    xlabel('depth (µm)')
end

ylabel('mean fluorescence intensity (a.u.)')
title([num2str(fname) ' (' num2str(numFrames) ' frames)'])
legend(legendROI)

%% save data and pdf
save('raw frameIntensity.mat')
print(figure(1),'-dpdf','ROI')
print(figure(2),'-dpdf','raw frameIntensity')

%% plot each ROI separately, normalized between 0 and 1
for i = 1:numROI
    figNum = ceil(i/6);
    figure(figNum*100)
    subplot(6,1,i-6*(figNum-1))
%     minDisplay = min(ROIF(:,i)./max(ROIF(:,i)));
%     maxDisplay = max(ROIF(:,i)./max(ROIF(:,i)));
    minDisplay = 0;
    maxDisplay = 1;
    if strcmp(info.ScanInfo.SCAN_MODE,'Plan')
%     plot(time,ROIF(:,i)./max(ROIF(:,i)))
    plot(time,(ROIF(:,i)-min(ROIF(:,i)))./(max(ROIF(:,i))-min(ROIF(:,i))))
        axis([0 max(time) minDisplay maxDisplay])
    elseif strcmp(info.ScanInfo.SCAN_MODE,'Stac')
        plot(depth,ROIF(:,i)./max(ROIF(:,i)))
        axis([0 max(depth) minDisplay maxDisplay])   
    end
    ylabel(['ROI ' num2str(i)])
end

for i = 1:figNum
    if strcmp(info.ScanInfo.SCAN_MODE,'Plan')
        subplot(6,1,6),xlabel('time (s)')
    elseif strcmp(info.ScanInfo.SCAN_MODE,'Stac')
        subplot(6,1,6),xlabel('depth (µm)')
    end
    subplot(6,1,1),title('normalized mean fluorescence (a.u.)')
    print(figure(i*100),'-dpdf',['normalized F' num2str(i)])
end