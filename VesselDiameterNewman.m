% Capillary_Diameter_and_Flux.m
% 21 May 2012
% Measures the diameter and flux of a capilary as function of time
% Can read 8-bit or 16-bit B/W tiff line scan confocal images
% Graphs diameter vs time, and flux vs time, writes table of graph, measures peak change in
% diameter and flux and indicates edges of vessel and each RBC on original line scan image

% The following files should be placed in the 'c:\MATLAB_Programs' directory:
%
% VesselDiameter_Parameters.mat  saves parameters from program
%




function VesselDiameterCMS

global PathName
global FileName
global RootFileName
global ReadNextFileFlag
global Num_Rows
global Num_Columns
global RawLineScan
global ProcessedLineScan
global ProcessedLineScanAndStim
global TimeValueVector
global VesselDiameterVector
global GraphFigure
global Plot_Handle
global ModifiedModifiedVesselDiameterVector
global AveragedVesselDiameterVector
global NumAveragedTraces
global ModifiedTimeValueVector
global PeakValueText
global BaselineLineHandle
global PeakValueHandle
global BaselineText
global Write_Diameter_Array
global Write_Flux_Array
global low
global high
global ScaleFactor
global LineLengthValue
global IntensityStartPositionValue
global IntensityEndPositionValue
global StimulusVector
global FluxVector
global ScrollStartValue
global ScrollEndValue
global FluxThresholdValue
global FluxMinWidthValue




% parameters that are saved in .mat file
global TrialDurationValue
global um_pixelValue
global MagFactorValue
global NumHighLowPixelsValue
global SpatialAverageValue
global TemporalAverageValue
global ThresholdValue





% Loads .mat file that contains parameter values in structure form
ParameterStructure = load('Single_VesselDiameter_Parameters.mat','TrialDurationValue',...
            'um_pixelValue','MagFactorValue','NumHighLowPixelsValue','SpatialAverageValue',...
            'TemporalAverageValue','ThresholdValue','DelayValue','BurstWidthValue','PulseDurationValue','PulsePeriodValue','NumVesselsValue');



% Initialize paramater values
IntensityStartPositionValue = 0;
IntensityEndPositionValue = 1;
ReadNextFileFlag = 0;





% Root Window
RootFigure = figure('Name','Capillary Diameter and Flux','NumberTitle','off','Color','white','Position',[10,15,500,1000]);

% Open File Button
OpenFileButton = uicontrol('Style','PushButton','String','Open File','Position',[40,960,70,30],...
    'CallBack', @ReadFile);

% Open Next File Button
OpenNextFileButton = uicontrol('Style','PushButton','String','Open Next File','Position',[40,926,85,30],...
    'CallBack', @ReadNextFile);

% Close all graph window figures Button
CloseFiguresButton = uicontrol('Style','PushButton','String',' Close figs','Position',[40,890,85,30],...
    'CallBack', @CloseFigures);

% Displays start and stop values of scroll window
ScrollWindowValuesButton = uicontrol('Style','PushButton','String',' Scroll Wnd Vals','Position',[130,890,85,30],...
    'CallBack', @ScrollWindowValues);

ScrollStart = uicontrol('Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[220 893 50 23]);

ScrollStartValue = 0;
temp_string = num2str(ScrollStartValue);
set(ScrollStart,'string',temp_string);

ScrollEnd = uicontrol('Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[273 893 50 23]);

ScrollEndValue = 0;
temp_string = num2str(ScrollEndValue);
set(ScrollEnd,'string',temp_string);



% Name of File
DisplayFileName = uicontrol('Style','Text','BackgroundColor',[1 1 1],...
    'FontSize', 12,'Position',[110,960,280,30]);

% Save parameters Button
SaveParam = uicontrol('Style','PushButton','String','Save parameters','Position',[400,960,90,30],...
    'CallBack', @SaveParameters);



% Shift StimulusVector up
StimulusVectorUpButton = uicontrol('Style','PushButton','String','up','Position',[450,910,35,25],...
    'CallBack', @StimulusVectorUp);

% Shift StimulusVector up
StimulusVectorDownButton = uicontrol('Style','PushButton','String','down','Position',[450,880,35,25],...
    'CallBack', @StimulusVectorDown);






% Reject Artifact Panel Controls
StimArtifactPanel = uipanel('Title','Stimulus Artifact','FontSize',12,...
    'BackgroundColor','white',...
    'Units','pixels','Position',[25 710 200 170]);

StimArtifactRejectMode = uibuttongroup('Parent',StimArtifactPanel,'Units','pixels','BackgroundColor','white',...
    'BorderType', 'none','Position',[0 120 120 30]);

uicontrol('parent',StimArtifactRejectMode, 'Style','Radio','String','Normal','FontSize',12,...
    'BackgroundColor','white','Position',[5 0 70 30]);

RejectArtifactsMode = uicontrol('parent',StimArtifactRejectMode, 'Style','Radio','String','Rej Artifacts','FontSize',12,...
    'BackgroundColor','white','Position',[80 0 110 30]);


DelayLabel = uicontrol('Parent',StimArtifactPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','delay (s)',...
    'Position',[5 95 130 23]);

Delay = uicontrol('Parent',StimArtifactPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 95 50 23]);

DelayValue = ParameterStructure.DelayValue;
temp_string = num2str(DelayValue);
set(Delay,'string',temp_string);

BurstWidthLabel = uicontrol('Parent',StimArtifactPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','burst width (s)',...
    'Position',[5 65 130 23]);

BurstWidth = uicontrol('Parent',StimArtifactPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 65 50 23]);

BurstWidthValue = ParameterStructure.BurstWidthValue;
temp_string = num2str(BurstWidthValue);
set(BurstWidth,'string',temp_string);

PulseDuationLabel = uicontrol('Parent',StimArtifactPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','pulse duration (s)',...
    'Position',[5 35 130 23]);

PulseDuration = uicontrol('Parent',StimArtifactPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 35 50 23]);

PulseDurationValue = ParameterStructure.PulseDurationValue;
temp_string = num2str(PulseDurationValue);
set(PulseDuration,'string',temp_string);

