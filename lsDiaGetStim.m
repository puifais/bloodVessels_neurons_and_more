% lsDia.m
% measure change in diameter from linescan perpendicular to a vessel.
% Threshold the gray scale image. Then sum up horizontal line to
% calculate diameter

% create by Puifai on 7/16/2013
% modification history:
% 9/5/13 - threshold using gray scale image. 15% of the difference between
% darkest and brightest above baseline is consider to be vascular lumen
% 6/26/14 - change time to come from info.TimeStamps.TimeStamps. Calculate
% diameter by detecting first and last edges that passes the intensity
% threshold.Added multiple ROI selection
% 7/10/14 - user selection on the z-projected instead of raw image
% 9/2/14 - noticed that was analyzing from averaged image. Changed to raw
% image but take winSize at a time. Also added maxTime and maxLines parameter to cap the
% end of data especially for stimulation
% 9/26/14 - save figures as .pdf automatically
% 11/19/15 - ask user to manually select an ROI or use the entire image.
% Make 10% temporal smoothing the default. Also find threshold based on
% each winSize.
% 2/14/16 lsDiaGetStim.m created by Brandon
% 2/14/16 Added the function of being able to choose the type of
% stimulation, manual, auto, or none. Automatic stimulation assumes 1 off 2
% on 10 off (13sec epoch) 
% 2/16/16 Changed final printed pdf to "ROIFinal" and the ROI selection as
% "ROISelect"


% if you get the warning, "TIFF library error: 'TIFFFillStrip: Invalid
% strip byte count 0, strip 1.'.  The image data may be corrupt." and it
% annoys you, turn it off. Here's how:
warning('off','all')
% or try this:
% w = warning('query','last');
% id = w.identifier;
% warning('off',id)

close all, clear variables
%% user selects a tiff linescan to work on

[fname, pname] = uigetfile({'*.tif';'*.TIF';'*.tiff';'*.TIFF'},'select the linescan tiff file');
cd(pname)
openFile = [pname fname];
[fname2, pname2] = uigetfile({'*.lsm'},'select the associated lsm file');
infoFile = [pname2 fname2];
info = lsminfo(infoFile);
imData = double(imread(openFile));

time = info.TimeStamps.TimeStamps; % in s

fprintf('processing:  %s \n',openFile)

figure(100)
subplot(1,2,1)
imagesc(imData(20*info.DimensionX+1:21*info.DimensionX,1:info.DimensionX))% only show the 20th square lines
xlabel('pixels')
ylabel('pixels')

colormap('Gray')
title('raw image')
xlim([0 info.DimensionX]) 
ylim([0 info.DimensionX])% showing equal amount of pixel as in x-direction
axis image

%% user select ROIs

% process image to help user selection
epoch = 13;
binTime = 0.1*epoch; %in s. default is 10% of an epoch
binLine = round(binTime/info.DimensionX*info.ScanInfo.PIXEL_TIME{1}*10^6);%PIXEL_TIME in µs/pixel
if mod(binLine,2) == 0 %check if it's an odd number
    binLine = binLine+1; %if not an odd number, add 1
end

imAvg = NaN(size(imData));
for i = 1:info.DimensionX
    imAvg(:,i) = smooth(imData(:,i),binLine);
end

figure(100)
subplot(1,2,2)
imagesc(imAvg(20*info.DimensionX+1:21*info.DimensionX,1:info.DimensionX))% only show the 20th square lines maybe #,1
colormap('Gray')
title('vertically smoothed image')
xlim([0 info.DimensionX]) %
ylim([0 info.DimensionX])% showing equal amount of pixel as in x-direction
axis image
xlabel('pixels')
ylabel('pixels')

% user selection
fignum = gcf;
done = 0;
currentFrameNum = 1;
numROI = 0;

fprintf('\npress n to begin ROI selection using the mouse...\n  ')
fprintf('\npress spacebar to choose the entire FOV, or when done...\n  ')

