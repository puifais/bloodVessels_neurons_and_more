  % framesDia.m
% measure diameter from perpendicular cross sections of still frames
% user select the lines. threshold is made from the intensity profile then
% diameter is measured

% created by Puifai on 7/9/14
% modification history:
% 8/11/2014 - utilize Butterworth filter to smooth data. Threshold calculation based on edges of intensity profile, but
% omits the very end 5% of data, which cannot be filtered properly.
% Diameter detection from first and last points that intensity profile
% exceeds threshold, omiting the very edges of data.
% 8/12/14 - interp rawProfile to make it fine first, then do butterworth
% filter later
% 8/12/14 - save threshold, rawProfFine,avgProfFiit,profDistFine in 3D
% arrays
% 9/5/14 - added maxTime to end data at end of 10 epochs
% 9/26/14 - save figures as .pdf automatically
% 10/22/14 - can now handle still, snapshot, and stack data
% 12/2/14 - calculate diameter of each ROI from the z-projected image too.
% 'darkest' is also calculated from 10% of fine data, skipping the 10% at
% the very edges
% 12/5/14 - when pressing 's' to skip frames, skip by 25 instead of 10
% frames
% 12/9/14 - filtered data based on residual of the 'hill' that is -20%
% change or more
% 12/9/14 - added capability to measure diameter from partial z-projection
% from a stack. But parameters are not saved in .m file. All diameters
% saved on pdf printout
% 12/11/14 - user select which frames to project for diameter measurement
% from stacks

warning('off','all')

close all, clear all
%% user selects a tiff linescan to work on

[fname pname] = uigetfile({'*.tif';'*.TIF';'*.tiff';'*.TIFF'},'select the still video tiff file');
cd(pname)
openFile = [pname fname];
[fname2 pname2] = uigetfile({'*.lsm'},'select the associated lsm file');
infoFile = [pname2 fname2];
info = lsminfo(infoFile);

%manual input for merged stacks
% info.ScanInfo.NUMBER_OF_PLANES = 97;
% info.DimensionX = 575;
% info.DimensionY = 823;

if strcmp(info.ScanInfo.SCAN_MODE,'Plan')
    numFrames = info.DimensionTime;
else % for stack or snap data
    numFrames = info.ScanInfo.NUMBER_OF_PLANES;
end

%% user selects lines across blood vessels

%show a z-project stack using average value
info2 = imfinfo(openFile);

if info2(1,1).BitDepth == 16
    zproject = zeros(info2(1,1).Height,info2(1,1).Width,'uint16');
    imData = zeros(info2(1,1).Height,info2(1,1).Width,numFrames,'uint16');
elseif info2(1,1).BitDepth == 8
    zproject = zeros(info2(1,1).Height,info2(1,1).Width,'uint8');
    imData = zeros(info2(1,1).Height,info2(1,1).Width,numFrames,'uint8');
end

fprintf('projecting:  %s \n', fname)

for i = 1:numFrames
    imData(:,:,i) = imread(openFile,i);
end

zproject = mean(imData,3);

figure(100)
subplot(2,2,1)
imagesc(zproject)
title('average z-projection')
xlim([0 info.DimensionX])
ylim([0 info.DimensionY])
axis image

% show a scrollable stack
currentFrame = imread(openFile,1);

figure(100)
subplot(2,2,2)
imagesc(currentFrame)
colormap gray
title('scrollable frames')
xlim([0 info.DimensionX])
ylim([0 info.DimensionY])
axis image
xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');

done = 0;
currentFrameNum = 1;
numROI = 0;

% ask user if want to use partial zprojection in case of stack data
disp('press a button...')
waitforbuttonpress
partialZproj = 0;

if strcmp(info.ScanInfo.SCAN_MODE,'Stac') %for stack data
    choice = questdlg('Measure diameters from partial z-projection?', ...
        'Partial or Full Z-projection?', ...
        'Full','Partial','Partial');
    
    switch choice
        case 'Partial'
            disp([choice ' z-projection diameter measurements.'])
            partialZproj = 1;
        case 'Full'
            disp([choice ' z-projection diameter measurements.'])
    end
end