PulsePeriodLabel = uicontrol('Parent',StimArtifactPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','pulse period (s)',...
    'Position',[5 5 130 23]);

PulsePeriod = uicontrol('Parent',StimArtifactPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 5 50 23]);

PulsePeriodValue = ParameterStructure.PulsePeriodValue;
temp_string = num2str(PulsePeriodValue);
set(PulsePeriod,'string',temp_string);






% Graph Diameter Panel Controls
GraphDiameterPanel = uipanel('Title','Graph vessel diameter','FontSize',12,...
    'BackgroundColor','white',...
    'Units','pixels','Position',[25 300 200 405]);

NumVesselsLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','num vessels',...
    'Position',[5 350 130 23]);

NumVessels = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 350 50 23]);

NumVesselsValue = ParameterStructure.NumVesselsValue;
temp_string = num2str(NumVesselsValue);
set(NumVessels,'string',temp_string);

TrialDurationLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','trial dur (s)',...
    'Position',[5 320 130 23]);

TrialDuration = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 320 50 23]);

TrialDurationValue = ParameterStructure.TrialDurationValue;
temp_string = num2str(TrialDurationValue);
set(TrialDuration,'string',temp_string);

um_PixelLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','um/pixel',...
    'Position',[5 290 130 23]);

um_pixel = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 290 50 23]);

um_pixelValue = ParameterStructure.um_pixelValue;
temp_string = num2str(um_pixelValue);
set(um_pixel,'string',temp_string);

MagFactorLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','mag factor',...
    'Position',[5 260 130 23]);

MagFactor = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 260 50 23]);

MagFactorValue = ParameterStructure.MagFactorValue;
temp_string = num2str(MagFactorValue);
set(MagFactor,'string',temp_string);


% The Mag factor corrects for the extra magnification of the rats eye
% The FluoView Program should be set to the 40X objective
MagFactorNoteLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',8,...
    'string','4X > 6.9; 10X > 2.8',...
    'Position',[0 235 190 23]);


NumHighLowPixelsLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','# high/low pixels',...
    'Position',[5 220 130 23]);

NumHighLowPixels = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 220 50 23]);

NumHighLowPixelsValue = ParameterStructure.NumHighLowPixelsValue;
temp_string = num2str(NumHighLowPixelsValue);
set(NumHighLowPixels,'string',temp_string);


SpatialAverageLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','spatial av (pixels)',...
    'Position',[5 190 130 23]);

SpatialAverage = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 190 50 23]);

SpatialAverageValue = ParameterStructure.SpatialAverageValue;
temp_string = num2str(SpatialAverageValue);
set(SpatialAverage,'string',temp_string);


TemporalAverageLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','temporal av (s)',...
    'Position',[5 160 130 23]);

TemporalAverage = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 160 50 23]);

TemporalAverageValue = ParameterStructure.TemporalAverageValue;
temp_string = num2str(TemporalAverageValue);
set(TemporalAverage,'string',temp_string);



ThresholdLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','diam thresh (0-1)',...
    'Position',[5 130 130 23]);

ThresholdInput = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 130 50 23]);

ThresholdValue = ParameterStructure.ThresholdValue;
temp_string = num2str(ThresholdValue);
set(ThresholdInput,'string',temp_string);




FluxThresholdLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','flux thresh (0-1)',...
    'Position',[5 100 130 23]);

FluxThresholdInput = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 100 50 23]);

FluxThresholdValue = 0.4;
temp_string = num2str(FluxThresholdValue);
set(FluxThresholdInput,'string',temp_string);




FluxMinWidthLabel = uicontrol('Parent',GraphDiameterPanel,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','flux min width',...
    'Position',[5 70 130 23]);

FluxMinWidthInput = uicontrol('Parent',GraphDiameterPanel,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[140 70 50 23]);

FluxMinWidthValue = 4;
temp_string = num2str(FluxMinWidthValue);
set(FluxMinWidthInput,'string',temp_string);



GraphButton = uicontrol('Parent',GraphDiameterPanel,'Style','PushButton','String','Graph',...
    'Position',[17,5,60,25],...
    'CallBack', @GraphDiameter);





% Average graphs
AverageGraphsControls = uipanel('Title','Average graphs','FontSize',12,...
    'BackgroundColor','white',...
    'Units','pixels','Position',[25 165 200 130]);

% Label = uicontrol('Parent',AverageGraphsControls,'Style','text',...
%     'BackgroundColor','white','FontSize',10,...
%     'string','do not use "Reject Artifacts"',...
%     'Position',[10 100 180 25]);

AddTraceButton = uicontrol('Parent',AverageGraphsControls,'Style','PushButton',...
    'Position',[10,80,100,25],...
    'string','Add graph','CallBack', @AddTrace);

NumTracesLabel = uicontrol('Parent',AverageGraphsControls,'Style','text',...
    'BackgroundColor','white','FontSize',12,...
    'string','# traces',...
    'Position',[115 75 80 23]);

NumTraces = uicontrol('Parent',AverageGraphsControls,'Style','edit',...
    'BackgroundColor','white','FontSize',12,...
    'Units','pixels','Position',[130 50 50 23]);

temp_string = num2str(NumAveragedTraces);
set(NumTraces,'string',temp_string);


DisplayAverageButton = uicontrol('Parent',AverageGraphsControls,'Style','PushButton',...
    'Position',[10,45,100,25],...
    'string','Display average','CallBack', @DisplayAverage);

ClearButton = uicontrol('Parent',AverageGraphsControls,'Style','PushButton',...
    'Position',[10,10,100,25],...
    'string','Clear','CallBack', @Clear);







% Write Files
WriteFilesControls = uipanel('Title','Write files','FontSize',12,...
    'BackgroundColor','white',...
    'Units','pixels','Position',[25 90 200 70]);

WriteGraphButton = uicontrol('Parent',WriteFilesControls,'Style','PushButton',...
    'Position',[10,22,100,25],...
    'string','Current graph(s)','CallBack', @WriteGraph);