while not(done)
    waitforbuttonpress
    pressed = get(fignum, 'CurrentCharacter');
    
    if pressed == ' ' % space for done w all ROIs
        done = 1;
        if numROI == 0 % i.e. user decides to use the whole image, rather than selecting an ROI
            numROI = 1;
            allROI(numROI,:) = [1 1 info.DimensionX 999]; %999 doesn't get used. Just a place holder
        end
    elseif pressed == 'n'
        numROI = numROI+1;
        fprintf('\nselect an ROI using the mouse:  ')
        subplot(1,2,1)
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

%% analysis parameters
winTimeDown = 0.1; %s. default is 0.1 s, which means get 1 datapoint every 0.1 s
winPixelsDown = round(winTimeDown/info.TimeStamps.AvgStep);
if mod(winPixelsDown,2) ~= 0 %check if it's an even number
    winPixelsDown = winPixelsDown+1; %if not an even number, add 1
end
winSize = binLine;%odd number only, please
maxTime = max(info.TimeStamps.TimeStamps); %in s. Because recording 10 epochs of 13 s each.
maxLine = maxTime/info.TimeStamps.AvgStep;
if length(imData) < maxLine
    maxLine = length(imData);
end

%% measure diameter and plot

dia = nan(length(imAvg),size(allROI,1)); % this means there will be at least 1 nan left in dia after this program
% dia = nan(length(imAvg),size(allROI,1));
% time = (1:info.DimensionTime)*info.ScanInfo.PIXEL_TIME{1}*10^(-6)*info.DimensionX; % PIXEL_TIME in µs/pixel
 
 
for i = 1:size(allROI,1)
    % display each ROI intensity profile
    imROI = imData(1:maxLine,allROI(i,1):allROI(i,1)+allROI(i,3)-1);
    figure(i)
    subplot(3,2,1)
    imagesc(imROI(20*info.DimensionX+1:21*info.DimensionX,:))% only show the 20th square lines
%     colormap('Gray')
    title(['ROI ' num2str(i)])
    xlim([0 info.DimensionX])
    ylim([0 info.DimensionX])
    xlabel('pixels')
    ylabel('pixels')
    
    avgProfile = mean(imROI);
    figure(i)
    subplot(3,2,2)
    plot(avgProfile)
    title('avg intensity profile')
    xlim([0 info.DimensionX])
    ylabel('arbitrary unit (a.u.)')
    xlabel('pixels')
   
    %measure diameter
    setThreshold = 0.15;% set at 15% because old paper did this
    
    avgBrightest = max(avgProfile);
    avgDarkest = mean([avgProfile(1:10) avgProfile(end-9:end)]);
    avgThreshold = setThreshold*(avgBrightest-avgDarkest)+avgDarkest;
    line([0 length(avgProfile)],[avgThreshold avgThreshold],'Color','g','LineStyle','--');
    avgDia = (find(avgProfile>avgThreshold,1,'last')-find(avgProfile>avgThreshold,1,'first')+1)*info.VoxelSizeX*10^(6); % VoxelSizeX in m/pixel
    text(length(avgProfile)/2,avgThreshold,['avg dia = ' num2str(avgDia,3) ' µm'])
    
    brightest = nan(length(imROI),1);
    darkest = nan(length(imROI),1);
    threshold = nan(length(imROI),1);
    
    for j = 1:length(imROI)
        first = 1+j*winPixelsDown;
        last = first+(winSize);
        
        if first >= 1 && last <= maxLine
            fprintf('analyzing line:  %s \n',num2str(first))

            profile = mean(imROI(first:last,:)); % averaging all the lines within winSize
%             brightest(j) = max(max(imROI(first:last,:)));
            brightest(j) = max(profile);
%             darkest(j) = mean(mean([imROI(first:last,1:10) imROI(first:last,end-9:end)]));
            darkest(j) = mean([profile(1:10) profile(end-9:end)]);
            threshold(j) = setThreshold*(brightest(j)-darkest(j))+darkest(j); %threshold is specific to each window
            dia(j,i) = (find(profile>threshold(j),1,'last')-find(profile>threshold(j),1,'first')+1)*info.VoxelSizeX*10^(6); % VoxelSizeX in m/pixel

            % for debugging
