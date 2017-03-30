% cellIntensity.m

% get fluorescence intensity of neuronal soma, excluding the nucleus, and
% subtracting background

% create by Puifai on 1/8/2014
% modification history:  
% 2014-10-08 save automatically. minor changes in display
% 2016-03-08 Added Subplot to final figure to show stimulation times (BC)

close all, clear variables
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
imagesc(zproject)
colormap gray
title('average z-projection')
xlim([0 info.DimensionX])
ylim([0 info.DimensionY])
axis image

fprintf('select the whole cell using the mouse. double click when done:  ')
[cellMask cellX cellY] = roipoly;
fprintf('done\n')

fprintf('\nselect just the nucleus to be excluded:  ')
[nucMask nucX nucY] = roipoly;
fprintf('done\n')

fprintf('\nselect area surrounding the cell to be used as background:  ')
[bigMask bigX bigY] = roipoly;
fprintf('done\n')

somaMask = cellMask&~nucMask;
surrMask = bigMask&~cellMask;
somaShow = uint8(somaMask);
surrShow = uint8(surrMask);

%% calculate fluorescence intensity for each frame

% threshold = nan(numFrames,1);
somaF = nan(numFrames,1);
surrF = nan(numFrames,1);
ROIF = nan(numFrames,1);

for i=1:numFrames
    fprintf('analyzing:  %s frame %3.0f\n', fname,i)
    imFrame = imData(:,:,i);
    
    % calculate and store ROIF of each frame
    pixROI = imFrame(somaMask);
    somaF(i) = mean(pixROI);
    pixSurr = imFrame(surrMask);
    surrF(i) = mean(pixSurr);
    ROIF(i) = somaF(i)-0.5*surrF(i); %0.5 came from Kerlin et al, 2010
        
    % show each frame
    imROI = imFrame.*somaShow;
        
    figure(2)
    set(gcf,'Name',[' frame ' num2str(i) ' of ' num2str(numFrames)])
    subplot(1,2,1)
    imagesc(imFrame)
    title('raw image')
    axis image
    subplot(1,2,2)
    imagesc(imROI)
    title('ROI image')
    axis image
end

time = info.TimeStamps.TimeStamps; % in s
%% save

save('raw cellIntensity.mat')

%% plot

figure(3)

subplot(3,1,2)
area([1 3], [150 150],'FaceColor','y'),hold on %shading stimuli
area([14 16], [150 150],'FaceColor','y'),
area([27 29], [150 150],'FaceColor','y'), 
area([40 42], [150 150],'FaceColor','y'),
area([53 55], [150 150],'FaceColor','y'),
area([66 68], [150 150],'FaceColor','y'),
area([79 81], [150 150],'FaceColor','y'),
area([92 94], [150 150],'FaceColor','y'),
area([105 107], [150 150],'FaceColor','y'),
area([118 120], [150 150],'FaceColor','y'),
plot(time,ROIF,'k.',time,smooth(ROIF),'b-')
xlabel('time (s)')
ylabel('mean fluorescence intensity (a.u.)')
title(['soma-nucleus-background of ' num2str(fname) ' (' num2str(numFrames) ' frames)'])

print(figure(1),'-dpdf','ROI')
print(figure(3),'-dpdf','raw cellIntensity')