Label = uicontrol('Parent',WriteFilesControls,'Style','text',...
    'BackgroundColor','white','FontSize',8,...
    'string','-Vessel_Diam.txt',...
    'Position',[0 6 120 13]);



% Graph Pericyte Diameter
GraphIntensityControls = uipanel('Title','Graph pericyte diameter','FontSize',12,...
    'BackgroundColor','white',...
    'Units','pixels','Position',[25 10 200 70]);


GraphPercyteButton = uicontrol('Parent',GraphIntensityControls,'Style','PushButton',...
    'Position',[30,13,100,25],...
    'string','Graph Intensity','CallBack', @GraphPericye);





% sets up initial scroll panel to display line scan images
% image with white pixels displayed
ProcessedLineScan = ones(900,100).*255;
DisplayedImageHandle = imshow(ProcessedLineScan);
ScrollPanelHandle = imscrollpanel(RootFigure,DisplayedImageHandle);
set(ScrollPanelHandle,'Units','pixels','Position',[240 50 240 820]);


%Retrives and Displays Scroll Bar Location
    function ScrollWindowValues(h, eventdata)
        scrollapi = iptgetapi(ScrollPanelHandle);
        
        %Returns the location of the currently visible portion of the target image
        % 2nd and 4th values are begin Y location and Y length
        location = scrollapi.getVisibleImageRect();  
        
        TimePerRow = TrialDurationValue / Num_Rows;
        ScrollStartValue = location(2) * TimePerRow;
        ScrollEndValue = (location(2) + location(4)) * TimePerRow;
        
        temp_string = num2str(ScrollStartValue,'%.1f');
        set(ScrollStart,'string',temp_string);
        
        temp_string = num2str(ScrollEndValue,'%.1f');
        set(ScrollEnd,'string',temp_string);
    end


    
% Initializes parameters for averaging traces
AveragedVesselDiameterVector = 0;
NumAveragedTraces = 0;