if ~partialZproj
    
    fprintf('\nplease try your best to get the vessels to be in the middle of your line selection\n\n')
    fprintf('\npress n to begin line selection using the mouse...\n  ')
    
    while not(done)
        
        waitforbuttonpress
        pressed = get(gcf, 'CurrentCharacter');
        
        
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
            subplot(2,2,2), imagesc(currentFrame);
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
            subplot(2,2,2), imagesc(currentFrame);
            title({fname;['frame:', num2str(currentFrameNum),'/', num2str(numFrames)]});
            axis image
            xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
        elseif pressed == 's' % skip 10 frames forward
            if currentFrameNum+25 <= numFrames;
                currentFrameNum = currentFrameNum+25;
                currentFrame = imread(openFile,currentFrameNum);
            else
                beep
                display ('no more frames')
            end
            subplot(2,2,2), imagesc(currentFrame);
            title({fname;['frame:', num2str(currentFrameNum),'/', num2str(numFrames)]});
            axis image
            xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
        elseif pressed == 'n'
            numROI = numROI+1;
            fprintf('\nselect a line using the mouse. left click, then right:  ')
            subplot(2,2,1)
            ROI = round(getline);
            display('good job. got this ROI')
            
            allROI((numROI-1)*2+1:(numROI-1)*2+2,:) = ROI;
            
            %draw selection on figure
            subplot(2,2,1)
            line(ROI(:,1),ROI(:,2),'Color','m');
            text(ROI(1,1),ROI(1,2),['\color{magenta}' num2str(numROI)])
            subplot(2,2,2)
            line(ROI(:,1),ROI(:,2),'Color','m');
            
            subplot(2,2,2)
        else
            beep
            display ('not a valid key')
        end
    end %loop while not done
    print(figure(100),'-dpdf','ROI selection')
    
    %% measure diameter of the z-projected image
    setThreshold = 0.15;% set at 15% because old paper did this
    
    zprojDia = nan(1,numROI);
    zprojDiaTemp = nan;
    zprojThreshold = nan(1,numROI);
    zprojRawProfileFine = nan(100,numROI);
    zprojProfDistFine = nan(100,numROI);
    zprojAvgProfFit = nan(100,numROI);
    zprojRawProfile = cell(1,numROI);
    zprojProfDist = cell(1,numROI);
    zprojEndIndex = nan(1,numROI);
    zprojBeginIndex = nan(1,numROI);
    
    for i = 1:numROI
        
        fprintf('analyzing zprojected:  %s ROI %3.0f\n', fname,i)
        imROI = zproject;
        
        [cx,cy,zprojRawProfile{1,i}] = improfile(imROI,allROI((i-1)*2+1:(i-1)*2+2,1),allROI((i-1)*2+1:(i-1)*2+2,2));
        
        % make distance vector more fine
        zprojProfDist{1,i} = sqrt((cx-cx(1)).^2+(cy-cy(1)).^2)*info.VoxelSizeX*10^(6); %in um
        zprojProfDistFine(:,i) = linspace(min(zprojProfDist{1,i}),max(zprojProfDist{1,i}),100)'; %in um
        zprojRawProfileFine(:,i) = interp1q(zprojProfDist{1,i},zprojRawProfile{1,i},zprojProfDistFine(:,i));
        % perform Butterworth filter
        [B,A] = butter(3,0.2); %butter filter of order 3, low pass at 0.2 Hz (normalized frequency)
        zprojAvgProfFit(:,i) = filtfilt(B,A,zprojRawProfileFine(:,i));
        %         perform Gaussian fit
        %         [sigma mu A] = mygaussfit(profDist,avgProfile);
        %         zprojAvgProfFit = A*exp(-(zprojProfDistFine-mu).^2/(2*sigma^2));
        zprojAvgProfFitTemp = zprojAvgProfFit(:,i);
        
        %skipping 10% of data at the edges, which were not filtered
        omitEdge = round(0.1*numel(zprojAvgProfFitTemp));
        
        % determine brightest and darkest and threshold
        brightest = max(zprojAvgProfFitTemp);
        darkest = mean([zprojAvgProfFitTemp(omitEdge:omitEdge+round(0.15*numel(zprojAvgProfFitTemp))); zprojAvgProfFitTemp(end-omitEdge-round(0.15*numel(zprojAvgProfFitTemp))+1:end-omitEdge)]); %determine darkest from the edges, but skipping the very far edges
        zprojThreshold(i) = setThreshold*(brightest-darkest)+darkest;
        
        % measure diameter
        zprojBeginIndex(i) = find(zprojAvgProfFitTemp(omitEdge:end)>zprojThreshold(i),1,'first')+omitEdge-1; %skip the edge. Then adjust index
        zprojEndIndex(i) = find(zprojAvgProfFitTemp(1:end-omitEdge)>zprojThreshold(i),1,'last'); %skip the edge. No need to adjust index
        zprojDiaTemp = zprojProfDistFine(zprojEndIndex(i),i)-zprojProfDistFine(zprojBeginIndex(i),i); % in um
        
        if numel(zprojDiaTemp) == 0
            zprojDiaTemp = nan;
        end
        
        zprojDia(i) = zprojDiaTemp;
        
        % show each frame and profile
        figure(i)
        set(gcf,'Name',['ROI ' num2str(i)])
        subplot(5,2,1)
        plot(zprojProfDist{1,i},zprojRawProfile{1,i},'c.-',zprojProfDistFine(:,i),zprojAvgProfFit(:,i),'m')
        axis([0 max(zprojProfDist{1,i}) 0.9*min(zprojRawProfile{1,i}) 1.1*max(zprojRawProfile{1,i})])
        hold on
        if ~isnan(zprojDiaTemp)
            plot(zprojProfDistFine(zprojBeginIndex(i),i),zprojThreshold(i),'rx','MarkerSize',15)
            plot(zprojProfDistFine(zprojEndIndex(i),i),zprojThreshold(i),'rx','MarkerSize',15)
        end
        title(['z-proj dia = ' num2str(zprojDia(i),'%0.1f') ' µm'])
        line([0 max(zprojProfDistFine(:,i))],[zprojThreshold(i) zprojThreshold(i)],'Color','r','LineStyle','--');
        hold off
        
        if strcmp(info.ScanInfo.SCAN_MODE,'Plan') && info.DimensionTime > 1 %for still data
            figure(400+i)
            set(gcf,'Name',['filtered ROI ' num2str(i)])
            subplot(5,2,1)
            plot(zprojProfDist{1,i},zprojRawProfile{1,i},'c.-',zprojProfDistFine(:,i),zprojAvgProfFit(:,i),'m')
            axis([0 max(zprojProfDist{1,i}) 0.9*min(zprojRawProfile{1,i}) 1.1*max(zprojRawProfile{1,i})])
            hold on
            if ~isnan(zprojDiaTemp)
                plot(zprojProfDistFine(zprojBeginIndex(i),i),zprojThreshold(i),'rx','MarkerSize',15)
                plot(zprojProfDistFine(zprojEndIndex(i),i),zprojThreshold(i),'rx','MarkerSize',15)
            end
            title(['z-proj dia = ' num2str(zprojDia(i),'%0.1f') ' µm'])
            line([0 max(zprojProfDistFine(:,i))],[zprojThreshold(i) zprojThreshold(i)],'Color','r','LineStyle','--');
            hold off
            
            print(gcf,'-dpdf',['ROI ' num2str(i)]);
            
        else %for stack and snap data
            print(gcf,'-dpdf',['ROI ' num2str(i)]);
        end
    end
    
    %% measure diameter and plot
    maxTime = 300; %in s. Because recording 10 epochs of 30 s each.
    
    if strcmp(info.ScanInfo.SCAN_MODE,'Plan') && info.DimensionTime ~= 1% this is for still frames
        maxFrame = floor(maxTime/info.TimeStamps.AvgStep);
        if size(imData,3) < maxFrame
            maxFrame = size(imData,3);
        end
    elseif strcmp(info.ScanInfo.SCAN_MODE,'Plan') && info.DimensionTime == 1 % this is a snap data
        maxFrame = 1;
    elseif strcmp(info.ScanInfo.SCAN_MODE,'Stac') % this is for stack frames
        maxFrame = 1;
        imData = mean(imData,3);
    else
        error('\nWhat file type is this? This algorithm is now going to destroy the Earth\n')
    end
    
    
    
    % set number of frame smoothing
    frameSmooth = 5; %2 before, 2 after frame of interest. odd number only
    
    dia = nan(maxFrame,numROI);
    diaTemp = nan;
    time = info.TimeStamps.TimeStamps; % in s
    threshold = nan(maxFrame,numROI);
    rawProfile = cell(1,numROI,maxFrame);
    profDist = cell(1,numROI,maxFrame);
    rawProfileFine = nan(100,numROI,maxFrame);
    profDistFine = nan(100,numROI,maxFrame);
    avgProfFit = nan(100,numROI,maxFrame);
    beginIndex = nan(maxFrame,numROI);
    endIndex = nan(maxFrame,numROI);
    
    for i = 1:maxFrame
        fprintf('analyzing:  %s frame %3.0f\n', fname,i)
        if maxFrame == 1
            imROI = imData(:,:);
        elseif i-(frameSmooth-1)/2 >= 1 && i+(frameSmooth-1)/2 <= numFrames
            imROI = mean(imData(:,:,i-(frameSmooth-1)/2:i+(frameSmooth-1)/2),3);
        elseif i-(frameSmooth-1)/2 < 1
            imROI = mean(imData(:,:,i:i+(frameSmooth-1)/2),3); %this means the first couple of frames will not have equal amount of smoothing
        else
            imROI = mean(imData(:,:,i-(frameSmooth-1)/2:i),3); %this means the last couple of frames will not have equal amount of smoothing
        end
        
        for j = 1:numROI
            [cx,cy,rawProfile{1,j,i}] = improfile(imROI,allROI((j-1)*2+1:(j-1)*2+2,1),allROI((j-1)*2+1:(j-1)*2+2,2));
            
            % make distance vector more fine
            profDist{1,j,i} = sqrt((cx-cx(1)).^2+(cy-cy(1)).^2)*info.VoxelSizeX*10^(6); %in um
            profDistFine(:,j,i) = linspace(min(profDist{1,j,i}),max(profDist{1,j,i}),100)'; %in um
            rawProfileFine(:,j,i) = interp1q(profDist{1,j,i},rawProfile{1,j,i},profDistFine(:,j,i));
            % perform Butterworth filter
            [B,A] = butter(3,0.2); %butter filter of order 3, low pass at 0.2 Hz
            avgProfFit(:,j,i) = filtfilt(B,A,rawProfileFine(:,j,i));
            % perform Gaussian fit
            % [sigma mu A] = mygaussfit(profDist,avgProfile);
            % avgProfFit = A*exp(-(profDistFine-mu).^2/(2*sigma^2));
            avgProfFitTemp = avgProfFit(:,j,i);
            
            %skipping 10% of data at the edges, which were not filtered
            omitEdge = round(0.1*numel(avgProfFitTemp));
            
            % determine brightest and darkest and threshold
            brightest = max(avgProfFitTemp);
            darkest = mean([avgProfFitTemp(omitEdge:omitEdge+round(0.15*numel(avgProfFitTemp))); avgProfFitTemp(end-omitEdge-round(0.15*numel(avgProfFitTemp))+1:end-omitEdge)]); %determine darkest from the edges, but skipping the very far edges
            threshold(i,j) = setThreshold*(brightest-darkest)+darkest;
            
            % measure diameter
            if sum(avgProfFitTemp(omitEdge:end)>threshold(i,j)) == 0 || sum(avgProfFitTemp(1:end-omitEdge)>threshold(i,j)) == 0 %in case of frame drip due to motion
                beginIndex(i,j) = NaN;
                endIndex(i,j) = NaN;
                diaTemp = NaN;
            else %otherwise, measure diameter
                beginIndex(i,j) = find(avgProfFitTemp(omitEdge:end)>threshold(i,j),1,'first')+omitEdge-1; %skip the edge. Then adjust index
                endIndex(i,j) = find(avgProfFitTemp(1:end-omitEdge)>threshold(i,j),1,'last'); %skip the edge. No need to adjust index
                diaTemp = profDistFine(endIndex(i,j),j,i)-profDistFine(beginIndex(i,j),j,i); % in um
            end
            if numel(diaTemp) == 0
                diaTemp = nan;
            end
            
            dia(i,j) = diaTemp;
            
            % show each frame and profile
            figure(100)
            subplot(2,2,2)
            colormap('default')
            set(gcf,'Name',[' frame ' num2str(i) ' of ' num2str(numFrames)])
            imagesc(imROI)
            line(allROI((j-1)*2+1:(j-1)*2+2,1),allROI((j-1)*2+1:(j-1)*2+2,2),'Color','m')
            title('raw image')
            axis image
            
            subplot(2,1,2)
            plot(profDist{1,j,i},rawProfile{1,j,i},'k.-',profDistFine(:,j,i),avgProfFit(:,j,i),'b')
            hold on
            if ~isnan(diaTemp)
                plot(profDistFine(beginIndex(i,j),j,i),threshold(i,j),'rx','MarkerSize',15)
                plot(profDistFine(endIndex(i,j),j,i),threshold(i,j),'rx','MarkerSize',15)
            end
            title(['diameter = ' num2str(diaTemp,'%0.1f') ' µm'])
            line([0 max(profDistFine(:,j,i))],[threshold(i,j) threshold(i,j)],'Color','r','LineStyle','--');
            hold off
            
            ylabel('intensity (a.u.)')
            xlabel('profile distance (um)')
        end
    end
    
    %check in case unequal length
    if length(time)>length(dia)
        time = time(1:length(dia));
    else
        dia = dia(1:length(time),:);
    end
    
    %% printout profile of many frames to get a sense of the fit+thresholding
    
    if strcmp(info.ScanInfo.SCAN_MODE,'Plan') && info.DimensionTime > 1
        randomFrame = ceil(rand(9,1)*maxFrame);
        
        for i = 1:numROI
            figure(i)
            subplot(5,2,1)
            title(['z-proj dia = ' num2str(zprojDia(i),'%0.1f') ' µm. avg = ' num2str(nanmean(dia(:,i)),'%0.1f') ' µm'])
            for j = 1:9
                subplot(5,2,j+1)
                plot(profDist{1,i,randomFrame(j)},rawProfile{1,i,randomFrame(j)},'k.-',profDistFine(:,i,randomFrame(j)),avgProfFit(:,i,randomFrame(j)),'b')
                axis([0 max(zprojProfDist{1,i}) 0.9*min(zprojRawProfile{1,i}) 1.1*max(zprojRawProfile{1,i})])
                hold on
                if ~isnan(dia(randomFrame(j),i))
                    plot(profDistFine(beginIndex(randomFrame(j),i),i,randomFrame(j)),threshold(randomFrame(j),i),'rx','MarkerSize',15)
                    plot(profDistFine(endIndex(randomFrame(j),i),i,randomFrame(j)),threshold(randomFrame(j),i),'rx','MarkerSize',15)
                end
                title(['frame ' num2str(randomFrame(j)) ', dia = ' num2str(dia(randomFrame(j),i),'%0.1f') ' µm'])
                line([0 max(profDistFine(:,i))],[threshold(randomFrame(j),i) threshold(randomFrame(j),i)],'Color','r','LineStyle','--');
                hold off
            end
            subplot(5,2,5)
            ylabel('intensity (a.u.)')
            subplot(5,2,9)
            xlabel('profile distance (um)')
            subplot(5,2,10)
            xlabel('profile distance (um)')
            
            print(gcf,'-dpdf',['ROI ' num2str(i)]);
        end
        
        %% rule out failed diameter
        
        %calculate residual of the wings of each frame for each ROI
        resWing = nan(maxFrame,numROI);
        normResWing = nan(maxFrame,numROI);
        resHill = nan(maxFrame,numROI);
        normResHill = nan(maxFrame,numROI);
        
        zprojResWing = nan(1,numROI);
        normZprojResWing = nan(1,numROI);
        zprojResHill = nan(1,numROI);
        normZprojResHill = nan(1,numROI);
        
        resWingChange = nan(maxFrame,numROI);
        resHillChange = nan(maxFrame,numROI);
        
        for i = 1:numROI
            tempZprojWing = [zprojAvgProfFit(1:zprojBeginIndex(i)-1,i); zprojAvgProfFit(zprojEndIndex(i)+1:end,i)];
            zprojResWing(i) = sum(zprojThreshold(i)-tempZprojWing); %more+ means less background at the wings
            normZprojResWing(i) = zprojResWing(i)/numel(tempZprojWing);
            
            tempZprojHill = zprojAvgProfFit(zprojBeginIndex(i):zprojEndIndex(i),i);
            zprojResHill(i) = sum(tempZprojHill-zprojThreshold(i)); %more+ means bigger hill
            normZprojResHill(i) = zprojResHill(i)/numel(tempZprojHill);
            
            tempAvgProfFit = permute(avgProfFit(:,i,:),[3 1 2]);
            
            for j = 1:maxFrame
                
                if isnan(threshold(j,i)) || isnan(beginIndex(j,i)) || isnan(endIndex(j,i))
                    normResWing(j,i) = -0.49*normZprojResWing(i); %automatically set the failed frames so that resWingChange and resHillChange would be -50%
                    normResHill(j,i) = -0.49*normZprojResHill(i); %automatically set the failed frames so that resWingChange and resHillChange would be -50%
                else
                    tempThreshold = threshold(j,i);
                    
                    tempWing = [tempAvgProfFit(j,1:beginIndex(j,i)-1) tempAvgProfFit(j,endIndex(j,i)+1:end)];
                    resWing(j,i) = sum(tempThreshold-tempWing);  %more positive means less background at the wings
                    normResWing(j,i) = resWing(j,i)/numel(tempWing);
                    
                    tempHill = tempAvgProfFit(j,beginIndex(j,i):endIndex(j,i));
                    resHill(j,i) = sum(tempHill-tempThreshold); %more positive means bigger hill
                    normResHill(j,i) = resHill(j,i)/numel(tempHill);
                end
            end
            
            resWingChange(:,i) = (normResWing(:,i)-normZprojResWing(i))/normZprojResWing(i)*100;
            resHillChange(:,i) = (normResHill(:,i)-normZprojResHill(i))/normZprojResHill(i)*100;
        end
        
        % show residual change and diameter
        legendROI = cell(numROI,1);
        for i = 1:numROI
            legendROI{i} = num2str(i);
        end
        
        figure(300)
        subplot(2,1,1)
        plot(resWingChange,dia,'.')
        hold on
        title('all diameter')
        ylabel('diameter (µm)')
        xlabel('%change normalized "wings" residual')
        
        subplot(2,1,2)
        plot(resHillChange,dia,'.')
        hold on
        title('all diameter')
        ylabel('diameter (µm)')
        xlabel('%change normalized "hill" residual')
        
        % subplot(1,2,2)
        % plot(resWingChange,resHillChange,'.')
        % ylabel('%change normalized "hill" residual')
        % xlabel('%change normalized "wings" residual')
        % title('all diameter')
        % legend(legendROI)
        
        % rule out bad diameters
        wingResCutoff = -20;
        hillResCutoff = -20;
        filtDia = dia;
        filtDia(resWingChange < wingResCutoff) = nan;
        filtDia(resHillChange < hillResCutoff) = nan;
        
        % for j = 1:numROI
        %     highEnd = 1.3*zprojDia(j); %any diameter 30% above the mean is filtered out because expect MAX dilation of 25%
        %     filtDia(dia(:,j)>highEnd,j) = nan;
        %
        %     %after a lot of testing, realize that low diameter is very rarely
        %     %wrong. so not filtering
        % end
        
        subplot(2,1,1)
        line([wingResCutoff wingResCutoff],[0.95*min(min(dia)) 1.05*max(max(dia))],'Color','r','LineStyle','--');
        legend(legendROI)
        hold off
        subplot(2,1,2)
        line([hillResCutoff hillResCutoff],[0.95*min(min(dia)) 1.05*max(max(dia))],'Color','r','LineStyle','--');
        hold off
        
        print(figure(300),'-dpdf','residual')
        
        %% After ruled out bad dia, printout profile of many frames to get a sense of the fit+thresholding again
        
        for i = 1:numROI
            figure(400+i)
            
            percentExclude = round(sum(isnan(filtDia(:,i)))/size(filtDia,1)*100);
            subplot(5,2,1)
            title(['z-proj dia = ' num2str(zprojDia(i),'%0.1f') ' µm. avg = ' num2str(nanmean(filtDia(:,i)),'%0.1f') ' µm (exclude ' num2str(percentExclude,'%0.0f') '% of data)'])
            goodDiaFrame = find(~isnan(filtDia(:,i)));
            randomFrame = [goodDiaFrame(1) goodDiaFrame(round(numel(goodDiaFrame)/8)) goodDiaFrame(round(numel(goodDiaFrame)/8)*2) goodDiaFrame(round(numel(goodDiaFrame)/8)*3) goodDiaFrame(round(numel(goodDiaFrame)/8)*4) goodDiaFrame(round(numel(goodDiaFrame)/8)*5) goodDiaFrame(round(numel(goodDiaFrame)/8)*6) goodDiaFrame(round(numel(goodDiaFrame)/8)*7) goodDiaFrame(end)];
            for j = 1:9
                subplot(5,2,j+1)
                plot(profDist{1,i,randomFrame(j)},rawProfile{1,i,randomFrame(j)},'k.-',profDistFine(:,i,randomFrame(j)),avgProfFit(:,i,randomFrame(j)),'b')
                axis([0 max(zprojProfDist{1,i}) 0.9*min(zprojRawProfile{1,i}) 1.1*max(zprojRawProfile{1,i})])
                hold on
                if ~isnan(dia(randomFrame(j),i))
                    plot(profDistFine(beginIndex(randomFrame(j),i),i,randomFrame(j)),threshold(randomFrame(j),i),'rx','MarkerSize',15)
                    plot(profDistFine(endIndex(randomFrame(j),i),i,randomFrame(j)),threshold(randomFrame(j),i),'rx','MarkerSize',15)
                end
                title(['frame ' num2str(randomFrame(j)) ', dia = ' num2str(dia(randomFrame(j),i),'%0.1f') ' µm'])
                line([0 max(profDistFine(:,i))],[threshold(randomFrame(j),i) threshold(randomFrame(j),i)],'Color','r','LineStyle','--');
                hold off
            end
            subplot(5,2,5)
            ylabel('intensity (a.u.)')
            subplot(5,2,9)
            xlabel('profile distance (um)')
            subplot(5,2,10)
            xlabel('profile distance (um)')
            
            print(gcf,'-dpdf',['filtered ROI ' num2str(i)]);
        end
        
        %% plot all diameters over time
        
        percentExclude = round(sum(sum(isnan(filtDia)))/numel(filtDia)*100);
        
        % filtered diameters
        figure(201)
        subplot(2,1,2)
      
        plot(time,filtDia,'.-')
        title(['filtered ' num2str(fname) ' (excluding ' num2str(percentExclude,'%0.0f') '% of data)'])
        ylabel('diameter (µm)')
        xlabel('time (s)')
        axis([0 max(time) min(nanmin(dia)) max(nanmax(dia))])

        figure(201)
        subplot(2,1,1)
       plot(time,dia,'.-')
        title(['raw ' num2str(fname) ' (' num2str(numFrames) ' frames)'])
        ylabel('diameter (µm)')
        xlabel('time (s)')
        axis([0 max(time) min(nanmin(dia)) max(nanmax(dia))])
        legend(legendROI)
    
        
        % save
        print(figure(201),'-dpdf','frameDiameter')
    end
    
    % save
    save('raw frameDia.mat')
    