%             figure(1000),plot(profile)
%             title('current intensity profile')
%             xlim([0 info.DimensionX])
%             ylabel('arbitrary unit (a.u.)')
%             xlabel('pixels')
%             line([0 length(profile)],[threshold(j) threshold(j)],'Color','g','LineStyle','--');
%             text(length(profile)/2,threshold(j),['avg dia = ' num2str(dia(j,i),3) ' µm'])
            % end of debugging
   
            timeAnalyzed(j) = time(first+winPixelsDown/2); %in s
        end
    end
    
    %truncate at maxLine and remove NaN
    dia = dia(1:maxLine,:);
    time = time(1:maxLine);
    time(isnan(dia)) = [];
    dia(isnan(dia)) = [];
   
    %plot yellow stimuli.  
    
fignum2=gcf;
done2=0;

fprintf('\nPress "M" if Manual Stimulation...\n  ')
fprintf('\nPress "A" if Automatic Stimulation...\n  ')
fprintf('\nPress "N" if No Stimualation...\n  ')



                while not(done2)
                 waitforbuttonpress
                pressed2 = get(fignum2, 'CurrentCharacter');
    
                    if pressed2 == 'm' % space for done w all ROIs
                      done2=1;
                        getStim;
   
                        elseif pressed2 == 'a'
                            done2=1;
                          figure(i)
                           subplot(3,1,2)
                            area([1 3], [999 999],'FaceColor','y'),hold on %shading stimuli
                            area([14 16], [999 999],'FaceColor','y'),
                            area([27 29], [999 999],'FaceColor','y'), 
                            area([40 42], [999 999],'FaceColor','y'),
                            area([53 55], [999 999],'FaceColor','y'),
                            area([66 68], [999 999],'FaceColor','y'),
                            area([79 81], [999 999],'FaceColor','y'),
                            area([92 94], [999 999],'FaceColor','y'),
                            area([105 107], [999 999],'FaceColor','y'),
                            area([118 120], [999 999],'FaceColor','y'),
                            plot(timeAnalyzed,dia(:,i),'.k')
                            title('raw diameter')
                            ylabel('diameter (µm)')
                            xlim([0 maxTime])
                             ylim([min(dia(:,i)) max(dia(:,i))])

                            figure(i)
                            subplot(3,1,3)
                            area([2 4], [999 999],'FaceColor','y'),hold on %shading stimuli
                            area([14 16], [999 999],'FaceColor','y'),
                            area([27 29], [999 999],'FaceColor','y'),
                            area([40 42], [999 999],'FaceColor','y'),
                            area([53 55], [999 999],'FaceColor','y'),
                            area([66 68], [999 999],'FaceColor','y'),
                            area([79 81], [999 999],'FaceColor','y'),
                            area([92 94], [999 999],'FaceColor','y'),
                            area([105 107], [999 999],'FaceColor','y'),
                            area([118 120], [999 999],'FaceColor','y'),
                            plot(timeAnalyzed,smooth(dia(:,i),round(0.05*length(dia))),'-b') % 5% smoothing
                            title('smoothed')
                            xlabel('time (s)')
                            ylabel('diameter (µm)')
                            xlim([0 maxTime])
                            ylim([min(dia(:,i)) max(dia(:,i))])

        
                         elseif pressed2 == 'n'
                        done2=1;
                        figure(i)
                           subplot(3,1,2)
                            plot(timeAnalyzed,dia(:,i),'.k')
                            title('raw diameter')
                            ylabel('diameter (µm)')
                            xlim([0 maxTime])
                            ylim([min(dia(:,i)) max(dia(:,i))])
                           
                            figure(i)
                            subplot(3,1,3)
                            plot(timeAnalyzed,smooth(dia(:,i),round(0.05*length(dia))),'-b') % 5% smoothing
                            title('smoothed')
                            xlabel('time (s)')
                            ylabel('diameter (µm)')
                            xlim([0 maxTime])
                            ylim([min(dia(:,i)) max(dia(:,i))])
    
                    end
                end

  
    
end

print(figure(i),'-dpdf',['ROIFinal' num2str(i)])
%% save

save('raw diameter.mat')
print(figure(100),'-dpdf','ROISelect')
% print(figure(2),'-dpdf','raw diameter')