msgbox('Enter stimulus parameters (with 3 significant figures) before opening line scan file. Use up and down buttons to align artifact with the stimulus. Number of vessels = 1.', 'General instructions');



    function ReadNextFile(h, eventdata)
        ReadNextFileFlag = 1;
        ReadFile();
    end



    function ReadFile(h, eventdata)
        if ReadNextFileFlag == 0
            % opens dialogue box to choose file
            [FileName,PathName] = uigetfile('*.tif','Select TIFF file');
            cd(PathName);
        else
            % increment path by 1
            NumOfChar = size(PathName);
            NumOfChar = NumOfChar(2);      % take second element of matrix
            EndOfPathName = PathName((NumOfChar-11):NumOfChar); % extract last 12 characters
            BeginningOfPathName = PathName(1:(NumOfChar-15)); % extract first characters
            FileNumber = PathName((NumOfChar-14):(NumOfChar-12)); % extract next 3 characters
            TempNum = str2double(FileNumber);    % convert to number
            TempNum = TempNum + 1;
            TempNumStr = int2str(TempNum);     % convert to str
            if TempNum < 10   % add extra 0's
                TempNumStr = ['0' '0' TempNumStr];
            else
                TempNumStr = ['0' TempNumStr];
            end
            
            PathName = [BeginningOfPathName TempNumStr EndOfPathName];   % Concatonate parts of path name
            
            cd(PathName);
            
            % increment file name by 1
            BeginningOfFileName = FileName(1:7);
            EndOfFileName = FileName(11:19);
            
            FileName = [BeginningOfFileName TempNumStr EndOfFileName];     % Concatonate parts of file name
        end
        
        % reset flag
        ReadNextFileFlag = 0;
        
        [pathstr, name, ext] = fileparts(FileName);
        RootFileName = name;

        % displays file name at top
        set(DisplayFileName,'String', FileName);


        % reads file
        RawLineScan = imread(FileName);

        % This may correct a bug where the Olympus confocal program thinks
        % the file is still open
        status = fclose('all');

        % Retrieve dimensions of image
        [Num_Rows,Num_Columns] = size(RawLineScan);
        
        % rescale image between min and max
        low = double(min(RawLineScan(:))); 
        high = double(max(RawLineScan(:)));
        ScaleFactor = 255/(high-low);
        % rescale and convert to 8-bit if image was 16 bit
        ProcessedLineScan = uint8(ScaleFactor.*(RawLineScan - low));
        
        RejectArtifactsModeFlag = get(RejectArtifactsMode,'Value');
        if RejectArtifactsModeFlag == 1
            GenerateStimVector();
        else
            StimulusVector = zeros(Num_Rows,1,'uint8');
        end
        
        % make StimulusVector 8 col wide
        StimulusVectorWide = [StimulusVector StimulusVector StimulusVector StimulusVector];
        StimulusVectorWide = [StimulusVectorWide StimulusVectorWide];
        StimulusVectorWide = StimulusVectorWide .* 255;
        
        BlackLine = zeros(Num_Rows,4,'uint8');
        
        if RejectArtifactsModeFlag == 1
            ProcessedLineScanAndStim = [ProcessedLineScan StimulusVectorWide BlackLine];
        else
            ProcessedLineScanAndStim = ProcessedLineScan;
        end


        DisplayLineScan();
        ScrollWindowValues();
        
        
        % calculates length of line scan line in um
        um_pixelValue = str2double(get(um_pixel,'string'));
        MagFactorValue = str2double(get(MagFactor,'string'));

        LineLengthValue = Num_Columns * (um_pixelValue * MagFactorValue);
     end


    function StimulusVectorUp(h, eventdata)
        StimulusVector = circshift(StimulusVector,-1);
        
        StimulusVectorWide = [StimulusVector StimulusVector StimulusVector StimulusVector];
        StimulusVectorWide = [StimulusVectorWide StimulusVectorWide];
        StimulusVectorWide = StimulusVectorWide .* 255;
        
        BlackLine = zeros(Num_Rows,4,'uint8');
        
        ProcessedLineScanAndStim = [ProcessedLineScan StimulusVectorWide BlackLine];

        DisplayLineScan();
    end

    function StimulusVectorDown(h, eventdata)
        StimulusVector = circshift(StimulusVector,1);
        
        StimulusVectorWide = [StimulusVector StimulusVector StimulusVector StimulusVector];
        StimulusVectorWide = [StimulusVectorWide StimulusVectorWide];
        StimulusVectorWide = StimulusVectorWide .* 255;
        
        BlackLine = zeros(Num_Rows,4,'uint8');
        
        ProcessedLineScanAndStim = [ProcessedLineScan StimulusVectorWide BlackLine];

        DisplayLineScan();
    end






    function GenerateStimVector(h, eventdata)
        StimulusVector = zeros(Num_Rows,1,'uint8');
        
        TrialDurationValue = str2double(get(TrialDuration,'string'));
        DelayValue = str2double(get(Delay,'string'));
        BurstWidthValue = str2double(get(BurstWidth,'string'));
        PulseDurationValue = str2double(get(PulseDuration,'string'));
        PulsePeriodValue = str2double(get(PulsePeriod,'string'));
        
        TimeRowFactor = Num_Rows / TrialDurationValue;
        
        DelayValueRows = DelayValue * TimeRowFactor;
        BurstWidthValueRows = BurstWidthValue * TimeRowFactor;
        PulseDurationValueRows = PulseDurationValue * TimeRowFactor;
        PulsePeriodValueRows = PulsePeriodValue * TimeRowFactor;
        
        % generates StimulusVector where values are 1 when stimulus
        % light is on
        % adds 2 extra rows before and after each stimulus
        for row = round(DelayValueRows):round(DelayValueRows + BurstWidthValueRows + PulseDurationValueRows)
            PeriodCounter = mod((row - round(DelayValueRows)),PulsePeriodValueRows);  % modulus function
            if PeriodCounter <= (PulseDurationValueRows + 4)
                StimulusVector(row - 2) = 1;
            end
        end
    end



   


    function DisplayLineScan(h, eventdata)
        % New line scan image is drawn within existing scroll panel
        api = iptgetapi(ScrollPanelHandle);
        api.replaceImage(ProcessedLineScanAndStim);
    end





    function GraphDiameter(h, eventdata)
        TemporalAverageValue = str2double(get(TemporalAverage,'string'));
        TrialDurationValue = str2double(get(TrialDuration,'string'));
        
        RejectArtifactsModeFlag = get(RejectArtifactsMode,'Value');

        clear TimeValueVector;
        for row=1:Num_Rows
            TimeValueVector(row) = row * TrialDurationValue / Num_Rows;
        end

        
        
        % Calculate Intensity_Vector containing sum of each row vs row
        % number
        Intensity_Vector = ones(Num_Rows,1);
        for row=1:Num_Rows
            Intensity_Vector(row) = sum(ProcessedLineScan(row,:));
        end
        
       
       
        %Threshold Intensity_Vector
        No_RBC_Vector = zeros(Num_Rows,1);
        for row=1:Num_Rows
            
            % Calculate local threshold
            % Calculate average of 1000 row, ensuring that there are no
            % boundary conflicts
            
            BeginRow = row - 500;
            if BeginRow < 1
                BeginRow = 1;
            end
            
            EndRow = row + 500;
            if EndRow > Num_Rows
                EndRow =Num_Rows;
            end
            
            Intensity_Vector_Subset = Intensity_Vector(BeginRow:EndRow);
            Sorted_Intensity_Vector_Subset = sort(Intensity_Vector_Subset,'descend');
            
            num_row_subset = size(Sorted_Intensity_Vector_Subset);
            
            % Calculate max and min by taking top and bottom 20%
            Max = mean(Sorted_Intensity_Vector_Subset(1:round(num_row_subset/5)));
            Min = mean(Sorted_Intensity_Vector_Subset((num_row_subset-round(num_row_subset/5)):num_row_subset));
            
            
            FluxThresholdValue = str2double(get(FluxThresholdInput,'string'));
                 
            % Calculate threshold as 60% between max and min
            Threshold = Min + (Max - Min) * FluxThresholdValue ;
            
            if Intensity_Vector(row) > Threshold
                No_RBC_Vector(row) = 1;
            end
        end
        
        % Display line scan and threshholded image
        % make separator line 3 columns wide
        BlackLine = zeros(Num_Rows,3);
        ProcessedLineScanAndStim = [ProcessedLineScanAndStim No_RBC_Vector*255 No_RBC_Vector*255 No_RBC_Vector*255 No_RBC_Vector*255 No_RBC_Vector*255 BlackLine];
        
        DisplayLineScan();
        