else% for partial z-projection
    %     numFrameProj = 100;
    %     numFrameOverlap = 5;
    
    %     for j = 1:ceil(numFrames/numFrameProj)
    done2 = 0;
    
    while ~done2
        
        prompt = {'Enter begin frame:','Enter end frame:'};
        dlg_title = 'Partial z-project';
        num_lines = 1;
        def = {'1','30'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        beginFrame = str2double(answer{1});
        if str2double(answer{2}) < numFrames %in case user went over max frame
            endFrame = str2double(answer{2});
        else
            endFrame = numFrames;
        end
        
        %         beginFrame = 1+numFrameProj*(j-1);
        %         endFrame = numFrameProj+numFrameOverlap+numFrameProj*(j-1);
        
        %         if endFrame > numFrames
        %             endFrame = numFrames;
        %         end
        zproject = mean(imData(:,:,beginFrame:endFrame),3);
        figure
        imagesc(zproject)
        title(['average z-projection of frames ' num2str(beginFrame) ' to ' num2str(endFrame)])
        xlabel ('n-newbox, space-done');
        xlim([0 info.DimensionX])
        ylim([0 info.DimensionY])
        axis image
        
        % ROI selection
        fprintf('\nplease try your best to get the vessels to be in the middle of your line selection\n\n')
        fprintf('\npress n to begin line selection using the mouse...\n  ')
        
        done = 0;
        numROI = 0;
        while not(done)
            
            waitforbuttonpress
            pressed = get(gcf, 'CurrentCharacter');
            
            if pressed == ' ' % space for done w all ROIs
                done = 1;
            elseif pressed == 'n'
                numROI = numROI+1;
                fprintf('\nselect a line using the mouse. left click, then right:  ')
                ROI = round(getline);
                display('good job. got this ROI')
                
                allROI((numROI-1)*2+1:(numROI-1)*2+2,:) = ROI;
                
                %draw selection on figure
                line(ROI(:,1),ROI(:,2),'Color','m');
                text(ROI(1,1),ROI(1,2),['\color{magenta}' num2str(numROI)])
            else
                beep
                display ('not a valid key')
            end
        end %loop while not done
        print(gcf,'-dpdf',['frame ' num2str(beginFrame) '-' num2str(endFrame) ' ROI selection'])
        
        % measure diameter
        setThreshold = 0.15;% set at 15% because old paper did this
        
        zprojDia = nan(1,numROI);
        zprojDiaTemp = nan;
        zprojThreshold = nan(1,numROI);
        zprojRawProfileFine = nan(100,numROI);
        zprojProfDistFine = nan(100,numROI);
        zprojAvgProfFit = nan(100,numROI);
        zprojEndIndex = nan(1,numROI);
        zprojBeginIndex = nan(1,numROI);
        zprojRawProfile = cell(1,numROI);
        zprojProfDist = cell(1,numROI);
        
        for i = 1:numROI
            
            fprintf('analyzing zprojected:  %s ROI %3.0f\n', fname,i)
            imROI = zproject;
            
            [cx,cy,zprojRawProfile{1,i}] = improfile(imROI,allROI((i-1)*2+1:(i-1)*2+2,1),allROI((i-1)*2+1:(i-1)*2+2,2));
            
            % make distance vector more fine
            zprojProfDist{1,i} = sqrt((cx-cx(1)).^2+(cy-cy(1)).^2)*info.VoxelSizeX*10^(6); %in um
            zprojProfDistFine(:,i) = linspace(min(zprojProfDist{1,i}),max(zprojProfDist{1,i}),100)'; %in um
            zprojRawProfileFine(:,i) = interp1q(zprojProfDist{1,i},zprojRawProfile{1,i},zprojProfDistFine(:,i));
            % perform Butterworth filter
            [B,A] = butter(3,0.2); %butter filter of order 3, low pass at 0.2 Hz
            zprojAvgProfFit(:,i) = filtfilt(B,A,zprojRawProfileFine(:,i));
            zprojAvgProfFitTemp = zprojAvgProfFit(:,i);
            
            %skipping 10% of data at the edges, which were not filtered
            omitEdge = round(0.1*numel(zprojAvgProfFitTemp));
            
            % determine brightest and darkest and threshold
            brightest = max(zprojAvgProfFitTemp);
            darkest = mean([zprojAvgProfFitTemp(omitEdge:omitEdge+round(0.15*numel(zprojAvgProfFitTemp))); zprojAvgProfFitTemp(end-omitEdge-round(0.15*numel(zprojAvgProfFitTemp))+1:end-omitEdge)]); %determine darkest from the edges, but skipping the very far edges
            zprojThreshold(i) = setThreshold*(brightest-darkest)+darkest;
            
            % measure diameter
            zprojBeginIndex(i) = find(zprojAvgProfFitTemp(omitEdge:end)>zprojThreshold(i),1,'first')+omitEdge-1; %skip the edge. Then adjust index
            zprojEndIndex(i) = find(zprojAvgProfFitTemp(1:end-omitEdge)>zprojThreshold(i),1,'last'); %skip the edge. No need to adjust index
            zprojDiaTemp = zprojProfDistFine(zprojEndIndex(i),i)-zprojProfDistFine(zprojBeginIndex(i),i); % in um
            
            if numel(zprojDiaTemp) == 0
                zprojDiaTemp = nan;
            end
            
            zprojDia(i) = zprojDiaTemp;
            
            % show each frame and profile
            figure
            set(gcf,'Name',['frame ' num2str(beginFrame) '-' num2str(endFrame) ' ROI ' num2str(i)])
            subplot(5,2,1)
            plot(zprojProfDist{1,i},zprojRawProfile{1,i},'c.-',zprojProfDistFine(:,i),zprojAvgProfFit(:,i),'m')
            axis([0 max(zprojProfDist{1,i}) 0.9*min(zprojRawProfile{1,i}) 1.1*max(zprojRawProfile{1,i})])
            hold on
            if ~isnan(zprojDiaTemp)
                plot(zprojProfDistFine(zprojBeginIndex(i),i),zprojThreshold(i),'rx','MarkerSize',15)
                plot(zprojProfDistFine(zprojEndIndex(i),i),zprojThreshold(i),'rx','MarkerSize',15)
            end
            title(['z-proj dia = ' num2str(zprojDia(i),'%0.1f') ' µm'])
            line([0 max(zprojProfDistFine(:,i))],[zprojThreshold(i) zprojThreshold(i)],'Color','r','LineStyle','--');
            hold off
            
            print(gcf,'-dpdf',['frame ' num2str(beginFrame) '-' num2str(endFrame) ' ROI ' num2str(i)]);
        end
        
        %         % don't analyze that left-over 1 little frame if that's the case
        %         if endFrame == numFrames
        %             break
        %         end
        
        % ask user if want to continue measuring diameters
        disp('press a button...')
        waitforbuttonpress
        choice = questdlg('Done?', ...
            'Measure more diameters?', ...
            'Yes','No','Yes');
        
        switch choice
            case 'Yes'
                done2 = 1;
            case 'No'
                
        end
        
    end
end