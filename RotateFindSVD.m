function [seperability, Rotdata] = RotateFindSVD(XRAMP, YRAMP, X, Y,small,Theta,method)
%RotateFindSVD - rotates the center square matrix of small, returns seperability
% 090406 changed isnan
warpx = X*cos(Theta) +Y*sin(Theta) ;
                warpy = (-X*sin(Theta)+ Y*cos(Theta)) ;
                Rotdata = interp2(XRAMP, YRAMP, small, warpx, warpy, method);
%                 Rotdata(isnan(Rotdata)) = mean(mean(Rotdata));   % replace NaN with mean
                Rotdata(isnan(Rotdata))= mean(Rotdata(~isnan(Rotdata)));
                S = svd(Rotdata);
                seperability = S(1)^2/sum(S.^2);

% Savename2 = 'C:\Nozomi\Rotdata.raw';    
% fid = fopen(Savename2, 'w');
% opened = fwrite(fid, Rotdata, 'uint8');
% fclose(fid);