% CALCULATE DIAMETER
% CALCULATE DIAMETER  
        % spacial average line scan image horizontally if spatial average value > 0
        SpatialAverageValue = str2double(get(SpatialAverage,'string'));
        if logical(SpatialAverageValue) > 0

            ProcessedLineScan = RawLineScan;

            NHOOD = ones(1,SpatialAverageValue);

            ProcessedLineScan = conv2(RawLineScan, NHOOD, 'same');
            ProcessedLineScan = (ProcessedLineScan./(SpatialAverageValue));
            % rescale and convert to 8-bit if image was 16 bit
            ProcessedLineScan = uint8(ScaleFactor.*(ProcessedLineScan - low));
        else   %use original, unaveraged linescan
            ProcessedLineScan = RawLineScan;
            % rescale and convert to 8-bit if image was 16 bit
            ProcessedLineScan = uint8(ScaleFactor.*(ProcessedLineScan - low));

        end



        % NumHighLowPixels is the nth highest or lowest value to use as
        % high and low values
        NumHighLowPixelsValue = str2double(get(NumHighLowPixels,'string'));

        % find edges of vessel for each row of line scan image
        % loop over each row of line scan image
        
        % preallocates vectors
        % VesselDiameterVector = ones(1,Num_Rows);
        LeftEdgeVector = ones(1,Num_Rows);
        RightEdgeVector = ones(1,Num_Rows);
        clear VesselDiameterVector;
        VesselDiameterVector = ones(1,Num_Rows);
        
   
        
        for row=1:Num_Rows
            % Does not measure diameter if No_RBC_Vector(row) is 0
               % OR the stimulus is on and reject artifact flag  is selected
            % then, set the diameter of that row to the mean of the last 10 rows
            if(((No_RBC_Vector(row) == 0) && (row>11)) || ((StimulusVector(row) == 1)) && (RejectArtifactsModeFlag == 1) && (row>11))
                VesselDiameterVector(row) = mean(VesselDiameterVector((row-11):(row-1)));
                
                % puts red dots on right edge of image if row n is rejected
                LeftEdgeVector(row) = Num_Columns;
                RightEdgeVector(row) = Num_Columns;

            else
                Sorted = sort(ProcessedLineScan(row,:),'descend');
                XLargest = Sorted(1:NumHighLowPixelsValue);
                XSmallest = Sorted(Num_Columns - NumHighLowPixelsValue:Num_Columns);
                
                % threshold can be set between 0.0 and 1.0 
                % from the dimmest to brightest pixel value
                
                % get threshold value
                ThresholdValue = str2double(get(ThresholdInput,'string'));
                
                % Calculate threshold
                Threshold = mean(XSmallest) + ThresholdValue*(mean(XLargest) - mean(XSmallest));
                
                % find left edge of vessel
                for col=1:Num_Columns
                    Pixelvalue = ProcessedLineScan(row,col);
                    LeftEdgePixel = col;
                    if Pixelvalue > Threshold, break, end
                end
                
                % find right edge of vessel
                for col=Num_Columns:-1:1
                    Pixelvalue = ProcessedLineScan(row,col);
                    RightEdgePixel = col;
                    if Pixelvalue > Threshold, break, end
                end
                
                VesselDiameterVector(row) = RightEdgePixel - LeftEdgePixel;
                
                % creates vectors containing positions of edges of vessel
                LeftEdgeVector(row) = LeftEdgePixel;
                RightEdgeVector(row) = RightEdgePixel;
            end
        end

        % creates a 3D array, an RGB copy of the line scan array
        RGBLineScan = repmat(ProcessedLineScanAndStim,[1 1 3]);
        
        % inserts red dots (255,0,0) at the edges of the vessel for each row of the
        % line scan
        for row=1:Num_Rows
            RGBLineScan(row,LeftEdgeVector(row),1) = 255;
            RGBLineScan(row,LeftEdgeVector(row),2) = 0;
            RGBLineScan(row,LeftEdgeVector(row),3) = 0;
            
            RGBLineScan(row,RightEdgeVector(row),1) = 255;
            RGBLineScan(row,RightEdgeVector(row),2) = 0;
            RGBLineScan(row,RightEdgeVector(row),3) = 0;
        end
        
        
        % displays the same line scan with edges of vessel marked by red
        % dots
        % New line scan image is drawn within existing scroll panel
        api = iptgetapi(ScrollPanelHandle);
        api.replaceImage(RGBLineScan);
        
        
