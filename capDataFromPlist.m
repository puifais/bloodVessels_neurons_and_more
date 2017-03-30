%% get tortuosity and capillary length from plist
% run this after running plist2matlab
x1 = 0;


for x = 1:length(S.Vessels)
    if strcmp (S.Vessels{1,x}.type,'Not Defined') == 1 || strcmp (S.Vessels{1,x}.type, 'Capillary') ==1
        x1 = x1  + 1;
        caplength (x1) = S.Vessels{1,x}.lengthInMicrons;  %vector of path length in microns
        euDistance (x1) = sqrt((cell2mat(S.Vessels{1,x}.micronStartPoint(1))- cell2mat(S.Vessels{1,x}.micronEndPoint(1))).^2+ (cell2mat(S.Vessels{1,x}.micronStartPoint(2))-cell2mat(S.Vessels{1,x}.micronEndPoint(2))).^2+ (cell2mat(S.Vessels{1,x}.micronStartPoint(3))-cell2mat(S.Vessels{1,x}.micronEndPoint(3))).^2);
                %euclidean distance between start point and end point
        tortuosity (x1) = caplength(x1)./euDistance(x1);
    else
        
    end
end