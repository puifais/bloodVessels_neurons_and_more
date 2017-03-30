% lsSpeed.m
% measure RBC flow speed from linescan along a vessel

% created by Puifai on 6/30/14
% modification history:  none

% OUTPUT:  result, timeEKG, voltsEKG
% below are the columns of result
% 1) starting line number (first)
% 2) time (ms)
% 3) velocity (mm/s). positive meansRBC's from left to right. negative means right to
% left
% 4) Sep (Seperability)
% 5) Angle (true angle of stripes)
% 6) Flux (method 1:  10% above baseline thresholding)
% 7) Analog (Can be used to record average value of a data channel)
% 8) unsure -- 9/4/11 Puifai
% 9) Flux (method 2:  15% above baseline thresholding)
% 10)Flux (method 3:  25% above baseline thresholding)
% 11)Flux (method 4:  Otsu's algorithm thresholding

% if you get the warning, "TIFF library error: 'TIFFFillStrip: Invalid
% strip byte count 0, strip 1.'.  The image data may be corrupt." and it
% annoys you, turn it off. Here's how:
warning('off','all')
% or try this:
% w = warning('query','last');
% id = w.identifier;
% warning('off',id)

close all, clear all

%% user selects a tiff linescan to work on

dontaskslope = 0;  % user specifies slope

% Ask to go through new files or not
button = questdlg('New files to look at?',...
    'New files','Yes','No', 'Yes');
if strcmp(button,'Yes')
    newfiles = 1;
elseif strcmp(button,'No')
    newfiles = 0;
    keepgoing = 1;
end

if newfiles == 1;
    openNameTemp = [];
    fNameTemp = [];
    winLefts = [];
    winRights = [];
    slopes = [];
    NXs = [];
    Tfactors = []; % pixel/ms
    Xfactors =[]; % um/pixel
    useAvgs = [];
    maxLines = [];
    msPreAnalogPixel = [];
    
    % ask user for analysis parameter
    prompt = {'Always subtract average? (N/Y)', 'image channel (1,2)', 'objective magnification (#, or varied)','analog input (1,2,none)'};
    def = {'N', 'ignoreMe', 'ignoreMe','ignoreMe'};
    dlgTitle = 'Processing parameters';
    lineNo = 1;
    answer = inputdlg(prompt,dlgTitle,lineNo,def,'on');
    channel = str2double(answer(2));
    
    % use analog signal or not. no use now (7/10/14) but perhaps in the future
    if strcmp(answer(4),'1')
        useAna = 1;
    elseif strcmp(answer(4),'2')
        useAna = 2;
    else
        useAna = 0;
    end
    
    % subtracting average or not
    if strcmp(answer{1},'N')
        alwaysUseAvg = 0;
    else
        alwaysUseAvg = 1;
        useAvg = 1;
    end
    
    objectiveMag = str2double(answer(3)); %objectiveMag is unused
    
    morefiles = 1;
    
    while morefiles
        % read file
        [fname1 pname1] = uigetfile({'*.tif';'*.TIF';'*.tiff';'*.TIFF'},'select the linescan tiff file');
        cd(pname1)
        openFile = [pname1 fname1];
        [fname2 pname2] = uigetfile({'*.lsm'},'select the associated lsm file');
        infoFile = [pname2 fname2];
        info = lsminfo(infoFile);
        imData = double(imread(openFile));
        
        % save imaging parameters
        Tfactor = info.DimensionTime/(info.TimeStamps.TimeStamps(end)*1000); %ypix/ms
        Xfactor = info.VoxelSizeX*10^6; %um/xpix
        
        % show a scrollable linescan
        fprintf('showing:  %s\n',fname1)
        currentFrame = imData(1:info.DimensionX,:);
        figure(1)
        imagesc(currentFrame)% only show the first square lines
        colormap('Gray')
        title('raw image')
        xlim([0 info.DimensionX])
        ylim([0 info.DimensionX])
        axis image
        xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');

        fprintf('\npress n to begin ROI selection using the mouse...\n  ')
        beginLine = 1;
        done = 0;
        
        % user select ROIs
        while not(done)
            waitforbuttonpress
            pressed = get(gcf, 'CurrentCharacter');
            
            if pressed == ' ' % space for done w all ROIs
                done = 1;
            elseif pressed == 'f' % forward 1 "frame"
                if beginLine+info.DimensionX-1 <= info.DimensionTime;
                    beginLine = beginLine+info.DimensionX;
                    currentFrame = imData(beginLine:beginLine+info.DimensionX-1,:);
                else
                    beep
                    display ('no more lines')
                end
                imagesc(currentFrame);
                rectangle('Position', [winLeft, 1, width, info.DimensionX],'EdgeColor', 'm');
                title({fname1;['begin line: ', num2str(beginLine),'/', num2str(info.DimensionTime)]});
                axis image
                xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
            elseif pressed == 'b' % back 1 frame
                if beginLine > 1
                    beginLine = beginLine-info.DimensionX;
                    currentFrame = imData(beginLine:beginLine+info.DimensionX-1,:);
                else
                    beep
                    display ('no more lines')
                end
                imagesc(currentFrame);
                rectangle('Position', [winLeft, 1, width, info.DimensionX],'EdgeColor', 'm');
                title({fname1;['begin line: ', num2str(beginLine),'/', num2str(info.DimensionTime)]});
                axis image
                xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
            elseif pressed == 's' % skip 10 frames forward
                if beginLine+10*info.DimensionX <= info.DimensionTime;
                    beginLine = beginLine+10*info.DimensionX;
                    currentFrame = imData(beginLine:beginLine+info.DimensionX-1,:);
                else
                    beep
                    display ('no more frames')
                end
                imagesc(currentFrame);
                rectangle('Position', [winLeft, 1, width, info.DimensionX],'EdgeColor', 'm');
                title({fname1;['begin line: ', num2str(beginLine),'/', num2str(info.DimensionTime)]});
                axis image
                xlabel ('f-forward, b-back, s-skip forward, n-newbox, space-done');
            elseif pressed == 'n'
                fprintf('\nselect an ROI using the mouse:  ')
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
                if ROI(2)+ROI(4)>info.DimensionTime
                    ROI(4) = info.DimensionTime-ROI(2);
                end
                if ROI(1)>info.DimensionX || ROI(2)>info.DimensionTime
                    fprintf('you are intentionally selecting the wrong area!\n\n\nstart over...\n\n\n')
                else
                    display('good job. got this ROI')
                end
                
                %draw selection on figure
                winLeft = ROI(1);
                width = ROI(3);
                winRight = ROI(1) + ROI(3);
                rectangle('Position', [winLeft, 1, width, info.DimensionX],'EdgeColor', 'm');
            else
                beep
                display ('not a valid key')
            end
        end
        
        % Ask user for slope
        if dontaskslope == 0
            button = questdlg('slope', 'Slope of lines:', ...
                'positive', 'negative', 'both', 'both');
            if strcmp(button, 'positive')
                slope = 1;
            elseif strcmp(button, 'negative')
                slope = 0;
            else
                slope = 2;
            end
        end
        
        % Ask user if subtract average of linescans across from each block of data
        if alwaysUseAvg == 0
            button = questdlg('Subtract average across linescans?',...
                'Use average?','yes','no', 'yes');
            if strcmp(button,'yes')
                useAvg = 1;
            elseif strcmp(button,'no')
                useAvg = 0;
            end
        end
        
        % Store analysis parameters
        openNameTemp = strvcat(openNameTemp, openFile);
        fNameTemp = strvcat(fNameTemp, fname1);
        winLefts = vertcat(winLefts, winLeft);
        winRights = vertcat(winRights, winRight);
        slopes = vertcat(slopes, slope);
        NXs = vertcat(NXs, info.DimensionX);
        Tfactors = vertcat(Tfactors, Tfactor);
        Xfactors = vertcat(Xfactors, Xfactor);
        useAvgs = vertcat(useAvgs, useAvg);
        maxLines = vertcat(maxLines,info.DimensionTime(end));
        
        if useAna
            msPreAnalogPixel = vertcat(msPreAnalogPixel,ms_pre_analog_pixel);
        end
        
        %         clear openFile fname1 winLeft winRight slope Tfactor Xfactor useAvg
        
        % ask if more files?
        button = questdlg('More files?',...
            'Continue','yes','no','yes');
        if strcmp(button,'yes')
            morefiles = 1;
        elseif strcmp(button,'no')
            morefiles = 0;
        end
    end
    
    openName = cellstr(openNameTemp);
    fName = cellstr(fNameTemp);
    
    %% save parameters
    [fname3, pname3] = uiputfile('radonRaw.csv', 'Comma delimited file save As');
    saveFile1 = [pname3, fname3];
    
    % save as a .mat file
    saveFile2 = strrep(saveFile1, '.csv', 'Parameters');
    if useAna
        save(saveFile2, 'openName', 'slopes','winLefts','winRights','NXs', 'Tfactors', 'Xfactors','useAvgs', 'maxLines', 'msPreAnalogPixel','channel','useAna','info');
    else
        save(saveFile2, 'openName', 'slopes','winLefts','winRights','NXs', 'Tfactors', 'Xfactors','useAvgs', 'maxLines','channel','useAna','info');
    end
    
    % save as .csv file
    openName = strvcat('openName', openNameTemp);
    fName = strvcat('fName', fNameTemp);
    winLefts = strvcat('WinLeft',num2str(winLefts));
    winRights = strvcat('WinRight', num2str(winRights));
    slopes = strvcat('Slope',num2str(slopes));
    NXs = strvcat('NX', num2str(NXs));
    Tfactors = strvcat('Tfactor', num2str(Tfactors));
    Xfactors = strvcat('Xfactor', num2str(Xfactors));
    useAvgs = strvcat('useAvg', num2str(useAvgs));
    maxLines = strvcat('maxLine', num2str(maxLines));
    if useAna
        msPreAnalogPixel = strvcat('msPreAnalogPixel',num2str(msPreAnalogPixel));
    end
    
    [lines, col] = size(slopes);
    commas = char(44*ones(lines,1));
    
    if useAna
        tosave = horzcat((openName), commas, (NXs), commas,(Zs),commas, (Npics), commas, (winLefts),commas, (winRights), commas, (slopes),commas, (Tfactors), commas, (Xfactors), commas, (Tandems) , commas, (fName), commas, (FileTime), commas, (useAvgs), commas, (RotAngs), commas, (XLocs), commas, (YLocs), commas, (maxLines), commas, (msPreAnalogPixel));
    else
        tosave = horzcat((openName), commas, (winLefts),commas, (winRights), commas, (slopes),commas, (Tfactors), commas, (Xfactors) , commas, (maxLines), commas, (NXs), commas, (useAvgs), commas, (openName));
    end
    
    diary(saveFile1)
    tosave
    diary off
    
    button = questdlg('Calculate velocites now?',...
        'Continue','yes','no','yes');
    
    if strcmp(button,'yes')
        keepgoing = 1;
    elseif strcmp(button,'no')
        keepgoing = 0;
    end
    
end % if new files

%% compute speed
if keepgoing
    %get saved data (optional)
    if exist('saveFile2','var')
        load(saveFile2);
    else
        [fname4 pname4] = uigetfile({'*.mat'},'select the parameter file');
        openFile2 = [pname4 fname4];
        load(openFile2)
        cd(pname4)
    end
    
    [nfiles,z] = size(openName);
    
    % For running continuously from setup
    clear currentFrame
    
    % Running parameters from user
    prompt = {'winPixelsDown', 'winSize', 'max time (s)', 'Start with file #'};
    def = {'50', '100', '300', '1'};
    dlgTitle = 'Processing parameters';
    lineNo = 1;
    answer = inputdlg(prompt,dlgTitle,lineNo,def,'on');
    winPixelsDown = str2double(answer(1)); % number of pixels between top of last window and next window
    winSize =  str2double(answer(2));   % EVEN NUMBER please! actual data used is only center circle ~70% of area (square window)
    startFileNum = str2double(answer(4));
    
    % Loop through all files
    for i = startFileNum:nfiles
        tic
        maxTime =  str2double(answer(3)); 
        maxLines = floor(maxTime/info.TimeStamps.AvgStep); % total number of lines
        openFile3 = char(openName{i});
        
        if useAna
            dataFile = char(strrep(strrep(openName{i},'linescan ','velEKG '),'.MPD',[' ', num2str(winPixelsDown), num2str(winSize), '.mat']));
        else
            addonName = [' ', num2str(winPixelsDown), '-', num2str(winSize), ' vel.mat'];
            dataFile = strrep(strrep(strrep(strrep(openName{i},'.tiff',addonName),'.TIFF',addonName),'.tif',addonName),'.TIF',addonName);
        end
        
        fprintf('processing:  %s \n',openName{i})
        
        slope = slopes(i,1);
        winLeft = winLefts(i,1); % leftmost pixel
        winRight = winRights(i,1); % rightmost pixel
        NX = NXs(i,1);   % pixels per frame in x
        Tfactor = Tfactors(i, 1);
        Xfactor = Xfactors(i, 1);
        useAvg = useAvgs(i,1);
        if useAna
            ms_pre_analog_pixel = msPreAnalogPixel(i,1);
        end
        
        FR1 = 1;
        FRLast = 1;
        datachunk = [];
        
        % Loop through lines
        npoints = 0;
        first = 1;
        last = first+winSize;
        result = [];
        imData = imread(openFile3);
%%%%
%         for testing speed output accuracy
%         smallstuff = double(~eye(256,256));
%         emptystuff = ones(256,256);
%         imData = smallstuff;
%         imData = fliplr([smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff;smallstuff;emptystuff]);
%%%%       
            
        if maxLines == inf
            maxLines = size(imData,1);
        end
        
        while last < maxLines        
            
            if last > size(imData,1)
                break
            end
            
            lines = imData(first:last,:);
            
            if isempty(lines)
                break
            end
            
            [tny, tnx] = size(lines);
            
            if tny < winSize
                break
            end
            
            block = lines(:, winLeft: winRight);
            veldata = f_find_vel_flux_radon(block, Tfactor, Xfactor, slope, useAvg, 1);
            
            veldata(1) = first;
            veldata(2) = npoints*winPixelsDown/Tfactor;
            
            result = vertcat(result, veldata);
            first = first + winPixelsDown;
            fprintf('analyzing line:  %s \n',num2str(first))
            last = first+winSize;
            npoints = npoints+1;
        end
        
        % not used right now but leaving just in case want to in the future
        voltsEKG = [];
        timeEKG = [];
        
        if useAna
            
            if useAna == 1
                analogChannel = 3;
            else
                analogChannel = 4;
            end
            
            for j = 1:maxLines;
                framedata = invoke(mpfile,'ReadFrameData',analogChannel,j);
                voltsEKG = horzcat(voltsEKG, framedata);
                timeEKG = horzcat(timeEKG, ((1:length(framedata))+(j-1)*1000)*ms_pre_analog_pixel/1000);
            end
        end
        
        % save this
        %         save(dataFile,'result', 'Tfactor', 'winPixelsDown','voltsEKG','timeEKG');
        save(dataFile,'result', 'voltsEKG','timeEKG','info');
        
        clear result;
        toc
    end; % Loop for each file
    
    disp('done')
    beep
    
end % if keepgoing