% CALCULATE FLUX
% CALCULATE FLUX        
        % initialize FluxVector
        WidthVector = zeros(Num_Rows,1);
        % create width vector
        Width = 0;
        for row=1:Num_Rows
            if No_RBC_Vector(row) == 0
                Width = Width + 1;
            else
                WidthVector(row) = Width;
                Width = 0;
            end
        end
        
       
        
        % remove any events where width is < MinWidth

        FluxMinWidthValue = str2double(get(FluxMinWidthInput,'string'));
        
        
        MinWidth = FluxMinWidthValue;
        FluxVector = WidthVector;
        FluxVector(FluxVector < MinWidth) = 0;
        
        % set all width values to 1
        FluxVector(FluxVector > 0) = 1;
        
        
        % make flux display 10 columns wide
        FluxVectorDisplay = FluxVector .*255;
        FluxVectorDisplay = repmat(FluxVectorDisplay,1,10);
        % make FluxVector by RGB
        FluxVectorDisplay_RGB = repmat(FluxVectorDisplay,[1 1 3]);
        FluxVectorDisplay_RGB(:,:,2) = 0;
        FluxVectorDisplay_RGB(:,:,3) = 0;

        % concatinate the  arrays horizontally
        RGB_Display = [RGBLineScan  FluxVectorDisplay_RGB];
        % RGBLineScan_Diameter
        
        % displays the same line scan with edges of vessel marked by red
        % dots
        % New line scan image is drawn within existing scroll panel
        api = iptgetapi(ScrollPanelHandle);
        api.replaceImage(RGB_Display);
        
        DisplayDiameterGraph();
        
        DisplayFluxGraph();
    end







    function DisplayDiameterGraph(h, eventdata)

        % make new figure (window) for graph
        GraphFigure = figure('Name','Vessel diameter','NumberTitle','off','Color','white',...
            'Position',[650,550,750,400]);
        
        % Name of File
        DisplayGraphFileName = uicontrol('Parent',GraphFigure,'Style','Text','String',FileName,...
            'BackgroundColor',[1 1 1],...
         'FontSize', 12,'Position',[110,360,280,30]);

        CursorsOn = uicontrol('Parent',GraphFigure,'Style','PushButton','String','cursors',...
            'Position',[5,365,60,25],...
            'CallBack', @MeasurePeak);

        CalculatePeakButton = uicontrol('Parent',GraphFigure,'Style','PushButton','String','calculate',...
            'Position',[5,335,60,25],...
            'CallBack', @CalculatePeak);

        PeakValueText = uicontrol('Parent',GraphFigure,'Style','text','String','',...
            'FontSize', 12,'Position',[5,305,50,25],'backgroundcolor','white');

        PeakValueTextLabel = uicontrol('Parent',GraphFigure,'Style','text','String','% change',...
            'FontSize', 8,'Position',[55,302,60,25],'backgroundcolor','white');


        BaselineText = uicontrol('Parent',GraphFigure,'Style','text','String','',...
            'FontSize', 12,'Position',[5,280,50,25],'backgroundcolor','white');

        BaselineTextLabel = uicontrol('Parent',GraphFigure,'Style','text','String','baseline (um)',...
            'FontSize', 8,'Position',[55,280,60,25],'backgroundcolor','white');






        TemporalAverageValue = str2double(get(TemporalAverage,'string'));
        TrialDurationValue = str2double(get(TrialDuration,'string'));
        
        RejectArtifactsModeFlag = get(RejectArtifactsMode,'Value');

        
        % Edit out rows with diameter < 2
        EditedVesselDiameterVector = ones(1,Num_Rows); 
        EditedTimeValueVector = ones(1,Num_Rows);
        
        % clear and initialize edited vectors
        clear EditedVesselDiameterVector;
        clear EditedTimeValueVector;
        EditedVesselDiameterVector = VesselDiameterVector(1);
        EditedTimeValueVector = TimeValueVector(1) ;
        
        for row=1:Num_Rows
            if ((VesselDiameterVector(row) < 2) && (RejectArtifactsModeFlag == 1))  % skip row.  NOTE, this should not occur becuase code was modified
            else    %add row value to end of vectors
                EditedVesselDiameterVector = [EditedVesselDiameterVector  VesselDiameterVector(row)];
                EditedTimeValueVector = [EditedTimeValueVector  TimeValueVector(row)] ;
            end
            
        end

        % Do not temporal average if value is zero
        if logical(TemporalAverageValue) == 0
            ModifiedVesselDiameterVector = EditedVesselDiameterVector;
            ModifiedTimeValueDiameterVector = EditedTimeValueVector;
        % if temporal average is non-zero, do running average of values
        else
            TimeConstantInRows = TemporalAverageValue * Num_Rows / TrialDurationValue;
            TimeConstantInRows = round(TimeConstantInRows);

            if TimeConstantInRows < 1
                TimeConstantInRows = 1;  % this prevents the filter function from crashing
            end
            
            NHOOD = ones(1,TimeConstantInRows)/TimeConstantInRows;  % make array for convolution
            % filter function does running average
            ModifiedVesselDiameterVector = filter(NHOOD,1,EditedVesselDiameterVector);


            %remove first n frames of averaged image to eliminate boundary
            %artifact
            ModifiedVesselDiameterVector = ModifiedVesselDiameterVector(TimeConstantInRows:end);
            ModifiedTimeValueDiameterVector = EditedTimeValueVector(TimeConstantInRows:end);


        end

        % convert ModifiedVesselDiameterVector into true um
        um_pixelValue = str2double(get(um_pixel,'string'));
        MagFactorValue = str2double(get(MagFactor,'string'));

        ModifiedModifiedVesselDiameterVector = ModifiedVesselDiameterVector * (um_pixelValue*MagFactorValue);


        % create axes to obtain handle for graph
        Plot_Handle = axes('Parent',GraphFigure,'Units','pixels','Position',[145 50 600 300]);
        plot(ModifiedTimeValueDiameterVector,ModifiedModifiedVesselDiameterVector);

        % make new arrray with 2 rows. Transpose to array with 2 columns
        Write_Diameter_Array = [ModifiedTimeValueDiameterVector ; ModifiedModifiedVesselDiameterVector]';

    end


    function DisplayFluxGraph(h, eventdata)

        % make new figure (window) for graph
        GraphFigure = figure('Name','Blood flux','NumberTitle','off','Color','white',...
            'Position',[650,100,750,400]);
        
        % Name of File
        DisplayGraphFileName = uicontrol('Parent',GraphFigure,'Style','Text','String',FileName,...
            'BackgroundColor',[1 1 1],...
         'FontSize', 12,'Position',[110,360,280,30]);

        CursorsOn = uicontrol('Parent',GraphFigure,'Style','PushButton','String','cursors',...
            'Position',[5,365,60,25],...
            'CallBack', @MeasurePeak);

        CalculatePeakButton = uicontrol('Parent',GraphFigure,'Style','PushButton','String','calculate',...
            'Position',[5,335,60,25],...
            'CallBack', @CalculatePeak);

        PeakValueText = uicontrol('Parent',GraphFigure,'Style','text','String','',...
            'FontSize', 12,'Position',[5,305,50,25],'backgroundcolor','white');

        PeakValueTextLabel = uicontrol('Parent',GraphFigure,'Style','text','String','% change',...
            'FontSize', 8,'Position',[55,302,60,25],'backgroundcolor','white');


        BaselineText = uicontrol('Parent',GraphFigure,'Style','text','String','',...
            'FontSize', 12,'Position',[5,280,50,25],'backgroundcolor','white');

        BaselineTextLabel = uicontrol('Parent',GraphFigure,'Style','text','String','RBCs per sec',...
            'FontSize', 8,'Position',[55,280,60,25],'backgroundcolor','white');






        TemporalAverageValue = str2double(get(TemporalAverage,'string'));
        TrialDurationValue = str2double(get(TrialDuration,'string'));
        
 
        % Do not temporal average if value is zero
        if logical(TemporalAverageValue) == 0
            ModifiedFluxVector = FluxVector;
            ModifiedTimeValueFluxVector = TimeValueVector;
        % if temporal average is non-zero, do running average of values
        else          
            TimeConstantInRows = floor(TemporalAverageValue * Num_Rows / TrialDurationValue);
            
            if TimeConstantInRows < 1
                TimeConstantInRows = 1;  % this prevents the filter function from crashing
            end
            
            NHOOD = ones(1,TimeConstantInRows);  % make array for convolution
            % filter function does running average
            ModifiedFluxVector = filter(NHOOD,1,FluxVector);

            %remove first n frames of averaged image to eliminate boundary
            %artifact
            ModifiedFluxVector = ModifiedFluxVector(TimeConstantInRows:end);
            ModifiedTimeValueFluxVector = TimeValueVector(TimeConstantInRows:end);
        end
        
        ModifiedFluxVector = ModifiedFluxVector';
        ModifiedFluxVector = ModifiedFluxVector ./ TemporalAverageValue ;
       
        
        % create axes to obtain handle for graph
        Plot_Handle = axes('Parent',GraphFigure,'Units','pixels','Position',[145 50 600 300]);
        plot(ModifiedTimeValueFluxVector,ModifiedFluxVector);

        % make new arrray with 2 rows. Transpose to array with 2 columns
        Write_Flux_Array = [ModifiedTimeValueFluxVector ; ModifiedFluxVector]';
     end




    function MeasurePeak(h, eventdata)

        % calculate mean of first 20% of graph
        BaseLineValue = mean(ModifiedModifiedVesselDiameterVector(1:(Num_Rows/5)));

        % calculate peak; use the  largest values based on total number of points
        OnePercent = uint8(Num_Rows/100);
        if OnePercent < 1
            OnePercent = 1;
        end
        
        Sorted = sort(ModifiedModifiedVesselDiameterVector,'descend');
        PeakValue = mean(Sorted(1:OnePercent));


        % create position arrays for placing the two cursor lines
        % TemporalAverageValue is where the graph begins
        % TrialDurationValue is where the graph ends
        X = [TemporalAverageValue TrialDurationValue];
        Y = [BaseLineValue BaseLineValue];
        BaselineLineHandle = imline(Plot_Handle,X,Y);

        X = [TemporalAverageValue TrialDurationValue];
        Y = [PeakValue PeakValue];
        PeakValueHandle = imline(Plot_Handle,X,Y);
        setColor(PeakValueHandle,'red')

    end


    function CalculatePeak(h, eventdata)

        % obtain the y value of the two cursors
        BaselineArray = getPosition(BaselineLineHandle);
        BaseLine = BaselineArray(2,2);

        PeakArray = getPosition(PeakValueHandle);
        Peak = PeakArray(2,2);

        % calculate the percentage change from baseline to peak of the
        % graph
        PeakValueTextValue = 100*(Peak-BaseLine)/BaseLine;
        temp_string = num2str(PeakValueTextValue,'%.1f');
        set(PeakValueText,'string',temp_string);

        PeakValueTextValue = BaseLine;
        temp_string = num2str(PeakValueTextValue,'%.1f');
        set(BaselineText,'string',temp_string);

    end

    function CloseFigures(h, eventdata)
        % closes all figures except the current one
        figs = get(0,'children');
        figs(figs == gcf) = []; % deletes current figure from the list
        close(figs);
    end





    function AddTrace(h, eventdata)
        % counts traces to be averaged
        NumAveragedTraces = NumAveragedTraces + 1;
        AveragedVesselDiameterVector = AveragedVesselDiameterVector + ModifiedModifiedVesselDiameterVector;

        % updates num of traces averaged display
        temp_string = num2str(NumAveragedTraces);
        set(NumTraces,'string',temp_string);
    end




    function DisplayAverage(h, eventdata)
        DisplayAveragedVesselDiameterVector = AveragedVesselDiameterVector./NumAveragedTraces;
        
        
        % make new figure (window) for graph
        GraphFigure = figure('Name','Vessel diameter','NumberTitle','off','Color','white',...
            'Position',[520,200,750,400]);
        
        temp_string = ['Averaged traces ending with' FileName];

        DisplayGraphFileName = uicontrol('Parent',GraphFigure,'Style','Text','String',temp_string,...
            'BackgroundColor',[1 1 1],...
            'FontSize', 12,'Position',[110,360,400,30]);


        CursorsOn = uicontrol('Parent',GraphFigure,'Style','PushButton','String','cursors',...
            'Position',[5,365,60,25],...
            'CallBack', @MeasurePeak);

        CalculatePeakButton = uicontrol('Parent',GraphFigure,'Style','PushButton','String','calculate',...
            'Position',[5,335,60,25],...
            'CallBack', @CalculatePeak);

        PeakValueText = uicontrol('Parent',GraphFigure,'Style','text','String','',...
            'FontSize', 12,'Position',[5,305,50,25],'backgroundcolor','white');

        PeakValueTextLabel = uicontrol('Parent',GraphFigure,'Style','text','String','% change',...
            'FontSize', 8,'Position',[55,302,60,25],'backgroundcolor','white');


        BaselineText = uicontrol('Parent',GraphFigure,'Style','text','String','',...
            'FontSize', 12,'Position',[5,280,50,25],'backgroundcolor','white');

        BaselineTextLabel = uicontrol('Parent',GraphFigure,'Style','text','String','baseline (um)',...
            'FontSize', 8,'Position',[55,280,60,25],'backgroundcolor','white');




        % create axes to obtain handle for graph
        Plot_Handle = axes('Parent',GraphFigure,'Units','pixels','Position',[145 50 600 300]);
        plot(ModifiedTimeValueVector,DisplayAveragedVesselDiameterVector);
        
        % set ModifiedModifiedVesselDiameterVector so that cursor program
        % works properly
        ModifiedModifiedVesselDiameterVector = DisplayAveragedVesselDiameterVector;

        % make new arrray with 2 rows. Transpose to array with 2 columns
        Write_Graph_Array = [ModifiedTimeValueVector ; DisplayAveragedVesselDiameterVector]';      
    end




    function Clear(h, eventdata)
        NumAveragedTraces = 0;
        AveragedVesselDiameterVector = 0;
        
        temp_string = num2str(NumAveragedTraces);
        set(NumTraces,'string',temp_string);

    end








    function WriteGraph(h, eventdata)
        TempFileName = [RootFileName '-Vessel_Diam.txt'];  % concatenate file name
        [FileName,PathName,FilterIndex] = uiputfile(TempFileName);
        ModifiedFileName = [PathName FileName];

        % values delimited by tabs
        dlmwrite(ModifiedFileName, Write_Diameter_Array, 'delimiter', '\t', 'precision', 6);
        
        TempFileName = [RootFileName '-Flux.txt'];  % concatenate file name
        [FileName,PathName,FilterIndex] = uiputfile(TempFileName);
        ModifiedFileName = [PathName FileName];

        % values delimited by tabs
        dlmwrite(ModifiedFileName, Write_Flux_Array, 'delimiter', '\t', 'precision', 6);
    end





    function SaveParameters(h, eventdata)

        % update parameter values before saving
        TrialDurationValue = str2double(get(TrialDuration,'string'));
        um_pixelValue = str2double(get(um_pixel,'string'));
        MagFactorValue = str2double(get(MagFactor,'string'));
        NumHighLowPixelsValue = str2double(get(NumHighLowPixels,'string'));
        SpatialAverageValue = str2double(get(SpatialAverage,'string'));
        TemporalAverageValue = str2double(get(TemporalAverage,'string'));
        ThresholdValue = str2double(get(ThresholdInput,'string'));
        DelayValue = str2double(get(Delay,'string'));
        BurstWidthValue = str2double(get(BurstWidth,'string'));
        PulseDurationValue = str2double(get(PulseDuration,'string'));
        PulsePeriodValue = str2double(get(PulsePeriod,'string'));
        NumVesselsValue = str2double(get(NumVessels,'string'));

        


        save('c:/MATLAB_Programs/Single_VesselDiameter_Parameters.mat','TrialDurationValue',...
            'um_pixelValue','MagFactorValue','NumHighLowPixelsValue','SpatialAverageValue',...
            'TemporalAverageValue','ThresholdValue','DelayValue','BurstWidthValue','PulseDurationValue','PulsePeriodValue','NumVesselsValue')
    end





% This function measures the diamater of a labeled pericyte
% the same way it would measure the diameter of a vessel
    function GraphPericye(h, eventdata)
        TemporalAverageValue = str2double(get(TemporalAverage,'string'));
        TrialDurationValue = str2double(get(TrialDuration,'string'));
        
        RejectArtifactsModeFlag = get(RejectArtifactsMode,'Value');

        clear TimeValueVector;
        for row=1:Num_Rows
            TimeValueVector(row) = row * TrialDurationValue / Num_Rows;
        end


        % average line scan image horizontally if spatial average value > 0
        SpatialAverageValue = str2double(get(SpatialAverage,'string'));
        if logical(SpatialAverageValue) > 0

            ProcessedLineScan = RawLineScan;

            NHOOD = ones(1,SpatialAverageValue);

            ProcessedLineScan = conv2(RawLineScan, NHOOD, 'same');
            ProcessedLineScan = (ProcessedLineScan./(SpatialAverageValue));
            % rescale and convert to 8-bit if image was 16 bit
            ProcessedLineScan = uint8(ScaleFactor.*(ProcessedLineScan - low));
        else   %use original, unaveraged linescan
            ProcessedLineScan = RawLineScan;
            % rescale and convert to 8-bit if image was 16 bit
            ProcessedLineScan = uint8(ScaleFactor.*(ProcessedLineScan - low));

        end




        NumHighLowPixelsValue = str2double(get(NumHighLowPixels,'string'));

        % find edges of vessel for each row of line scan image
        % loop over each row of line scan image
        
        % preallocates vectors
        % VesselDiameterVector = ones(1,Num_Rows);
        LeftEdgeVector = ones(1,Num_Rows);
        RightEdgeVector = ones(1,Num_Rows);
        clear VesselDiameterVector;
        VesselDiameterVector = ones(1,Num_Rows);
        
   
        
        for row=1:Num_Rows
            % if StimulusVector(row) is 1, indicating that stim light is on
            % set the diameter of that row to the mean of the last 10 rows
            if((StimulusVector(row) == 1) && (RejectArtifactsModeFlag == 1) && (row>10))
                VesselDiameterVector(row) = mean(VesselDiameterVector((row-11):(row-1)));
                
                % puts red dots on right edge of image if row n is rejected
                LeftEdgeVector(row) = Num_Columns;
                RightEdgeVector(row) = Num_Columns;

            else
                Sorted = sort(ProcessedLineScan(row,:),'descend');
                XLargest = Sorted(1:NumHighLowPixelsValue);
                XSmallest = Sorted(Num_Columns - NumHighLowPixelsValue:Num_Columns);
                
                % threshold can be set between 0.0 and 1.0 
                % from the dimmest to brightest pixel value
                
                % get threshold value
                ThresholdValue = str2double(get(ThresholdInput,'string'));
                
                % Calculate threshold
                Threshold = mean(XSmallest) + ThresholdValue*(mean(XLargest) - mean(XSmallest));
                
                % find left edge of vessel
                for col=1:Num_Columns
                    Pixelvalue = ProcessedLineScan(row,col);
                    LeftEdgePixel = col;
                    if Pixelvalue > Threshold, break, end
                end
                
                % find right edge of vessel
                for col=Num_Columns:-1:1
                    Pixelvalue = ProcessedLineScan(row,col);
                    RightEdgePixel = col;
                    if Pixelvalue > Threshold, break, end
                end
                
                VesselDiameterVector(row) = RightEdgePixel - LeftEdgePixel;
                
                % creates vectors containing positions of edges of vessel
                LeftEdgeVector(row) = LeftEdgePixel;
                RightEdgeVector(row) = RightEdgePixel;
            end
        end

        DisplayDiameterGraph();
        
        % creates a 3D array, an RGB copy of the line scan array
        RGBLineScan = repmat(ProcessedLineScanAndStim,[1 1 3]);
        
        % inserts red dots (255,0,0) at the edges of the vessel for each row of the
        % line scan
        for row=1:Num_Rows
            RGBLineScan(row,LeftEdgeVector(row),1) = 255;
            RGBLineScan(row,LeftEdgeVector(row),2) = 0;
            RGBLineScan(row,LeftEdgeVector(row),3) = 0;
            
            RGBLineScan(row,RightEdgeVector(row),1) = 255;
            RGBLineScan(row,RightEdgeVector(row),2) = 0;
            RGBLineScan(row,RightEdgeVector(row),3) = 0;
        end
        
        
        % displays the same line scan with edges of vessel marked by red
        % dots
        % New line scan image is drawn within existing scroll panel
        api = iptgetapi(ScrollPanelHandle);
        api.replaceImage(RGBLineScan);        
        
    end


end




